import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/dataset/picker_queries.dart';
import '../../domain/combination_key.dart';
import '../../domain/format.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';
import 'empty_states.dart';

final favouritesProvider = FutureProvider<List<CombinationKey>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(favouritesRepositoryProvider).all();
});

/// "Kodak Tri-X 400" for a key's film.
String filmTitle(PickerQueries q, CombinationKey k) {
  if (k.film.kind == RefKind.catalog) {
    final f = q.catalog.film(k.film.id);
    return f == null ? k.film.id : '${f.brand} ${f.name}';
  }
  for (final f in q.userFilms) {
    if (f.id == k.film.id) return '${f.brand} ${f.name}';
  }
  return k.film.id;
}

/// "Rodinal 1+50 · ISO 400 push +1 · 20 °C"
String keyLine(PickerQueries q, CombinationKey k, {bool fahrenheit = false}) {
  final box = q.boxIso(k.film);
  final pp = box == null ? null : pushPullLabel(k.ei, box);
  return '${q.developerLabel(k.developer)} ${k.dilution} · ISO ${k.ei}'
      '${pp == null ? '' : ' $pp'} · ${formatTemp(k.tempC, fahrenheit: fahrenheit)}';
}

/// HomeFavourites.dc.html: starred combinations, one tap from Start.
class FavouritesTab extends ConsumerWidget {
  const FavouritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favouritesProvider).value;
    final q = ref.watch(pickerQueriesProvider).value;
    if (favs == null || q == null) return const SizedBox();
    if (favs.isEmpty) {
      return const NoFavourites(key: Key('empty-favourites'));
    }
    return ListView(
      children: [
        SectionLabel('${favs.length} starred', bottom: 2),
        for (final (i, k) in favs.indexed)
          _FavouriteRow(index: i + 1, comboKey: k, queries: q),
      ],
    );
  }
}

class _FavouriteRow extends ConsumerWidget {
  const _FavouriteRow({
    required this.index,
    required this.comboKey,
    required this.queries,
  });

  final int index;
  final CombinationKey comboKey;
  final PickerQueries queries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final time = ref
        .watch(combinationViewProvider(comboKey))
        .value
        ?.preselection
        ?.timeS;
    return ListRow(
      key: Key('fav-${comboKey.canonical}'),
      onTap: () => context.push(comboPath(comboKey)),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.mut,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filmTitle(queries, comboKey),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  keyLine(queries, comboKey),
                  style: DrkType.sm.copyWith(color: p.mut),
                ),
              ],
            ),
          ),
          timeText(context, time == null ? '--:--' : formatTime(time)),
        ],
      ),
    );
  }
}
