import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/dataset/picker_queries.dart';
import '../../domain/format.dart';
import '../common/widgets.dart';
import 'picker_scaffold.dart';
import 'picker_state.dart';

/// PickISO.dc.html: step 3 of 4. Box speed first, then each EI with data
/// labelled push / pull, then Custom (FR-008).
class PickIsoScreen extends ConsumerStatefulWidget {
  const PickIsoScreen({super.key});

  @override
  ConsumerState<PickIsoScreen> createState() => _PickIsoScreenState();
}

class _PickIsoScreenState extends ConsumerState<PickIsoScreen> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _choose(int ei) {
    ref.read(pickerProvider.notifier).pickEi(ei);
    context.push('/pick/dilution');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = ref.watch(pickerProvider);
    final q = ref.watch(pickerQueriesProvider).value;
    if (s.film == null || s.developer == null || q == null) {
      return const PickerScaffold(
        step: 3,
        title: 'Shot at which ISO?',
        child: SizedBox(),
      );
    }
    final box = q.boxIso(s.film!);
    final options = q.eisFor(s.film!, s.developer!);
    final boxInt = box?.round();
    final rest = [
      for (final o in options)
        if (o.ei != boxInt) o,
    ]..sort((a, b) => a.ei.compareTo(b.ei));
    final others = [
      for (final o in rest)
        if (o.ei > (boxInt ?? 0)) o,
      for (final o in rest.reversed)
        if (o.ei < (boxInt ?? 0)) o,
    ];

    String count(int n) =>
        n == 0 ? 'no time' : '$n ${n == 1 ? 'time' : 'times'}';

    return PickerScaffold(
      step: 3,
      title: 'Shot at which ISO?',
      subtitle: _short(q, s),
      child: ListView(
        children: [
          if (boxInt != null) ...[
            SectionLabel('Box speed'),
            const SizedBox(height: 4),
            ListRow(
              key: const Key('iso-box'),
              selected: true,
              minHeight: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _choose(boxInt),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ISO $boxInt',
                          style: DrkType.ti.copyWith(color: p.fg),
                        ),
                        Text(
                          'box speed',
                          style: DrkType.sm.copyWith(color: p.mut),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    count(
                      options
                          .firstWhere(
                            (o) => o.ei == boxInt,
                            orElse: () => EiOption(boxInt, 0),
                          )
                          .count,
                    ),
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (others.isNotEmpty) SectionLabel('Push / pull'),
          for (final o in others)
            ListRow(
              key: Key('iso-${o.ei}'),
              minHeight: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onTap: () => _choose(o.ei),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'ISO ${o.ei}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (box != null && pushPullLabel(o.ei, box) != null)
                            TextSpan(
                              text: ' · ${pushPullLabel(o.ei, box)}',
                              style: TextStyle(color: p.mut),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    count(o.count),
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SectionLabel('Custom'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DrkField(
                  key: const Key('iso-custom'),
                  controller: _custom,
                  hint: 'ISO, e.g. 640',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: DrkButton(
                  key: const Key('iso-use'),
                  label: 'Use',
                  kind: DrkButtonKind.outline,
                  onPressed: () {
                    final v = int.tryParse(_custom.text.trim());
                    if (v != null && v >= 1 && v <= 25600) _choose(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _short(PickerQueries q, PickerState s) {
    final film = s.film!;
    final fl =
        q.catalog.film(film.id)?.name ??
        q.userFilms
            .where((f) => f.id == film.id)
            .map((f) => f.name)
            .firstOrNull ??
        film.id;
    return '$fl · ${q.developerLabel(s.developer!)}';
  }
}
