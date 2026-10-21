import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/process.dart';
import 'widgets.dart';

String describeAgitation(AgitationPattern a) => switch (a) {
  Intermittent(:final initialS, :final everyS, :final burstS) =>
    initialS > 0
        ? '$initialS s at the start, then $burstS s every $everyS s'
        : '$burstS s every $everyS s',
  Continuous() => 'continuous',
  Stand(:final initialS, :final midAgitationAtS, :final midBurstS) =>
    midAgitationAtS == null
        ? '$initialS s at the start, then stand'
        : '$initialS s at the start, $midBurstS s at ${midAgitationAtS ~/ 60}:${(midAgitationAtS % 60).toString().padLeft(2, '0')}',
  NoAgitation() => 'none',
};

String agitationName(AgitationPattern a) => switch (a) {
  Intermittent() => 'Intermittent',
  Continuous() => 'Continuous',
  Stand() => 'Stand / semi',
  NoAgitation() => 'None',
};

/// Picks an agitation pattern and edits its numbers.
class AgitationEditor extends StatelessWidget {
  const AgitationEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AgitationPattern value;
  final ValueChanged<AgitationPattern> onChanged;

  int get _index => switch (value) {
    Intermittent() => 0,
    Continuous() => 1,
    Stand() => 2,
    NoAgitation() => 3,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget num_(
      String label,
      int v,
      ValueChanged<int> set, {
      required int min,
      required int max,
      int step = 5,
      Key? key,
    }) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: DrkType.sm.copyWith(color: p.mut)),
            ),
            SizedBox(
              width: 170,
              child: DrkStepper(
                key: key,
                value: '$v s',
                height: 44,
                fontSize: 14,
                minusLabel: '$label shorter',
                plusLabel: '$label longer',
                onMinus: v > min ? () => set((v - step).clamp(min, max)) : null,
                onPlus: v < max ? () => set((v + step).clamp(min, max)) : null,
              ),
            ),
          ],
        ),
      );
    }

    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Seg(
          labels: const ['Intermittent', 'Continuous', 'Stand', 'None'],
          selected: _index,
          onChanged: (i) => onChanged(switch (i) {
            0 => const Intermittent(initialS: 60, everyS: 60, burstS: 10),
            1 => const Continuous(),
            2 => const Stand(initialS: 30),
            _ => const NoAgitation(),
          }),
        ),
        if (v is Intermittent) ...[
          num_(
            'First agitation',
            v.initialS,
            (x) => onChanged(
              Intermittent(initialS: x, everyS: v.everyS, burstS: v.burstS),
            ),
            min: 0,
            max: 600,
            key: const Key('agit-initial'),
          ),
          num_(
            'Then agitate for',
            v.burstS,
            (x) => onChanged(
              Intermittent(
                initialS: v.initialS,
                everyS: v.everyS <= x ? x + 1 : v.everyS,
                burstS: x,
              ),
            ),
            min: 1,
            max: 59,
            step: 1,
            key: const Key('agit-burst'),
          ),
          num_(
            'Every',
            v.everyS,
            (x) => onChanged(
              Intermittent(initialS: v.initialS, everyS: x, burstS: v.burstS),
            ),
            min: v.burstS + 1,
            max: 600,
            key: const Key('agit-every'),
          ),
        ],
        if (v is Stand) ...[
          num_(
            'First agitation',
            v.initialS,
            (x) => onChanged(
              Stand(
                initialS: x,
                midAgitationAtS: v.midAgitationAtS,
                midBurstS: v.midBurstS,
              ),
            ),
            min: 0,
            max: 600,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Agitate once mid-stand',
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                ),
                DrkSwitch(
                  value: v.midAgitationAtS != null,
                  label: 'Agitate once mid-stand',
                  onChanged: (on) => onChanged(
                    Stand(
                      initialS: v.initialS,
                      midAgitationAtS: on ? 1800 : null,
                      midBurstS: on ? 10 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (v.midAgitationAtS != null) ...[
            num_(
              'At',
              v.midAgitationAtS!,
              (x) => onChanged(
                Stand(
                  initialS: v.initialS,
                  midAgitationAtS: x,
                  midBurstS: v.midBurstS,
                ),
              ),
              min: 30,
              max: 7200,
              step: 30,
            ),
            num_(
              'For',
              v.midBurstS ?? 10,
              (x) => onChanged(
                Stand(
                  initialS: v.initialS,
                  midAgitationAtS: v.midAgitationAtS,
                  midBurstS: x,
                ),
              ),
              min: 1,
              max: 60,
              step: 1,
            ),
          ],
        ],
        const SizedBox(height: 6),
        Text(describeAgitation(v), style: DrkType.sm.copyWith(color: p.mut)),
      ],
    );
  }
}
