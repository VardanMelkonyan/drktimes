import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/combination_key.dart';
import '../../domain/format.dart';
import '../../domain/search.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';

/// HomeSearch.dc.html: one field, mixed film and developer results.
class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<InlineSpan> _highlight(String text, String query, TextStyle base) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [TextSpan(text: text, style: base)];
    final i = text.toLowerCase().indexOf(q);
    if (i < 0) return [TextSpan(text: text, style: base)];
    return [
      TextSpan(text: text.substring(0, i), style: base),
      TextSpan(
        text: text.substring(i, i + q.length),
        style: base.copyWith(
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        ),
      ),
      TextSpan(text: text.substring(i + q.length), style: base),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final index = ref.watch(searchIndexProvider).value;
    final queries = ref.watch(pickerQueriesProvider).value;
    final q = _controller.text;
    final results = (index == null || q.trim().isEmpty)
        ? const <SearchResult>[]
        : index.search(q);
    final films = [
      for (final r in results)
        if (r.item.kind == SearchKind.film) r.item,
    ];
    final devs = [
      for (final r in results)
        if (r.item.kind == SearchKind.developer) r.item,
    ];

    // Combinations the user already has for the top film.
    final mine = <CombinationKey, int>{};
    if (films.isNotEmpty && queries != null) {
      final film = films.first;
      final ref_ = queries.userFilms.any((f) => f.id == film.id)
          ? FilmRef.user(film.id)
          : FilmRef.catalog(film.id);
      for (final r in queries.recipes) {
        if (r.key.film == ref_) mine[r.key] = r.devTimeS;
      }
    }

    final base = DrkType.bd.copyWith(color: p.fg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrkField(
          key: const Key('home-search'),
          controller: _controller,
          hint: 'Search films and developers',
          heavyBorder: q.isNotEmpty,
          prefix: Icon(Icons.search, color: p.mut),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (q.trim().isNotEmpty) ...[
                SectionLabel('Films · ${films.length}'),
                for (final f in films)
                  ListRow(
                    key: Key('result-film-${f.id}'),
                    onTap: () {
                      final isUser = f.userAdded;
                      ref
                          .read(pickerProvider.notifier)
                          .startFrom(
                            isUser ? FilmRef.user(f.id) : FilmRef.catalog(f.id),
                          );
                      context.push('/pick/developer');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(children: _highlight(f.name, q, base)),
                              ),
                              Text(
                                '${f.brand}${f.userAdded ? ' · user-added' : ''}',
                                style: DrkType.sm.copyWith(color: p.mut),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.mut),
                      ],
                    ),
                  ),
                if (mine.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SectionLabel('Your combinations · ${films.first.name}'),
                  for (final e in mine.entries)
                    ListRow(
                      key: Key('mine-${e.key.canonical}'),
                      onTap: () => context.push(comboPath(e.key)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${queries!.developerLabel(e.key.developer)} ${e.key.dilution}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'ISO ${e.key.ei} · ${e.key.tempC} °C',
                                  style: DrkType.sm.copyWith(color: p.mut),
                                ),
                              ],
                            ),
                          ),
                          timeText(context, formatTime(e.value)),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                SectionLabel('Developers · ${devs.length}'),
                for (final d in devs)
                  ListRow(
                    key: Key('result-dev-${d.id}'),
                    onTap: () {
                      ref
                          .read(pickerProvider.notifier)
                          .startWithDeveloper(
                            d.userAdded
                                ? DeveloperRef.user(d.id)
                                : DeveloperRef.catalog(d.id),
                          );
                      context.push('/pick/film');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(children: _highlight(d.name, q, base)),
                              ),
                              Text(
                                d.brand,
                                style: DrkType.sm.copyWith(color: p.mut),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.mut),
                      ],
                    ),
                  ),
              ] else
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.ln2),
                    borderRadius: BorderRadius.circular(DrkSpace.radius),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: DrkType.sm.copyWith(color: p.mut),
                      children: [
                        const TextSpan(text: 'Spelling is forgiving: '),
                        for (final t in ['trix', 'hp5', 'd76', 'r09']) ...[
                          TextSpan(
                            text: t,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.fg,
                            ),
                          ),
                          const TextSpan(text: ', '),
                        ],
                        const TextSpan(
                          text: ' and more all find what you mean.',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
