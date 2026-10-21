import '../../domain/timeline/cue_event.dart';

/// Plays cues in the foreground and schedules them for when the app is not
/// (contracts/platform-channels.md §1).
abstract interface class CueScheduler {
  /// Foreground: play [events] at their wall-clock times. Replaces whatever
  /// was queued before.
  void playForeground(List<CueEvent> events);

  /// Stops foreground playback and clears the queue.
  void stopForeground();

  /// Called on app pause: schedule attention cues (no ticks) as local
  /// notifications, a rolling window of at most 60 across all tanks.
  Future<void> scheduleBackground(List<CueEvent> events);

  /// Called on app resume and on session end: cancel all pending.
  Future<void> cancelBackground();
}
