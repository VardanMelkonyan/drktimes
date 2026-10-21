import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/clock.dart';
import '../../domain/process.dart';
import '../../domain/session_meta.dart';
import '../../domain/sessions.dart';
import '../../domain/timeline/session_run.dart';
import '../../platform/cues/cue_scheduler.dart';
import '../../platform/foreground_service.dart';
import '../../platform/notification_permission.dart';
import '../../platform/volume_keys.dart';
import '../../platform/wake.dart';

/// Connects the [SessionCoordinator] to persistence, the cue scheduler, the
/// wake lock, the foreground service and the volume keys (T050).
///
/// Everything it does is a reaction to a transition or to the clock; it never
/// holds timing state of its own (research R1).
class SessionController extends ChangeNotifier with WidgetsBindingObserver {
  SessionController({
    required this.clock,
    required this.repository,
    required this.settings,
    required this.scheduler,
    required this.wake,
    required this.foregroundService,
    required this.volumeKeys,
    required this.permission,
    SessionCoordinator? coordinator,
    this.housekeeping = const Duration(milliseconds: 500),
    this.refeedEvery = const Duration(seconds: 20),
    this.isIos = false,
  }) : coordinator = coordinator ?? SessionCoordinator();

  factory SessionController.platform({
    required Clock clock,
    required SessionRepository repository,
    required SettingsRepository settings,
    required CueScheduler scheduler,
    required ScreenWake wake,
    required SessionForegroundService foregroundService,
    required VolumeKeys volumeKeys,
    required NotificationPermission permission,
  }) => SessionController(
    clock: clock,
    repository: repository,
    settings: settings,
    scheduler: scheduler,
    wake: wake,
    foregroundService: foregroundService,
    volumeKeys: volumeKeys,
    permission: permission,
    isIos: Platform.isIOS,
  );

  final Clock clock;
  final SessionRepository repository;
  final SettingsRepository settings;
  final CueScheduler scheduler;
  final ScreenWake wake;
  final SessionForegroundService foregroundService;
  final VolumeKeys volumeKeys;
  final NotificationPermission permission;
  final SessionCoordinator coordinator;
  final Duration housekeeping;
  final Duration refeedEvery;
  final bool isIos;

  Timer? _timer;
  StreamSubscription<VolumeKey>? _keys;
  DateTime? _lastFeed;
  bool _serviceRunning = false;
  bool _armed = false;
  bool _notificationsDenied = false;
  bool _showBackgroundNotice = false;
  bool _wentToBackground = false;

  /// The "Background cues are off" banner (FR-048).
  bool get backgroundCuesOff => _notificationsDenied;

  /// iOS: show the one-time "Ticks need the screen on" sheet.
  bool get showBackgroundNotice => _showBackgroundNotice;

  List<SessionRun> get active => coordinator.active;

