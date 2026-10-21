import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/sessions.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:flutter_test/flutter_test.dart';

Duration s(int n) => Duration(seconds: n);

void main() {
  late FakeClock clock;
  late SessionCoordinator c;
  setUp(() {
    clock = FakeClock();
    c = SessionCoordinator();
  });

  SessionRun add({int devS = 60, String? label}) => c.create(
    process: Process.defaults(),
    devTimeS: devS,
    inversionPaceS: 2,
    label: label,
  );

  test('at most 3 active sessions', () {
    add();
    add();
    add();
    expect(c.active, hasLength(3));
    expect(add, throwsA(isA<TankLimitReached>()));
  });

  test('slots are reused when freed, with default labels', () {
    final a = add();
    final b = add();
    expect([a.tankSlot, b.tankSlot], [1, 2]);
    expect([a.tankLabel, b.tankLabel], ['Tank 1', 'Tank 2']);
    c.abort(a, clock.now());
    final d = add();
    expect(d.tankSlot, 1);
    expect(d.tankLabel, 'Tank 1');
    expect(c.active.map((e) => e.tankSlot), [1, 2]);
  });

  test('a custom label is kept', () {
    expect(add(label: 'Rodinal').tankLabel, 'Rodinal');
  });

  test('Next goes to the tank that has waited longest', () {
    final a = add(devS: 100)..start(clock.now());
    clock.advance(s(10));
    final b = add(devS: 100)..start(clock.now());
    clock.advance(s(200));
    expect(a.stateAt(clock.now()).phase, SessionPhase.dumpPour);
    expect(b.stateAt(clock.now()).phase, SessionPhase.dumpPour);
    expect(c.nextTarget(clock.now()), same(a));
    expect(c.next(clock.now()), same(a));
    expect(a.stateAt(clock.now()).stepIndex, 1);
    expect(b.stateAt(clock.now()).stepIndex, 0);
    expect(c.nextTarget(clock.now()), same(b));
    expect(c.next(clock.now()), same(b));
    expect(c.next(clock.now()), isNull);
  });

  test('undo acts on the session the last next() hit', () {
    final a = add(devS: 100)..start(clock.now());
    final b = add(devS: 100)..start(clock.now());
    clock.advance(s(150));
    c.next(clock.now());
    clock.advance(s(1));
    c.next(clock.now());
    expect(c.undo(clock.now()), same(b));
    expect(b.stateAt(clock.now()).stepIndex, 0);
    expect(a.stateAt(clock.now()).stepIndex, 1);
    expect(c.undo(clock.now()), isNull);
  });

  test('merged cues are time ordered and capped at 60', () {
    add(devS: 780).start(clock.now());
    add(devS: 780).start(clock.now());
    clock.advance(s(1));
    final cues = c.upcomingCues(clock.now(), s(600));
    expect(cues.length, 60);
    final t = [for (final e in cues) e.at];
    expect([...t]..sort(), t);
    expect(cues.map((e) => e.tankSlot).toSet(), {1, 2});
  });

  test('background cues skip ticks', () {
    add(devS: 780).start(clock.now());
    final cues = c.upcomingCues(clock.now(), s(600), backgroundOnly: true);
    expect(cues, isNotEmpty);
    expect(cues.every((e) => e.background), isTrue);
  });

  test('finished sessions free their slot', () {
    final a = add(devS: 5)..start(clock.now());
    final p = Process.defaults();
    expect(a.steps.length, p.enabledSteps.length);
    c.abort(a, clock.now());
    expect(c.active, isEmpty);
    expect(c.all, contains(a));
  });
}
