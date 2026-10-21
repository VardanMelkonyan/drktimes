import '../process.dart';
import '../session_meta.dart';
import 'compile.dart';
import 'cue_event.dart';

enum SessionPhase {
  ready,
  agitate,
  rest,
  final10,
  dumpPour,
  washFill,
  paused,
  done,
  aborted,
}

enum SessionStatus { active, completed, aborted }

const undoWindow = Duration(seconds: 5);

class Pause {
  Pause(this.from, [this.to]);

  factory Pause.fromJson(Map<String, dynamic> j) => Pause(
    DateTime.parse(j['from'] as String),
    j['to'] == null ? null : DateTime.parse(j['to'] as String),
  );

  final DateTime from;
  DateTime? to;

  Map<String, dynamic> toJson() => {
    'from': from.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
  };
}

/// The persisted anchors of one step (research R1).
class StepRun {
  StepRun(this.stepIndex, {this.startedAt});

  factory StepRun.fromJson(Map<String, dynamic> j) =>
      StepRun(j['step_index'] as int, startedAt: _time(j['started_at']))
        ..adjustMs = (j['adjust_s'] as int? ?? 0) * 1000
        ..pauses.addAll([
          for (final p in (j['pauses'] as List? ?? const []))
            Pause.fromJson(p as Map<String, dynamic>),
        ])
        ..fillStarts.addAll([
          for (final f in (j['fill_starts'] as List? ?? const []))
            DateTime.parse(f as String),
        ])
        ..nextPressedAt = _time(j['next_pressed_at'])
        ..undoUntil = _time(j['undo_until'])
        ..undoKind = j['undo_kind'] as String?;

  /// Index into the session's enabled steps.
  final int stepIndex;
  DateTime? startedAt;

  /// Net ±30 s adjustments, in milliseconds.
  int adjustMs = 0;
  final List<Pause> pauses = [];

  /// Start of each Ilford fill; the first equals [startedAt].
  final List<DateTime> fillStarts = [];
  DateTime? nextPressedAt;

  /// While set and in the future, the action in [undoKind] can be undone:
  /// `step` (Next started the following step), `fill` (Next began the next
  /// fill) or `finish` (Next completed the process).
  DateTime? undoUntil;
  String? undoKind;

  StepRun copy() => StepRun(stepIndex, startedAt: startedAt)
    ..adjustMs = adjustMs
    ..pauses.addAll([for (final p in pauses) Pause(p.from, p.to)])
    ..fillStarts.addAll(fillStarts)
    ..nextPressedAt = nextPressedAt
    ..undoUntil = undoUntil
    ..undoKind = undoKind;

  Map<String, dynamic> toJson() => {
    'step_index': stepIndex,
    if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
    'adjust_s': adjustMs ~/ 1000,
    'pauses': [for (final p in pauses) p.toJson()],
    if (fillStarts.isNotEmpty)
      'fill_starts': [for (final f in fillStarts) f.toIso8601String()],
    if (nextPressedAt != null)
      'next_pressed_at': nextPressedAt!.toIso8601String(),
    if (undoUntil != null) 'undo_until': undoUntil!.toIso8601String(),
    if (undoKind != null) 'undo_kind': undoKind,
  };

