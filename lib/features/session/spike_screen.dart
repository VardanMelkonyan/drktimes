import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/clock.dart';
import '../../domain/process.dart';
import '../../domain/sessions.dart';
import '../../domain/timeline/cue_event.dart';
import '../../platform/cues/app_cue_scheduler.dart';
import '../../platform/cues/cue_player.dart';
import '../../platform/cues/notification_cues.dart';
import '../../platform/cues/soloud_player.dart';
import '../../platform/foreground_service.dart';
import '../../platform/notification_permission.dart';
import '../../platform/wake.dart';

/// Throwaway R3 spike (debug builds only): one 15:00 developer step with
/// {60,60,10} agitation, run through the real cue scheduler, wake lock and
/// foreground service, with the raw state on screen and a tick-jitter log.
class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _clock = const SystemClock();
  final _coordinator = SessionCoordinator();
  final _wake = WakelockPlusScreenWake();
  final _service = createForegroundService();
  final _plugin = FlutterLocalNotificationsPlugin();
  final _samples = SoloudSamplePlayer();
  final _planned = <DateTime>[];
  final _jitterMs = <int>[];
  late final NotificationPermission _permission = PluginNotificationPermission(
    _plugin,
  );
  late final CuePlayer _player;
  late final AppCueScheduler _scheduler;
  Timer? _ui;
  Timer? _feed;
  bool _ready = false;
  bool _running = false;
  PermissionState _perm = PermissionState.notDetermined;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _samples.init();
    _samples.onPlayed = (kind, slot) {
      if (kind != CueKind.tick || _planned.isEmpty) return;
      final now = _clock.now();
      final due = _planned.lastWhere(
        (t) => !t.isAfter(now),
        orElse: () => _planned.first,
      );
      _jitterMs.add(now.difference(due).inMilliseconds);
    };
    _player = CuePlayer(
      clock: _clock,
      samples: _samples,
      focus: AudioSessionFocus(),
      soundOn: () => true,
      volume: () => 0.8,
    );
    final cues = NotificationCues(_plugin);
    await cues.init();
    _scheduler = AppCueScheduler(
      player: _player,
      background: cues,
      upcoming: () => _coordinator.upcomingCues(
        _clock.now(),
        const Duration(minutes: 20),
        limit: 600,
      ),
      backgroundAllowed: () => _perm == PermissionState.granted,
    );
    _perm = await _permission.status();
    _ui = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => setState(() {}),
    );
    setState(() => _ready = true);
  }

  Future<void> _start() async {
    if (_perm != PermissionState.granted) {
      _perm = await _permission.request();
    }
    final p = Process.defaults();
    final run = _coordinator.create(
      process: p.copyWith(
        steps: [
          for (final s in p.steps)
            s.copyWith(enabled: s.kind == StepKind.developer),
        ],
      ),
      devTimeS: 15 * 60,
      inversionPaceS: 2,
    )..start(_clock.now());
    _planned
      ..clear()
      ..addAll([
        for (final c in run.upcomingCues(
          _clock.now(),
          const Duration(minutes: 16),
        ))
          if (c.kind == CueKind.tick) c.at,
      ]);
    _jitterMs.clear();
    await _wake.hold();
    await _service.start();
    _feed?.cancel();
    _feed = Timer.periodic(const Duration(seconds: 5), (_) => _topUp());
    _topUp();
    setState(() => _running = true);
  }

  void _topUp() {
    _scheduler.playForeground(
      _coordinator.upcomingCues(_clock.now(), const Duration(seconds: 30)),
    );
    final st = _coordinator.active.firstOrNull?.stateAt(_clock.now());
    _service.update([
      TankLine(
        1,
        'T1 Developer · ${st?.phase.name} · ${st?.remaining?.inSeconds ?? 0} s',
      ),
    ]);
  }

  Future<void> _stop() async {
    _feed?.cancel();
    _scheduler.stopForeground();
    await _scheduler.cancelBackground();
    for (final s in _coordinator.active) {
      s.abort(_clock.now());
    }
    await _wake.release();
    await _service.stop();
    setState(() => _running = false);
  }

  @override
  void dispose() {
    _ui?.cancel();
    _feed?.cancel();
    if (_ready) {
      _scheduler.dispose();
      _player.dispose();
    }
    super.dispose();
  }

  double _p95() {
    if (_jitterMs.isEmpty) return 0;
    final s = [..._jitterMs.map((e) => e.abs())]..sort();
    return s[((s.length - 1) * 0.95).round()].toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final run = _coordinator.active.firstOrNull;
    final st = run?.stateAt(_clock.now());
    return Scaffold(
      appBar: AppBar(title: const Text('R3 spike')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('notifications: ${_perm.name}'),
                  const SizedBox(height: 8),
                  Text('state: ${st ?? 'idle'}'),
                  Text('ticks played: ${_jitterMs.length}'),
                  Text('tick jitter p95: ${_p95().toStringAsFixed(0)} ms'),
                  const Spacer(),
                  FilledButton(
                    onPressed: _running ? _stop : _start,
                    child: Text(_running ? 'STOP' : 'START 15:00'),
                  ),
                ],
              ),
      ),
    );
  }
}
