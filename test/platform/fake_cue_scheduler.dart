import 'package:drktimes/domain/timeline/cue_event.dart';
import 'package:drktimes/platform/cues/cue_scheduler.dart';

/// Records what the app asked of the cue scheduler.
class FakeCueScheduler implements CueScheduler {
  List<CueEvent> foreground = [];
  List<CueEvent> background = [];
  int stopForegroundCalls = 0;
  int cancelBackgroundCalls = 0;

  @override
  void playForeground(List<CueEvent> events) => foreground = events;

  @override
  void stopForeground() {
    stopForegroundCalls++;
    foreground = [];
  }

  @override
  Future<void> scheduleBackground(List<CueEvent> events) async =>
      background = events;

  @override
  Future<void> cancelBackground() async {
    cancelBackgroundCalls++;
    background = [];
  }
}
