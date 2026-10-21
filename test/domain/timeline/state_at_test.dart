import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/timeline/cue_event.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRun make({
  TransitionMode mode = TransitionMode.waitForMe,
  int devS = 780,
  Process? process,
}) {
  final p = (process ?? Process.defaults()).copyWith(transitionMode: mode);
  return SessionRun(
    id: 'r',
    tankSlot: 1,
    process: p,
    devTimeS: devS,
    inversionPaceS: 2,
  );
}

Duration s(int n) => Duration(seconds: n);

void main() {
  late FakeClock clock;
  setUp(() => clock = FakeClock());

  SessionState at(SessionRun r) => r.stateAt(clock.now());

  test('ready before start', () {
    expect(at(make()).phase, SessionPhase.ready);
  });

  group('developer step states', () {
    late SessionRun r;
    setUp(() {
      r = make();
      r.start(clock.now());
    });

    test('agitate, rest, final10 with remaining values', () {
      var st = at(r);
      expect(st.phase, SessionPhase.agitate);
      expect(st.stepIndex, 0);
      expect(st.step!.kind, StepKind.developer);
      expect(st.remaining, s(780));
      expect(st.untilAgitationEnds, s(60));
      expect(st.untilNextAgitation, s(120));

      clock.advance(s(75));
      st = at(r);
      expect(st.phase, SessionPhase.rest);
      expect(st.remaining, s(705));
      expect(st.untilNextAgitation, s(45));

      clock.advance(s(45));
      expect(at(r).phase, SessionPhase.agitate);
      expect(at(r).windowElapsed, Duration.zero);

      clock.set(DateTime.utc(2026, 1, 1, 12).add(s(775)));
      st = at(r);
      expect(st.phase, SessionPhase.final10);
      expect(st.remaining, s(5));
    });

    test('dump_pour after time up, waiting counts up', () {
      clock.advance(s(792));
      final st = at(r);
      expect(st.phase, SessionPhase.dumpPour);
      expect(st.waited, s(12));
      expect(st.awaitingSince, DateTime.utc(2026, 1, 1, 12).add(s(780)));
    });
  });

  group('pause', () {
    test('freezes the remaining time and resumes exactly', () {
      final r = make()..start(clock.now());
      clock.advance(s(100));
      expect(r.pause(clock.now()), isTrue);
      final frozen = at(r);
      expect(frozen.phase, SessionPhase.paused);
      expect(frozen.remaining, s(680));

      clock.advance(s(500));
      expect(at(r).remaining, s(680));
      expect(r.resume(clock.now()), isTrue);
      expect(at(r).remaining, s(680));

      clock.advance(s(80));
      expect(at(r).remaining, s(600));
      clock.advance(s(600));
      expect(at(r).phase, SessionPhase.dumpPour);
    });

    test('cannot pause while waiting for Next', () {
      final r = make()..start(clock.now());
      clock.advance(s(800));
      expect(r.pause(clock.now()), isFalse);
    });
  });

  group('adjust', () {
    test('+30 s extends the step', () {
      final r = make()..start(clock.now());
      clock.advance(s(100));
      expect(r.adjust(clock.now(), 30), isTrue);
      expect(at(r).remaining, s(710));
      clock.advance(s(710));
      expect(at(r).phase, SessionPhase.dumpPour);
    });

    test('-30 s never goes below the time already elapsed', () {
      final r = make(devS: 120)..start(clock.now());
      clock.advance(s(100));
      expect(r.adjust(clock.now(), -30), isTrue);
      // Only 20 s were left: the step ends now, not 10 s in the past.
      final st = at(r);
      expect(st.phase, SessionPhase.dumpPour);
      expect(st.waited, Duration.zero);
      expect(st.awaitingSince, DateTime.utc(2026, 1, 1, 12).add(s(100)));
    });

    test('-30 s shortens a long step', () {
      final r = make()..start(clock.now());
      clock.advance(s(10));
      r.adjust(clock.now(), -30);
      expect(at(r).remaining, s(740));
    });
  });

  group('transitions', () {
    test('wait_for_me stays in dump_pour until next()', () {
      final r = make()..start(clock.now());
      clock.advance(s(900));
      expect(at(r).phase, SessionPhase.dumpPour);
      expect(at(r).waited, s(120));
      expect(r.next(clock.now()), isTrue);
      final st = at(r);
      expect(st.stepIndex, 1);
      expect(st.step!.kind, StepKind.stop);
      expect(st.remaining, s(60));
    });

    test('keep_going starts the next step at the previous end', () {
      final r = make(mode: TransitionMode.keepGoing)..start(clock.now());
      clock.advance(s(800));
      final st = at(r);
      expect(st.step!.kind, StepKind.stop);
      expect(st.remaining, s(40));
      clock.advance(s(40));
      expect(at(r).step!.kind, StepKind.fix);
      expect(at(r).remaining, s(300));
    });

    test('undo within 5 s restores dump_pour exactly', () {
      final r = make()..start(clock.now());
      clock.advance(s(790));
      final before = at(r);
      r.next(clock.now());
      clock.advance(s(3));
      expect(at(r).undoAvailable, isTrue);
      expect(r.undo(clock.now()), isTrue);
      final after = at(r);
      expect(after.phase, SessionPhase.dumpPour);
      expect(after.stepIndex, before.stepIndex);
      expect(after.awaitingSince, before.awaitingSince);
      expect(after.waited, before.waited! + s(3));
    });

    test('undo after 5 s is a no-op', () {
      final r = make()..start(clock.now());
      clock.advance(s(790));
      r.next(clock.now());
      clock.advance(s(6));
      expect(r.undo(clock.now()), isFalse);
      expect(at(r).stepIndex, 1);
    });

    test('next() is refused while the step runs', () {
      final r = make()..start(clock.now());
      clock.advance(s(10));
      expect(r.next(clock.now()), isFalse);
    });

    test('abort', () {
      final r = make()..start(clock.now());
      clock.advance(s(10));
      r.abort(clock.now());
      expect(at(r).phase, SessionPhase.aborted);
      expect(r.status, SessionStatus.aborted);
      expect(r.abortedAtStep, 0);
    });
  });

  group('Ilford wash', () {
    SessionRun washOnly() {
      final p = Process.defaults();
      return make(
        devS: 10,
        process: p.copyWith(
          steps: [
            for (final st in p.steps)
              st.copyWith(
                enabled:
                    st.kind == StepKind.developer || st.kind == StepKind.wash,
              ),
          ],
        ),
      );
    }

    test('three fills with counted inversions, Next between fills', () {
      final r = washOnly()..start(clock.now());
      clock.advance(s(10));
      expect(at(r).phase, SessionPhase.dumpPour);
      expect(r.next(clock.now()), isTrue);

      var st = at(r);
      expect(st.phase, SessionPhase.washFill);
      expect(st.fillIndex, 0);
      expect(st.fillCount, 3);
      expect(st.inversionsTarget, 5);
      clock.advance(s(4));
      expect(at(r).inversionsDone, 2);
      expect(at(r).windowElapsed, s(4), reason: 'drives the pulse');
      clock.advance(s(6));
      st = at(r);
      expect(st.phase, SessionPhase.dumpPour);
      expect(st.inversionsDone, 5);

      expect(r.next(clock.now()), isTrue);
      st = at(r);
      expect(st.phase, SessionPhase.washFill);
      expect(st.fillIndex, 1);
      expect(st.inversionsTarget, 10);
      clock.advance(s(20));
      expect(at(r).phase, SessionPhase.dumpPour);
      expect(r.next(clock.now()), isTrue);
      expect(at(r).inversionsTarget, 20);
      clock.advance(s(40));
      expect(at(r).phase, SessionPhase.dumpPour);
      expect(r.next(clock.now()), isTrue);
      expect(at(r).phase, SessionPhase.done);
      expect(r.status, SessionStatus.completed);
    });

    test('undo a fill, and undo the finish', () {
      final r = washOnly()..start(clock.now());
      clock.advance(s(10));
      r.next(clock.now());
      clock.advance(s(10));
      r.next(clock.now());
      expect(at(r).fillIndex, 1);
      expect(r.undo(clock.now()), isTrue);
      expect(at(r).fillIndex, 0);
      expect(at(r).phase, SessionPhase.dumpPour);

      r.next(clock.now());
      clock.advance(s(20));
      r.next(clock.now());
      clock.advance(s(40));
      r.next(clock.now());
      expect(r.status, SessionStatus.completed);
      expect(r.undo(clock.now()), isTrue);
      expect(r.status, SessionStatus.active);
      expect(at(r).phase, SessionPhase.dumpPour);
    });

    test('a fill can be paused', () {
      final r = washOnly()..start(clock.now());
      clock.advance(s(10));
      r.next(clock.now());
      clock.advance(s(4));
      expect(r.pause(clock.now()), isTrue);
      clock.advance(s(100));
      expect(at(r).phase, SessionPhase.paused);
      expect(at(r).inversionsDone, 2);
      r.resume(clock.now());
      clock.advance(s(6));
      expect(at(r).phase, SessionPhase.dumpPour);
    });
  });

  test('persisted anchors rebuild the same state', () {
    final r = make()..start(clock.now());
    clock.advance(s(100));
    r.pause(clock.now());
    clock.advance(s(30));
    r.resume(clock.now());
    clock.advance(s(10));
    final rebuilt = SessionRun.fromJson(r.toJson());
    expect(rebuilt.stateAt(clock.now()).remaining, at(r).remaining);
    expect(rebuilt.stateAt(clock.now()).phase, at(r).phase);
  });

  test('upcoming cues are time-ordered and attention cues are marked', () {
    final r = make()..start(clock.now());
    final cues = r.upcomingCues(clock.now(), s(200));
    expect(cues.first.kind, CueKind.tick);
    final times = [for (final c in cues) c.at];
    expect([...times]..sort(), times);
    final agitate = cues.where((c) => c.kind == CueKind.agitateStart).toList();
    expect(agitate.map((c) => c.at.difference(DateTime.utc(2026, 1, 1, 12))), [
      s(120),
      s(180),
    ]);
    expect(agitate.every((c) => c.background), isTrue);
    expect(
      cues.where((c) => c.kind == CueKind.tick).every((c) => !c.background),
      isTrue,
    );
  });
}
