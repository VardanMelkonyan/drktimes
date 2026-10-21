import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/combination_key.dart';
import '../../domain/format.dart';
import '../common/widgets.dart';
import 'picker_scaffold.dart';
import 'picker_state.dart';

/// PickDilution.dc.html: step 4 of 4. Dilution and temperature are
/// preselected from the data and editable (FR-009, FR-073).
class PickDilutionScreen extends ConsumerStatefulWidget {
  const PickDilutionScreen({super.key});

  @override
  ConsumerState<PickDilutionScreen> createState() => _PickDilutionScreenState();
}

class _PickDilutionScreenState extends ConsumerState<PickDilutionScreen> {
  final _custom = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = ref.watch(pickerProvider);
    final q = ref.watch(pickerQueriesProvider).value;
    final fahrenheit =
        ref.watch(settingsProvider).value?.tempUnit == TempUnit.f;
    if (s.film == null || s.developer == null || s.ei == null || q == null) {
      return const PickerScaffold(
        step: 4,
        title: 'Dilution & temperature',
        child: SizedBox(),
      );
    }
    final options = q.dilutionsFor(s.film!, s.developer!, s.ei!);
    if (!_seeded && options.isNotEmpty && s.dilution == null) {
      _seeded = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref
            .read(pickerProvider.notifier)
            .pickDilution(options.first.dilution, tempC: options.first.tempC),
      );
    }
    final notifier = ref.read(pickerProvider.notifier);
    final key = s.key;

    String tempText(int c) => formatTemp(c, fahrenheit: fahrenheit);

    return PickerScaffold(
      step: 4,
      title: 'Dilution & temperature',
      subtitle: '${q.developerLabel(s.developer!)} · ISO ${s.ei}',
      footer: DrkButton(
        key: const Key('show-combination'),
        label: 'Show combination →',
        kind: DrkButtonKind.primary,
        size: DrkButtonSize.large,
        onPressed: key == null ? null : () => context.push(comboPath(key)),
      ),
      child: ListView(
        children: [
          SectionLabel('Dilution'),
          const SizedBox(height: 8),
          for (final o in options)
            ListRow(
              key: Key('dil-${o.dilution}'),
              selected: s.dilution == o.dilution,
              boxed: true,
              minHeight: 60,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => notifier.pickDilution(o.dilution, tempC: o.tempC),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.dilution,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${o.count} ${o.count == 1 ? 'time' : 'times'}${o == options.first && options.length > 1 ? ' · typically' : ''}',
                          style: DrkType.sm.copyWith(color: p.mut),
                        ),
                      ],
                    ),
                  ),
                  if (o.typicalTimeS != null)
                    timeText(context, formatTime(o.typicalTimeS!), size: 24),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DrkField(
                  key: const Key('dil-custom'),
                  controller: _custom,
                  hint: options.isEmpty
                      ? 'Dilution, e.g. 1+50 or stock'
                      : 'Another dilution',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: DrkButton(
                  key: const Key('dil-use'),
                  label: 'Use',
                  kind: DrkButtonKind.outline,
                  onPressed: () {
                    final d = normaliseDilution(_custom.text);
                    try {
                      CombinationKey(
                        film: s.film!,
                        developer: s.developer!,
                        dilution: d,
                        ei: s.ei!,
                        tempC: s.tempC,
                      );
                      notifier.pickDilution(d);
                    } on ArgumentError {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use 1+N, 1+A+B, stock or working.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionLabel('Temperature'),
          const SizedBox(height: 10),
          DrkStepper(
            key: const Key('temp-stepper'),
            value: tempText(s.tempC),
            height: 64,
            fontSize: 28,
            onMinus: s.tempC > 10 ? () => notifier.setTemp(s.tempC - 1) : null,
            onPlus: s.tempC < 45 ? () => notifier.setTemp(s.tempC + 1) : null,
          ),
          const SizedBox(height: 10),
          Text(
            'Whole degrees. Where no time is published for your temperature, the combination page shows an estimate.',
            style: DrkType.sm.copyWith(color: p.mut),
          ),
        ],
      ),
    );
  }
}