  static DateTime? _time(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

/// What the screen shows at a moment in time. Derived, never stored.
class SessionState {
  const SessionState({
    required this.phase,
    this.stepIndex,
    this.step,
    this.remaining,
    this.untilNextAgitation,
    this.untilAgitationEnds,
    this.waited,
    this.windowElapsed,
    this.fillIndex,
    this.fillCount,
    this.inversionsDone,
    this.inversionsTarget,
    this.awaitingSince,
    this.undoAvailable = false,
    this.pausedFrom,
  });

  final SessionPhase phase;
  final int? stepIndex;
  final Step? step;

  /// Time left in a timed step (frozen while paused).
  final Duration? remaining;
  final Duration? untilNextAgitation, untilAgitationEnds;

  /// Count-up since the tank was ready to be dumped.
  final Duration? waited;

  /// Time into the current agitation window (for the inversion counter).
  final Duration? windowElapsed;

  final int? fillIndex, fillCount, inversionsDone, inversionsTarget;

  /// When the step finished and Next became available.
  final DateTime? awaitingSince;
  final bool undoAvailable;
  final DateTime? pausedFrom;

  bool get isFinished =>
      phase == SessionPhase.done || phase == SessionPhase.aborted;

  @override
  String toString() => 'State(${phase.name} step=$stepIndex rem=$remaining)';
}

class _Seg {
  _Seg(this.run, this.plan, this.start, this.end);

  final StepRun run;
  final StepPlan plan;
  final DateTime start;

  /// When a timed step ends; null for untimed or while an open pause is
  /// holding the end back.
  final DateTime? end;
}

/// One tank's session. All timing is derived from the anchors in [runs]
/// (research R1): nothing here counts ticks.
class SessionRun {
  SessionRun({
    required this.id,
    required this.tankSlot,
    required this.process,
    required this.devTimeS,
    required this.inversionPaceS,
    String? tankLabel,
    this.startedAt,
    this.meta = const SessionMeta(),
  }) : tankLabel = tankLabel ?? 'Tank $tankSlot',
       steps = process.enabledSteps.toList(growable: false);

  factory SessionRun.fromJson(Map<String, dynamic> j) =>
      SessionRun(
          id: j['id'] as String,
          tankSlot: j['tank_slot'] as int,
          tankLabel: j['tank_label'] as String,
          process: Process.fromJson(
            j['process_snapshot'] as Map<String, dynamic>,
          ),
          devTimeS: j['dev_time_s'] as int,
          inversionPaceS: (j['inversion_pace_s'] as num).toDouble(),
          startedAt: j['started_at'] == null
              ? null
              : DateTime.parse(j['started_at'] as String),
        )
        ..status = SessionStatus.values.byName(j['status'] as String)
        ..abortedAtStep = j['aborted_at_step'] as int?
        ..finishedAt = j['finished_at'] == null
            ? null
            : DateTime.parse(j['finished_at'] as String)
        ..runs.addAll([
          for (final r in (j['step_runs'] as List))
            StepRun.fromJson(r as Map<String, dynamic>),
        ]);

  final String id;
  final int tankSlot;
  String tankLabel;

  /// The frozen process this session runs.
  final Process process;

  /// Enabled steps of [process], in order.
  final List<Step> steps;
  final int devTimeS;
  final double inversionPaceS;
  final SessionMeta meta;
  DateTime? startedAt;
  DateTime? finishedAt;
  int? abortedAtStep;
  SessionStatus status = SessionStatus.active;
  final List<StepRun> runs = [];

  int get paceMs => (inversionPaceS * 1000).round();
  bool get keepGoing => process.transitionMode == TransitionMode.keepGoing;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tank_slot': tankSlot,
    'tank_label': tankLabel,
    'process_snapshot': process.toJson(),
    'dev_time_s': devTimeS,
    'inversion_pace_s': inversionPaceS,
    'status': status.name,
    if (abortedAtStep != null) 'aborted_at_step': abortedAtStep,
    if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
    if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
    'step_runs': [for (final r in runs) r.toJson()],
  };

  StepPlan planFor(int stepIndex, [int adjustMs = 0]) => compileStep(
    steps[stepIndex],
    devTimeS: devTimeS,
    paceMs: paceMs,
    adjustMs: adjustMs,
  );

  // ---------------------------------------------------------------- timing

  /// Active milliseconds between [base] and [t], leaving out paused time.
  static int _activeMs(DateTime base, DateTime t, List<Pause> pauses) {
    var ms = t.difference(base).inMilliseconds;
    for (final p in pauses) {
      final from = p.from.isBefore(base) ? base : p.from;
      final to = p.to ?? t;
      final cut = (to.isAfter(t) ? t : to).difference(from).inMilliseconds;
      if (cut > 0) ms -= cut;
    }
    return ms;
  }

  /// Wall time at which [activeMs] of active time has passed since [base];
  /// null if an open pause begins first.
  static DateTime? _wallAt(DateTime base, int activeMs, List<Pause> pauses) {
    var t = base.add(Duration(milliseconds: activeMs));
    final ordered = [...pauses]..sort((a, b) => a.from.compareTo(b.from));
    for (final p in ordered) {
      if (p.to != null && !p.to!.isAfter(base)) continue;
      if (!p.from.isBefore(t)) break;
      if (p.to == null) return null;
      final from = p.from.isBefore(base) ? base : p.from;
      t = t.add(p.to!.difference(from));
    }
    return t;
  }

  _Seg _seg(StepRun run) {
    final plan = planFor(run.stepIndex, run.adjustMs);
    final start = run.startedAt!;
    final end = plan.durationMs == null
        ? null
        : _wallAt(start, plan.durationMs!, run.pauses);
    return _Seg(run, plan, start, end);
  }

  /// Persisted runs plus, in keep-going mode, the steps that follow
  /// automatically.
  List<_Seg> _segments() {
    final out = [for (final r in runs) _seg(r)];
    if (!keepGoing || out.isEmpty) return out;
    var last = out.last;
    while (last.plan.isTimed &&
        last.end != null &&
        last.run.stepIndex + 1 < steps.length) {
      final run = StepRun(last.run.stepIndex + 1, startedAt: last.end);
      last = _seg(run);
      out.add(last);
    }
    return out;
  }

  /// Turns automatically started steps (keep-going) that have begun by [now]
  /// into persisted runs, so a transition builds on them.
  void _materialize(DateTime now) {
    if (runs.isEmpty) return;
    final segs = _segments();
    for (var i = runs.length; i < segs.length; i++) {
      if (segs[i].start.isAfter(now)) break;
      runs.add(segs[i].run);
    }
  }

  /// Persists automatically started steps (keep-going) that have begun by
  /// [now]. The controller calls this regularly so the stored anchors keep up.
  void syncAnchors(DateTime now) {
    if (status == SessionStatus.active) _materialize(now);
  }

  _Seg? _current(DateTime now) {
    final segs = _segments();
    _Seg? cur;
    for (final s in segs) {
      if (!s.start.isAfter(now)) cur = s;
    }
    return cur;
  }

  // ----------------------------------------------------------------- state

  /// The state at [now]. Pure: it reads anchors and nothing else.
  SessionState stateAt(DateTime now) {
    if (status == SessionStatus.aborted) {
      return const SessionState(phase: SessionPhase.aborted);
    }
    if (status == SessionStatus.completed) {
      return const SessionState(phase: SessionPhase.done);
    }
    if (runs.isEmpty) return const SessionState(phase: SessionPhase.ready);

    final seg = _current(now);
    if (seg == null) return const SessionState(phase: SessionPhase.ready);
    final run = seg.run;
    final plan = seg.plan;
    final idx = run.stepIndex;
    final step = plan.step;
    final undo = _undoAvailable(now);

    Pause? openPause;
    for (final p in run.pauses) {
      if (p.to == null && !p.from.isAfter(now)) openPause = p;
    }

    if (plan.isIlford) {
      final starts = run.fillStarts.isEmpty ? [seg.start] : run.fillStarts;
      final fill = starts.length - 1;
      final target = plan.fills[fill];
      final fillMs = target * plan.paceMs;
      final at = openPause != null && openPause.from.isBefore(now)
          ? openPause.from
          : now;
      final e = _activeMs(starts.last, at, run.pauses);
      if (openPause != null) {
        return SessionState(
          phase: SessionPhase.paused,
          stepIndex: idx,
          step: step,
          fillIndex: fill,
          fillCount: plan.fills.length,
          inversionsDone: (e ~/ plan.paceMs).clamp(0, target),
          inversionsTarget: target,
          pausedFrom: openPause.from,
          undoAvailable: undo,
        );
      }
      if (e >= fillMs) {
        final endAt = _wallAt(starts.last, fillMs, run.pauses)!;
        return SessionState(
          phase: SessionPhase.dumpPour,
          stepIndex: idx,
          step: step,
          fillIndex: fill,
          fillCount: plan.fills.length,
          inversionsDone: target,
          inversionsTarget: target,
          waited: now.difference(endAt),
          awaitingSince: endAt,
          undoAvailable: undo,
        );
      }
      return SessionState(
        phase: SessionPhase.washFill,
        stepIndex: idx,
        step: step,
        fillIndex: fill,
        fillCount: plan.fills.length,
        inversionsDone: e ~/ plan.paceMs,
        inversionsTarget: target,
        undoAvailable: undo,
      );
    }

    final durationMs = plan.durationMs!;
    final at = openPause != null && openPause.from.isBefore(now)
        ? openPause.from
        : now;
    final e = _activeMs(seg.start, at, run.pauses);

    if (openPause != null) {
      return SessionState(
        phase: SessionPhase.paused,
        stepIndex: idx,
        step: step,
        remaining: Duration(
          milliseconds: (durationMs - e).clamp(0, durationMs),
        ),
        pausedFrom: openPause.from,
        undoAvailable: undo,
      );
    }

    if (e >= durationMs) {
      final isLast = idx + 1 >= steps.length;
      if (isLast) {
        return SessionState(
          phase: SessionPhase.done,
          stepIndex: idx,
          step: step,
        );
      }
      final endAt = seg.end!;
      return SessionState(
        phase: SessionPhase.dumpPour,
        stepIndex: idx,
        step: step,
        waited: now.difference(endAt),
        awaitingSince: endAt,
        undoAvailable: undo,
      );
    }

    final remaining = Duration(milliseconds: durationMs - e);
    final window = plan.windowAt(e);
    final inFinal = plan.final10 != null && plan.final10!.contains(e);
    final phase = inFinal
        ? SessionPhase.final10
        : window != null
        ? SessionPhase.agitate
        : SessionPhase.rest;
    final nextStart = plan.nextWindowStartAfter(e);
    return SessionState(
      phase: phase,
      stepIndex: idx,
      step: step,
      remaining: remaining,
      untilAgitationEnds: window == null
          ? null
          : Duration(milliseconds: window.endMs - e),
      untilNextAgitation: nextStart == null
          ? null
          : Duration(milliseconds: nextStart - e),
      windowElapsed: window == null
          ? null
          : Duration(milliseconds: e - window.startMs),
      undoAvailable: undo,
    );
  }

  /// Whether the whole process has finished by [now] (a last timed step ran
  /// out, or the process was completed or aborted).
  bool isFinished(DateTime now) => stateAt(now).isFinished;

  bool _undoAvailable(DateTime now) {
    for (final r in runs) {
      if (r.undoUntil != null && !now.isAfter(r.undoUntil!)) return true;
    }
    return false;
  }

  // ----------------------------------------------------------- transitions

  /// Starts the first step.
  void start(DateTime now) {
    if (runs.isNotEmpty) return;
    startedAt = now;
    final run = StepRun(0, startedAt: now);
    if (planFor(0).isIlford) run.fillStarts.add(now);
    runs.add(run);
  }

  void _clearUndo() {
    for (final r in runs) {
      r.undoUntil = null;
      r.undoKind = null;
    }
  }

  /// Presses Next. Returns false when no Next is available at [now].
  bool next(DateTime now) {
    if (status != SessionStatus.active || runs.isEmpty) return false;
    _materialize(now);
    final st = stateAt(now);
    if (st.phase != SessionPhase.dumpPour) return false;
    final run = runs.last;
    final plan = planFor(run.stepIndex, run.adjustMs);
    _clearUndo();
    if (plan.isIlford && st.fillIndex! < plan.fills.length - 1) {
      if (run.fillStarts.isEmpty) run.fillStarts.add(run.startedAt!);
      run.fillStarts.add(now);
      run.undoUntil = now.add(undoWindow);
      run.undoKind = 'fill';
      return true;
    }
    run.nextPressedAt = now;
    run.undoUntil = now.add(undoWindow);
    if (run.stepIndex + 1 < steps.length) {
      run.undoKind = 'step';
      final nextRun = StepRun(run.stepIndex + 1, startedAt: now);
      if (planFor(nextRun.stepIndex).isIlford) nextRun.fillStarts.add(now);
      runs.add(nextRun);
    } else {
      run.undoKind = 'finish';
      status = SessionStatus.completed;
      finishedAt = now;
    }
    return true;
  }

  /// Undoes the last Next within [undoWindow]. A no-op afterwards.
  bool undo(DateTime now) {
    for (var i = runs.length - 1; i >= 0; i--) {
      final r = runs[i];
      if (r.undoUntil == null) continue;
      if (now.isAfter(r.undoUntil!)) return false;
      switch (r.undoKind) {
        case 'step':
          if (i != runs.length - 2) return false;
          runs.removeLast();
          r.nextPressedAt = null;
        case 'fill':
          if (r.fillStarts.length < 2) return false;
          r.fillStarts.removeLast();
        case 'finish':
          status = SessionStatus.active;
          finishedAt = null;
          r.nextPressedAt = null;
        default:
          return false;
      }
      r.undoUntil = null;
      r.undoKind = null;
      return true;
    }
    return false;
  }

  bool pause(DateTime now) {
    if (status != SessionStatus.active) return false;
    _materialize(now);
    final st = stateAt(now);
    if (!(st.phase == SessionPhase.agitate ||
        st.phase == SessionPhase.rest ||
        st.phase == SessionPhase.final10 ||
        st.phase == SessionPhase.washFill)) {
      return false;
    }
    _clearUndo();
    runs.last.pauses.add(Pause(now));
    return true;
  }

  bool resume(DateTime now) {
    if (status != SessionStatus.active || runs.isEmpty) return false;
    for (final p in runs.last.pauses) {
      if (p.to == null) {
        p.to = now;
        return true;
      }
    }
    return false;
  }

  /// Adds [deltaS] seconds (±30 in the UI) to the running step. A reduction
  /// never goes below the time already elapsed.
  bool adjust(DateTime now, int deltaS) {
    if (status != SessionStatus.active) return false;
    _materialize(now);
    final st = stateAt(now);
    if (!(st.phase == SessionPhase.agitate ||
            st.phase == SessionPhase.rest ||
            st.phase == SessionPhase.final10 ||
            st.phase == SessionPhase.paused) ||
        st.remaining == null) {
      return false;
    }
    final run = runs.last;
    final plan = planFor(run.stepIndex, run.adjustMs);
    final elapsed = plan.durationMs! - st.remaining!.inMilliseconds;
    final nominal = plan.durationMs! - run.adjustMs;
    var adjust = run.adjustMs + deltaS * 1000;
    if (adjust + nominal < elapsed) adjust = elapsed - nominal;
    if (adjust + nominal < 1000) adjust = 1000 - nominal;
    if (adjust == run.adjustMs) return false;
    _clearUndo();
    run.adjustMs = adjust;
    return true;
  }

  void abort(DateTime now) {
    if (status != SessionStatus.active) return;
    _materialize(now);
    status = SessionStatus.aborted;
    finishedAt = now;
    abortedAtStep = runs.isEmpty ? null : runs.last.stepIndex;
  }

  /// Records completion once a last timed step has run out, so persisted
  /// state matches [stateAt].
  void finishIfDone(DateTime now) {
    if (status != SessionStatus.active) return;
    final st = stateAt(now);
    if (st.phase == SessionPhase.done) {
      _materialize(now);
      status = SessionStatus.completed;
      finishedAt = _segments().last.end ?? now;
    }
  }

  // ------------------------------------------------------------------ cues

  /// Cues falling in `(now, now + horizon]`, in time order. Only what is
  /// already determined is returned: in wait-for-me mode nothing past the
  /// current step's end, and nothing after an open pause.
  List<CueEvent> upcomingCues(DateTime now, Duration horizon) {
    if (status != SessionStatus.active || runs.isEmpty) return const [];
    final until = now.add(horizon);
    final out = <CueEvent>[];
    final segs = _segments();
    final current = _current(now);
    for (final s in segs) {
      if (current != null && s.start.isBefore(current.start)) continue;
      if (s.start.isAfter(until)) break;
      _cuesFor(s, now, until, out);
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  void _cuesFor(_Seg s, DateTime now, DateTime until, List<CueEvent> out) {
    final plan = s.plan;
    final step = plan.step;
    final tag = '$tankLabel · ${step.name}';
    final isLast = s.run.stepIndex + 1 >= steps.length;
    void add(
      int activeMs,
      CueKind kind,
      String body, {
      bool background = false,
      DateTime? base,
    }) {
      final at = _wallAt(base ?? s.start, activeMs, s.run.pauses);
      if (at == null || !at.isAfter(now) || at.isAfter(until)) return;
      out.add(
        CueEvent(
          at: at,
          tankSlot: tankSlot,
          kind: kind,
          title: tag,
          body: body,
          background: background,
        ),
      );
    }

    if (plan.isIlford) {
      final starts = s.run.fillStarts.isEmpty ? [s.start] : s.run.fillStarts;
      final fill = starts.length - 1;
      final n = plan.fills[fill];
      final base = starts.last;
      add(
        0,
        CueKind.agitateStart,
        'Fill ${fill + 1}/${plan.fills.length} · invert $n times',
        background: true,
        base: base,
      );
      for (var i = 0; i < n; i++) {
        add(i * plan.paceMs, CueKind.tick, '', base: base);
      }
      add(
        n * plan.paceMs,
        CueKind.dumpPour,
        fill + 1 < plan.fills.length ? 'Dump → next fill' : 'Dump',
        background: true,
        base: base,
      );
      return;
    }

    final d = plan.durationMs!;
    for (final w in plan.windows) {
      final inv = w.lengthMs ~/ plan.paceMs;
      add(
        w.startMs,
        CueKind.agitateStart,
        'Agitate ${(w.lengthMs / 1000).round()} s · $inv inversions',
        background: true,
      );
    }
    for (final t in plan.ticksMs) {
      add(t, CueKind.tick, '');
    }
    final f = plan.final10!;
    var pip = 0;
    for (var ms = f.startMs; ms < d; ms += 1000) {
      add(ms, CueKind.finalPip, 'Last 10 s', background: pip == 0);
      pip++;
    }
    if (!isLast) {
      final nextName = steps[s.run.stepIndex + 1].name;
      add(d, CueKind.dumpPour, 'Dump → pour $nextName', background: true);
    } else {
      add(d, CueKind.dumpPour, 'Done', background: true);
    }
  }
}
