import 'dart:math';

import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:flutter_test/flutter_test.dart';

/// SC-003: step boundaries stay within ±1 s of plan over a whole session,
/// including a locked-phone gap and a rebuild from persisted anchors.
List<DateTime> simulate(int seed, {required bool rebuildHalfway}) {
  final rnd = Random(seed);
  final clock = FakeClock();
  var r = SessionRun(
    id: 'r',
    tankSlot: 1,
    process: Process.defaults().copyWith(
      transitionMode: TransitionMode.keepGoing,
    ),
    devTimeS: 780,
    inversionPaceS: 2,
  )..start(clock.now());

  final bigJumpAt = 40 + rnd.nextInt(60);
  var i = 0;
  var rebuilt = false;
  while (!r.isFinished(clock.now()) && i < 100000) {
    i++;
    final ms = i == bigJumpAt
        ? const Duration(minutes: 20).inMilliseconds
        : 100 + rnd.nextInt(6900);
    clock.advance(Duration(milliseconds: ms));
    final st = r.stateAt(clock.now());
    // The user presses Next whenever the wash is waiting on them.
    if (st.phase == SessionPhase.dumpPour) {
      r.next(clock.now());
    } else {
      r.syncAnchors(clock.now());
    }
    if (rebuildHalfway && !rebuilt && i > bigJumpAt + 30) {
      r = SessionRun.fromJson(r.toJson());
      rebuilt = true;
    }
  }
  r.finishIfDone(clock.now());
  expect(r.status, SessionStatus.completed);
  return [for (final run in r.runs) run.startedAt!];
}

void main() {
  test('step boundaries are within ±1 s of plan', () {
    final starts = simulate(1, rebuildHalfway: false);
    final start = DateTime.utc(2026, 1, 1, 12);
    // Steps that follow on their own are exact: developer 780 s, stop 60 s,
    // fix 300 s. The wash then waits for the user.
    final expected = [0, 780, 840];
    expect(starts.length, greaterThanOrEqualTo(4));
    for (final (i, e) in expected.indexed) {
      expect(
        (starts[i].difference(start).inMilliseconds - e * 1000).abs(),
        lessThanOrEqualTo(1000),
        reason: 'step $i',
      );
    }
    // Step 3 (wash) starts when the fix ends.
    expect(
      (starts[3].difference(start).inMilliseconds - 1140 * 1000).abs(),
      lessThanOrEqualTo(1000),
    );
  });

  test('rebuilding from persisted anchors halfway changes nothing', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final a = simulate(seed, rebuildHalfway: false);
      final b = simulate(seed, rebuildHalfway: true);
      expect(b, a, reason: 'seed $seed');
    }
  });

  test('a 20-minute jump (locked phone) lands in the right step', () {
    final clock = FakeClock();
    final r = SessionRun(
      id: 'r',
      tankSlot: 1,
      process: Process.defaults().copyWith(
        transitionMode: TransitionMode.keepGoing,
      ),
      devTimeS: 780,
      inversionPaceS: 2,
    )..start(clock.now());
    clock.advance(const Duration(minutes: 20));
    final st = r.stateAt(clock.now());
    // 1200 s: past developer (780) + stop (60) + fix (300) = 1140; now in wash.
    expect(st.step!.kind, StepKind.wash);
    expect(st.fillIndex, 0);
  });
}
