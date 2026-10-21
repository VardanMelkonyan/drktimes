import 'process.dart';
import 'session_meta.dart';
import 'timeline/cue_event.dart';
import 'timeline/session_run.dart';

class TankLimitReached implements Exception {
  const TankLimitReached();

  @override
  String toString() => 'At most 3 tanks can run at once.';
}

const maxTanks = 3;
const maxBackgroundCues = 60;

/// Up to three concurrent [SessionRun]s (FR-068), the Next routing between
/// them (FR-070) and their merged cue stream.
class SessionCoordinator {
  SessionCoordinator([Iterable<SessionRun> restored = const []]) {
    _sessions.addAll(restored);
  }

  final List<SessionRun> _sessions = [];
  SessionRun? _lastNext;
  int _counter = 0;

  List<SessionRun> get all => List.unmodifiable(_sessions);

  List<SessionRun> get active => [
    for (final s in _sessions)
      if (s.status == SessionStatus.active) s,
  ]..sort((a, b) => a.tankSlot.compareTo(b.tankSlot));

  /// Creates a session in the lowest free tank slot.
  SessionRun create({
    required Process process,
    required int devTimeS,
    required double inversionPaceS,
    String? label,
    String? id,
    SessionMeta meta = const SessionMeta(),
  }) {
    final used = {for (final s in active) s.tankSlot};
    final slot = [for (var i = 1; i <= maxTanks; i++) i]
        .firstWhere((i) => !used.contains(i), orElse: () => 0);
    if (slot == 0) throw const TankLimitReached();
    final run = SessionRun(
      id:
          id ??
          'session-${++_counter}-${DateTime.now().microsecondsSinceEpoch}',
      tankSlot: slot,
      tankLabel: label,
      process: process,
      devTimeS: devTimeS,
      inversionPaceS: inversionPaceS,
      meta: meta,
    );
    _sessions.add(run);
    return run;
  }

  /// Takes over a session rebuilt from storage.
  void adopt(SessionRun s) {
    if (!_sessions.contains(s)) _sessions.add(s);
  }

  void abort(SessionRun s, DateTime now) {
    s.abort(now);
  }

  void remove(SessionRun s) {
    _sessions.remove(s);
    if (identical(_lastNext, s)) _lastNext = null;
  }

  /// The session Next would act on: of those waiting for Next, the one
  /// that has waited longest.
  SessionRun? nextTarget(DateTime now) {
    SessionRun? best;
    DateTime? bestSince;
    for (final s in active) {
      final st = s.stateAt(now);
      if (st.phase != SessionPhase.dumpPour) continue;
      final since = st.awaitingSince!;
      if (bestSince == null || since.isBefore(bestSince)) {
        best = s;
        bestSince = since;
      }
    }
    return best;
  }

  /// Presses Next on [nextTarget]; returns the session it hit.
  SessionRun? next(DateTime now) {
    final target = nextTarget(now);
    if (target == null || !target.next(now)) return null;
    _lastNext = target;
    return target;
  }

  /// Undoes the last Next, on the session it hit.
  SessionRun? undo(DateTime now) {
    final s = _lastNext;
    if (s == null) return null;
    if (!s.undo(now)) return null;
    _lastNext = null;
    return s;
  }

  /// Cues of all active tanks in `(now, now + horizon]`, time ordered, at
  /// most [limit]. With [backgroundOnly], ticks and routine pips are left out.
  List<CueEvent> upcomingCues(
    DateTime now,
    Duration horizon, {
    int limit = maxBackgroundCues,
    bool backgroundOnly = false,
  }) {
    final out = <CueEvent>[
      for (final s in active)
        for (final c in s.upcomingCues(now, horizon))
          if (!backgroundOnly || c.background) c,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return out.length > limit ? out.sublist(0, limit) : out;
  }
}
