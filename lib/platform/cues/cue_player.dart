import 'dart:async';

import '../../domain/clock.dart';
import '../../domain/timeline/cue_event.dart';

/// Plays one preloaded sample.
abstract interface class SamplePlayer {
  Future<void> init();
  void play(CueKind kind, int tankSlot, double volume);
  Future<void> dispose();
}

/// Audio-session focus, as reported by the OS.
abstract interface class AudioFocus {
  /// `true` when an interruption begins (call, alarm, Siri…), `false` when
  /// it ends.
  Stream<bool> get interruptions;

  /// Makes our audio session active again after an interruption.
  Future<void> reactivate();
}

/// The foreground half of the cue scheduler: a look-ahead queue that plays
/// each [CueEvent] when its wall-clock time arrives.
///
/// Timing is never accumulated: every pump compares the queue against the
/// clock (research R1). Cues that fall inside an audio interruption are
/// dropped, not replayed late.
class CuePlayer {
  CuePlayer({
    required this.clock,
    required this.samples,
    required this.focus,
    required this.soundOn,
    required this.volume,
    this.pumpInterval = const Duration(milliseconds: 20),
    this.lookAhead = const Duration(milliseconds: 5),
  }) {
    _sub = focus.interruptions.listen(_onInterruption);
  }

  final Clock clock;
  final SamplePlayer samples;
  final AudioFocus focus;
  final bool Function() soundOn;
  final double Function() volume;
  final Duration pumpInterval;

  /// How early a cue may fire; it is played when `at <= now + lookAhead`.
  final Duration lookAhead;

  late final StreamSubscription<bool> _sub;
  Timer? _timer;
  List<CueEvent> _queue = [];
  bool _interrupted = false;

  /// Replaces the queue and starts the pump loop.
  void play(List<CueEvent> events) {
    _queue = [...events]..sort((a, b) => a.at.compareTo(b.at));
    _timer ??= Timer.periodic(pumpInterval, (_) => pump());
  }

  void stop() {
    _queue = [];
    _timer?.cancel();
    _timer = null;
  }

  /// Plays whatever has become due. Public so tests can drive it.
  void pump() {
    final now = clock.now().add(lookAhead);
    while (_queue.isNotEmpty && !_queue.first.at.isAfter(now)) {
      final cue = _queue.removeAt(0);
      if (_interrupted || !soundOn()) continue;
      samples.play(cue.kind, cue.tankSlot, volume());
    }
  }

  Future<void> _onInterruption(bool begin) async {
    if (begin) {
      _interrupted = true;
      return;
    }
    await focus.reactivate();
    // Skip what fell inside the interruption; timing carries on from now.
    final now = clock.now();
    _queue.removeWhere((c) => !c.at.isAfter(now));
    _interrupted = false;
  }

  Future<void> dispose() async {
    stop();
    await _sub.cancel();
    await samples.dispose();
  }
}
