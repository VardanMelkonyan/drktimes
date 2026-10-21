import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/timeline/compile.dart';
import 'package:flutter_test/flutter_test.dart';

Step step(AgitationPattern a, {StepKind kind = StepKind.developer}) => Step(
  id: 's',
  kind: kind,
  name: 'Dev',
  enabled: true,
  agitation: a,
  durationS: 60,
);

StepPlan plan(AgitationPattern a, {int devS = 780, int paceMs = 2000}) =>
    compileStep(step(a), devTimeS: devS, paceMs: paceMs);

List<int> secs(Iterable<int> ms) => [for (final m in ms) m ~/ 1000];

void main() {
  const pattern = Intermittent(initialS: 60, everyS: 60, burstS: 10);

  test('intermittent {60,60,10} over 780 s', () {
    final p = plan(pattern);
    expect(p.windows.first, const Window(0, 60000));
    expect(p.windows[1], const Window(120000, 130000));
    expect(p.windows[2], const Window(180000, 190000));
    expect(p.windows.last, const Window(720000, 730000));
    expect(p.windows.every((w) => w.startMs < 770000), isTrue);
    expect(p.windows, hasLength(1 + 11));
  });

  test('ticks every pace inside each window', () {
    final p = plan(pattern);
    final first = p.ticksMs.where((t) => t < 60000).toList();
    expect(first, hasLength(30));
    expect(first.first, 0);
    expect(first[1], 2000);
    expect(p.ticksMs.where((t) => t >= 120000 && t < 130000), hasLength(5));
    expect(p.ticksMs, hasLength(30 + 11 * 5));
  });

  test('tick count follows the pace', () {
    final p = plan(pattern, paceMs: 1500);
    expect(p.ticksMs.where((t) => t < 60000), hasLength(40));
  });

  test('final-10 window', () {
    expect(plan(pattern).final10, const Window(770000, 780000));
    expect(plan(pattern, devS: 6).final10, const Window(0, 6000));
  });

  test('continuous is one window over the step', () {
    expect(plan(const Continuous()).windows, [const Window(0, 780000)]);
  });

  test('stand {30, mid 390, 10}', () {
    final p = plan(
      const Stand(initialS: 30, midAgitationAtS: 390, midBurstS: 10),
    );
    expect(p.windows, [const Window(0, 30000), const Window(390000, 400000)]);
  });

  test('none has no windows or ticks', () {
    final p = plan(const NoAgitation());
    expect(p.windows, isEmpty);
    expect(p.ticksMs, isEmpty);
  });

  test('adjustment moves the end and the windows follow', () {
    final plus = compileStep(
      step(pattern),
      devTimeS: 780,
      paceMs: 2000,
      adjustMs: 30000,
    );
    expect(plus.durationMs, 810000);
    expect(plus.final10, const Window(800000, 810000));
    expect(plus.windows.last, const Window(780000, 790000));
    final minus = compileStep(
      step(pattern),
      devTimeS: 780,
      paceMs: 2000,
      adjustMs: -90000,
    );
    expect(minus.windows.last, const Window(660000, 670000));
  });

  test('Ilford wash is three counted fills with no clock end', () {
    final p = compileStep(
      const Step(
        id: 'w',
        kind: StepKind.wash,
        name: 'Wash',
        enabled: true,
        agitation: NoAgitation(),
        wash: IlfordWash([5, 10, 20]),
      ),
      devTimeS: 780,
      paceMs: 2000,
    );
    expect(p.isTimed, isFalse);
    expect(p.fills, [5, 10, 20]);
  });

  test('running wash is timed', () {
    final p = compileStep(
      const Step(
        id: 'w',
        kind: StepKind.wash,
        name: 'Wash',
        enabled: true,
        agitation: NoAgitation(),
        wash: RunningWash(600),
      ),
      devTimeS: 780,
      paceMs: 2000,
    );
    expect(p.durationMs, 600000);
  });

  test('developer time comes from the recipe, other steps from the step', () {
    final fix = compileStep(
      step(pattern, kind: StepKind.fix),
      devTimeS: 780,
      paceMs: 2000,
    );
    expect(fix.durationMs, 60000);
  });

  test('secs helper sanity', () => expect(secs([2000, 4000]), [2, 4]));
}
