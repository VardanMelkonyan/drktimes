import 'package:drktimes/domain/process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Process.defaults', () {
    final p = Process.defaults();

    test('matches the data-model table', () {
      expect(p.id, 'default');
      expect(p.transitionMode, TransitionMode.waitForMe);
      expect([for (final s in p.steps) s.kind], [
        StepKind.presoak,
        StepKind.developer,
        StepKind.stop,
        StepKind.fix,
        StepKind.hypoClear,
        StepKind.wash,
        StepKind.wettingAgent,
      ]);
      expect([for (final s in p.steps) s.enabled],
          [false, true, true, true, false, true, true]);
      Step at(StepKind k) => p.steps.firstWhere((s) => s.kind == k);
      expect(at(StepKind.presoak).durationS, 60);
      expect(at(StepKind.presoak).agitation, const Stand(initialS: 30));
      expect(at(StepKind.developer).agitation,
          const Intermittent(initialS: 60, everyS: 60, burstS: 10));
      expect(at(StepKind.stop).durationS, 60);
      expect(at(StepKind.stop).agitation,
          const Intermittent(initialS: 60, everyS: 60, burstS: 10));
      expect(at(StepKind.fix).durationS, 300);
      expect(at(StepKind.hypoClear).durationS, 120);
      expect(at(StepKind.hypoClear).agitation,
          const Intermittent(initialS: 30, everyS: 60, burstS: 10));
      expect(at(StepKind.wash).wash, const IlfordWash([5, 10, 20]));
      expect(at(StepKind.wash).agitation, const NoAgitation());
      expect(at(StepKind.wettingAgent).durationS, 30);
    });

    test('is valid and has prefilled how-to text', () {
      expect(p.validate(), isEmpty);
      expect(
          p.steps.firstWhere((s) => s.kind == StepKind.hypoClear).howTo,
          contains('wash'));
      expect(
          p.steps.firstWhere((s) => s.kind == StepKind.wettingAgent).howTo,
          contains('foam'));
    });
  });

  group('validate', () {
    Process with_(List<Step> Function(List<Step>) f) {
      final d = Process.defaults();
      return d.copyWith(steps: f(d.steps));
    }

    test('needs exactly one developer step', () {
      expect(
          with_((s) => s.where((x) => x.kind != StepKind.developer).toList())
              .validate(),
          isNotEmpty);
      expect(
          with_((s) => [...s, s[1].copyWith(id: 'dup')]).validate(), isNotEmpty);
    });

    test('rejects zero enabled steps', () {
      expect(
          with_((s) => [for (final x in s) x.copyWith(enabled: false)])
              .validate(),
          isNotEmpty);
    });

    test('rejects burst >= every', () {
      final p = with_((s) => [
            for (final x in s)
              x.kind == StepKind.stop
                  ? x.copyWith(
                      agitation: const Intermittent(
                          initialS: 0, everyS: 30, burstS: 30))
                  : x
          ]);
      expect(p.validate(), isNotEmpty);
    });

    test('rejects Ilford fills outside 1–50', () {
      for (final bad in [0, 51]) {
        final p = with_((s) => [
              for (final x in s)
                x.kind == StepKind.wash
                    ? x.copyWith(wash: IlfordWash([5, bad]))
                    : x
            ]);
        expect(p.validate(), isNotEmpty, reason: '$bad');
      }
    });

    test('rejects an over-long name and how-to', () {
      final p = with_((s) => [s[0].copyWith(name: 'x' * 41), ...s.skip(1)]);
      expect(p.validate(), isNotEmpty);
      final q = with_((s) => [s[0].copyWith(howTo: 'x' * 1001), ...s.skip(1)]);
      expect(q.validate(), isNotEmpty);
    });
  });

  test('json round trip', () {
    final p = Process.defaults();
    final j = p.toJson();
    expect(Process.fromJson(j).toJson(), j);
    final stepJson = (j['steps'] as List)[1] as Map<String, dynamic>;
    expect(stepJson['kind'], 'developer');
    expect((stepJson['agitation'] as Map)['type'], 'intermittent');
    final wash = ((j['steps'] as List)[5] as Map)['wash'] as Map;
    expect(wash, {'method': 'ilford', 'fills': [5, 10, 20]});
    for (final a in const [
      Continuous(),
      Stand(initialS: 30, midAgitationAtS: 390, midBurstS: 10),
      NoAgitation(),
    ]) {
      expect(AgitationPattern.fromJson(a.toJson()), a);
    }
    expect(WashMethod.fromJson(const RunningWash(600).toJson()),
        const RunningWash(600));
  });
}
