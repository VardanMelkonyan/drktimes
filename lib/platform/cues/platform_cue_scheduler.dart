import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/clock.dart';
import '../../domain/timeline/cue_event.dart';
import 'app_cue_scheduler.dart';
import 'cue_player.dart';
import 'cue_scheduler.dart';
import 'notification_cues.dart';
import 'soloud_player.dart';

/// The real [CueScheduler]: SoLoud samples in the foreground and local
/// notifications behind it. The audio engine starts on first use, so opening
/// the app costs nothing until a session begins.
class PlatformCueScheduler implements CueScheduler {
  PlatformCueScheduler({
    required this.clock,
    required this.soundOn,
    required this.volume,
    required this.upcoming,
    required this.backgroundAllowed,
    FlutterLocalNotificationsPlugin? plugin,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final Clock clock;
  final bool Function() soundOn;
  final double Function() volume;
  final List<CueEvent> Function() upcoming;
  final bool Function() backgroundAllowed;
  final FlutterLocalNotificationsPlugin plugin;

  Future<AppCueScheduler>? _ready;

  Future<AppCueScheduler> get _scheduler => _ready ??= _build();

  Future<AppCueScheduler> _build() async {
    final samples = SoloudSamplePlayer();
    await samples.init();
    final notifications = NotificationCues(plugin);
    await notifications.init();
    return AppCueScheduler(
      player: CuePlayer(
        clock: clock,
        samples: samples,
        focus: AudioSessionFocus(),
        soundOn: soundOn,
        volume: volume,
      ),
      background: notifications,
      upcoming: upcoming,
      backgroundAllowed: backgroundAllowed,
    );
  }

  @override
  void playForeground(List<CueEvent> events) {
    unawaited(_scheduler.then((s) => s.playForeground(events)));
  }

  @override
  void stopForeground() {
    if (_ready != null) unawaited(_ready!.then((s) => s.stopForeground()));
  }

  @override
  Future<void> scheduleBackground(List<CueEvent> events) async =>
      (await _scheduler).scheduleBackground(events);

  @override
  Future<void> cancelBackground() async {
    if (_ready != null) await (await _ready!).cancelBackground();
  }
}
