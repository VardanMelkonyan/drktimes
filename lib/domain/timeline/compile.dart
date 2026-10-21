import '../process.dart';

/// A half-open interval `[startMs, endMs)` of active step time.
class Window {
  const Window(this.startMs, this.endMs);

  final int startMs, endMs;

  int get lengthMs => endMs - startMs;

  bool contains(int ms) => ms >= startMs && ms < endMs;

  @override
  bool operator ==(Object other) =>
      other is Window && other.startMs == startMs && other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => '[${startMs / 1000}–${endMs / 1000})';
}

const finalWindowMs = 10000;

/// A step compiled into times relative to its start, in active milliseconds
/// (paused time does not count).
class StepPlan {
  const StepPlan({
    required this.step,
    required this.paceMs,
    required this.durationMs,
    required this.windows,
    required this.ticksMs,
    required this.final10,
    required this.fills,
  });

  final Step step;
  final int paceMs;

  /// Null for an Ilford wash, which has no clock end.
  final int? durationMs;

  /// Agitation windows.
  final List<Window> windows;

  /// Inversion ticks, at [paceMs] inside each window.
  final List<int> ticksMs;
  final Window? final10;

  /// Counted inversions for each fill of an Ilford wash; empty otherwise.
  final List<int> fills;

  bool get isTimed => durationMs != null;
  bool get isIlford => fills.isNotEmpty;

  /// The agitation window containing [ms], if any.
  Window? windowAt(int ms) {
    for (final w in windows) {
      if (w.contains(ms)) return w;
    }
    return null;
  }

  /// Start of the first window beginning after [ms], if any.
  int? nextWindowStartAfter(int ms) {
    for (final w in windows) {
      if (w.startMs > ms) return w.startMs;
    }
    return null;
  }
}

/// Compiles [step] into a [StepPlan].
///
/// [devTimeS] is the developer time (the developer step has no duration of
/// its own); [adjustMs] is the net ±30 s adjustment made while running.
StepPlan compileStep(
  Step step, {
  required int devTimeS,
  required int paceMs,
  int adjustMs = 0,
}) {
  final wash = step.wash;
  if (step.kind == StepKind.wash && wash is IlfordWash) {
    return StepPlan(
      step: step,
      paceMs: paceMs,
      durationMs: null,
      windows: const [],
      ticksMs: const [],
      final10: null,
      fills: wash.fills,
    );
  }

  final baseS = switch (step.kind) {
    StepKind.developer => devTimeS,
    StepKind.wash when wash is RunningWash => wash.durationS,
    _ => step.durationS,
  };
  final durationMs = baseS * 1000 + adjustMs;
  final windows = _windows(step.agitation, durationMs);
  final ticks = <int>[
    for (final w in windows)
      for (var i = 0; i < w.lengthMs ~/ paceMs; i++) w.startMs + i * paceMs,
  ];
  return StepPlan(
    step: step,
    paceMs: paceMs,
    durationMs: durationMs,
    windows: windows,
    ticksMs: ticks,
    final10: Window(
      durationMs > finalWindowMs ? durationMs - finalWindowMs : 0,
      durationMs,
    ),
    fills: const [],
  );
}

List<Window> _windows(AgitationPattern a, int durationMs) {
  // Bursts must start before the last-10 s window, which takes priority.
  final burstLimit = durationMs - finalWindowMs;
  switch (a) {
    case Continuous():
      return [Window(0, durationMs)];
    case NoAgitation():
      return const [];
    case Stand(:final initialS, :final midAgitationAtS, :final midBurstS):
      return [
        if (initialS > 0) Window(0, _min(initialS * 1000, durationMs)),
        if (midAgitationAtS != null &&
            midBurstS != null &&
            midAgitationAtS * 1000 < burstLimit)
          Window(
            midAgitationAtS * 1000,
            _min(midAgitationAtS * 1000 + midBurstS * 1000, burstLimit),
          ),
      ];
    case Intermittent(:final initialS, :final everyS, :final burstS):
      final out = <Window>[
        if (initialS > 0) Window(0, _min(initialS * 1000, durationMs)),
      ];
      for (var k = 1; ; k++) {
        final start = (initialS + k * everyS) * 1000;
        if (start >= burstLimit) break;
        out.add(Window(start, _min(start + burstS * 1000, burstLimit)));
      }
      return out;
  }
}

int _min(int a, int b) => a < b ? a : b;
