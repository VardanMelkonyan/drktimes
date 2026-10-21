import 'package:flutter/widgets.dart';

import '../../domain/timeline/cue_event.dart';
import 'cue_player.dart';
import 'cue_scheduler.dart';
import 'notification_cues.dart';

/// Combines the foreground [CuePlayer] and the notification-based
/// [BackgroundCues]. On `paused` it hands the attention cues to the OS; on
/// `resumed` it cancels them and plays in the foreground again.
class AppCueScheduler with WidgetsBindingObserver implements CueScheduler {
  AppCueScheduler({
    required this.player,
    required this.background,
    required this.upcoming,
    required this.backgroundAllowed,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final CuePlayer player;
  final BackgroundCues background;

  /// The cues still ahead, from the session coordinator.
  final List<CueEvent> Function() upcoming;

  /// False while notification permission is denied.
  final bool Function() backgroundAllowed;

  List<CueEvent> _foreground = [];

  @override
  void playForeground(List<CueEvent> events) {
    _foreground = events;
    player.play(events);
  }

  @override
  void stopForeground() {
    _foreground = [];
    player.stop();
  }

  @override
  Future<void> scheduleBackground(List<CueEvent> events) async {
    if (!backgroundAllowed()) return;
    await background.schedule(events);
  }

  @override
  Future<void> cancelBackground() => background.cancel();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        player.stop();
        scheduleBackground(upcoming());
      case AppLifecycleState.resumed:
        cancelBackground();
        if (_foreground.isNotEmpty) player.play(upcoming());
      default:
        break;
    }
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
