import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/dataset/picker_queries.dart';
import '../../domain/combination_key.dart';
import '../common/widgets.dart';
import 'add_entry_sheet.dart';
import 'picker_scaffold.dart';
import 'picker_state.dart';

/// PickDeveloper.dc.html: step 2 of 4. Developers with times for this film
/// first (FR-007).
class PickDeveloperScreen extends ConsumerWidget {
  const PickDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final film = ref.watch(pickerProvider).film;
    final q = ref.watch(pickerQueriesProvider).value;
    if (film == null || q == null) {
      return const PickerScaffold(
        step: 2,
        title: 'Which developer?',
        child: SizedBox(),
      );
    }
    final filmLabel = _filmLabel(q, film);
    final r = q.developersFor(film);

    void choose(DeveloperRef d) {
      ref.read(pickerProvider.notifier).pickDeveloper(d);
      context.push('/pick/iso');
    }

    Widget option(DeveloperOption o, {required bool muted}) => ListRow(
      key: Key('dev-${o.ref.id}'),
      minHeight: muted ? 52 : 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      onTap: () => choose(o.ref),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.label,
                  style: TextStyle(
                    fontWeight: muted ? FontWeight.w400 : FontWeight.w700,
                    color: muted ? p.mut : p.fg,
                  ),
                ),
                if (!muted && o.dilutions.isNotEmpty)
                  Text(
                    o.dilutions.join(' · '),
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
              ],
            ),
          ),
          if (o.userAdded) ...[
            const DrkChip('user-added', small: true, muted: true),
            const SizedBox(width: 8),
          ],
          Text(
            muted
                ? 'add your own →'
                : '${o.count} ${o.count == 1 ? 'time' : 'times'}',
            style: DrkType.sm.copyWith(color: p.mut),
          ),
        ],
      ),
    );

    return PickerScaffold(
      step: 2,
      title: 'Which developer?',
      subtitle: filmLabel,
      footer: DrkButton(
        key: const Key('add-developer'),
        label: 'Add a developer',
        size: DrkButtonSize.large,
        icon: Icons.add,
        onPressed: () async {
          final d = await showAddEntrySheet<DeveloperRef>(context, film: false);
          if (d != null && context.mounted) choose(d);
        },
      ),
      child: ListView(
        children: [
          if (r.withTimes.isNotEmpty) ...[
            SectionLabel('Has times for this film · ${r.withTimes.length}'),
            for (final o in r.withTimes) option(o, muted: false),
            const SizedBox(height: 16),
          ],
          SectionLabel('No published time'),
          for (final o in r.others) option(o, muted: true),
        ],
      ),
    );
  }
}

String _filmLabel(PickerQueries q, FilmRef film) {
  if (film.kind == RefKind.catalog) {
    final f = q.catalog.film(film.id);
    return f == null ? film.id : '${f.brand} ${f.name}';
  }
  for (final f in q.userFilms) {
    if (f.id == film.id) return '${f.brand} ${f.name}';
  }
  return film.id;
}