  /// Sessions finished since launch, newest first (for the Done screen).
  final List<SessionRun> finished = [];

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    _keys ??= volumeKeys.presses.listen((_) => next());
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _keys?.cancel();
    super.dispose();
  }

  /// Rebuilds sessions that were running when the app was killed (FR-003).
  Future<void> restore() async {
    final restored = await repository.loadActive();
    for (final s in restored.all) {
      coordinator.adopt(s);
    }
    if (active.isNotEmpty) await _engage();
    notifyListeners();
  }

  /// Starts a session. On the very first start the notification permission is
  /// asked for before the timer begins.
  Future<SessionRun> start({
    required Process process,
    required int devTimeS,
    SessionMeta meta = const SessionMeta(),
    String? label,
  }) async {
    final s = await settings.get();
    if (!s.notificationsAsked) {
      await permission.request();
      await settings.update(notificationsAsked: true);
    }
    _notificationsDenied =
        (await permission.status()) == PermissionState.denied;

    final run = coordinator.create(
      process: process,
      devTimeS: devTimeS,
      inversionPaceS: s.inversionPaceS,
      label: label,
      meta: meta,
    )..start(clock.now());
    await repository.save(run);
    await _engage();
    notifyListeners();
    return run;
  }

  Future<void> _engage() async {
    await wake.hold();
    if (!_serviceRunning) {
      await foregroundService.start();
      _serviceRunning = true;
    }
    _timer ??= Timer.periodic(housekeeping, (_) => tick());
    await _refeed();
    await _syncKeys();
  }

  // ------------------------------------------------------------ transitions

  /// Presses Next on the tank that has waited longest (FR-070).
  Future<SessionRun?> next() async {
    final hit = coordinator.next(clock.now());
    if (hit != null) await _after(hit);
    return hit;
  }

  Future<SessionRun?> undo() async {
    final hit = coordinator.undo(clock.now());
    if (hit != null) await _after(hit);
    return hit;
  }

  Future<void> pause(SessionRun s) => _apply(s, () => s.pause(clock.now()));
  Future<void> resume(SessionRun s) => _apply(s, () => s.resume(clock.now()));
  Future<void> adjust(SessionRun s, int deltaS) =>
      _apply(s, () => s.adjust(clock.now(), deltaS));

  Future<void> abort(SessionRun s) async {
    s.abort(clock.now());
    await _after(s);
  }

  Future<void> rename(SessionRun s, String label) async {
    s.tankLabel = label;
    await repository.save(s);
    notifyListeners();
  }

  Future<void> _apply(SessionRun s, bool Function() change) async {
    if (change()) await _after(s);
  }

  Future<void> _after(SessionRun s) async {
    s.finishIfDone(clock.now());
    await repository.save(s);
    await _retireFinished();
    await _refeed();
    await _syncKeys();
    notifyListeners();
  }

  Future<void> _retireFinished() async {
    for (final s in [...coordinator.all]) {
      if (s.status != SessionStatus.active && !finished.contains(s)) {
        finished.insert(0, s);
      }
    }
    if (active.isEmpty && _serviceRunning) {
      scheduler.stopForeground();
      await scheduler.cancelBackground();
      await wake.release();
      await foregroundService.stop();
      _serviceRunning = false;
      _timer?.cancel();
      _timer = null;
      await volumeKeys.setArmed(false);
      _armed = false;
    }
  }

  // --------------------------------------------------------------- the clock

  /// Called by the housekeeping timer; public so tests can drive it.
  Future<void> tick() async {
    final now = clock.now();
    var changed = false;
    for (final s in active) {
      final before = s.runs.length;
      s.syncAnchors(now);
      final wasActive = s.status == SessionStatus.active;
      s.finishIfDone(now);
      if (s.runs.length != before ||
          (wasActive && s.status != SessionStatus.active)) {
        await repository.save(s);
        changed = true;
      }
    }
    if (changed) {
      await _retireFinished();
      await _refeed();
      notifyListeners();
    } else if (_lastFeed == null || now.difference(_lastFeed!) >= refeedEvery) {
      await _refeed();
    }
    await _syncKeys();
    await _updateServiceLines();
  }

  Future<void> _refeed() async {
    final now = clock.now();
    _lastFeed = now;
    scheduler.playForeground(
      coordinator.upcomingCues(now, const Duration(seconds: 60), limit: 600),
    );
  }

  Future<void> _syncKeys() async {
    final s = await settings.get();
    final waiting = active.any(
      (r) => r.stateAt(clock.now()).phase == SessionPhase.dumpPour,
    );
    final want = waiting && s.volumeKeyNext;
    if (want != _armed) {
      _armed = want;
      await volumeKeys.setArmed(want);
    }
  }

  Future<void> _updateServiceLines() async {
    if (!_serviceRunning) return;
    final now = clock.now();
    await foregroundService.update([
      for (final s in active) TankLine(s.tankSlot, _line(s, s.stateAt(now))),
    ]);
  }

  static String _line(SessionRun s, SessionState st) {
    final name = st.step?.name ?? 'Ready';
    final time = st.remaining ?? st.waited;
    final t = time == null
        ? ''
        : ' · ${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
    return 'T${s.tankSlot} $name · ${st.phase.name}$t';
  }

  // --------------------------------------------------------------- lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (active.isEmpty) return;
        _wentToBackground = true;
        if (isIos) _maybeNotice();
      case AppLifecycleState.resumed:
        if (_wentToBackground) {
          _wentToBackground = false;
          permission.status().then((p) {
            _notificationsDenied = p == PermissionState.denied;
            notifyListeners();
          });
          tick();
        }
      default:
        break;
    }
  }

  Future<void> _maybeNotice() async {
    final s = await settings.get();
    if (!s.backgroundLimitSeen) {
      _showBackgroundNotice = true;
      notifyListeners();
    }
  }

  /// The user has read the one-time sheet.
  Future<void> acknowledgeBackgroundNotice() async {
    _showBackgroundNotice = false;
    await settings.update(backgroundLimitSeen: true);
    notifyListeners();
  }

  Future<void> openNotificationSettings() => permission.openSystemSettings();
}
