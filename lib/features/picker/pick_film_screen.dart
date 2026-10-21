import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/user_catalog_repository.dart';
import '../../domain/combination_key.dart';
import '../../domain/search.dart';
import '../common/widgets.dart';
import 'add_entry_sheet.dart';
import 'picker_scaffold.dart';
import 'picker_state.dart';

/// PickFilm.dc.html: step 1 of 4.
class PickFilmScreen extends StatelessWidget {
  const PickFilmScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PickerScaffold(step: 1, title: 'Which film?', child: FilmPicker());
}

/// Search field, every film grouped by brand, and "Add a film". Shared by
/// the picker's first step and the home Search tab.
class FilmPicker extends ConsumerStatefulWidget {
  const FilmPicker({super.key});

  @override
  ConsumerState<FilmPicker> createState() => _FilmPickerState();
}

class _FilmPickerState extends ConsumerState<FilmPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _choose(FilmRef film) {
    ref.read(pickerProvider.notifier).pickFilm(film);
    context.push('/pick/developer');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final catalog = ref.watch(catalogProvider).value;
    final index = ref.watch(searchIndexProvider).value;
    final userFilms =
        ref.watch(pickerQueriesProvider).value?.userFilms ?? const <UserFilm>[];
    final q = _query.text.trim();

    final entries = <_FilmEntry>[];
    if (catalog != null) {
      final results = q.isEmpty || index == null
          ? null
          : {
              for (final r in index.search(q))
                if (r.item.kind == SearchKind.film) r.item.id: r.tier,
            };
      for (final f in catalog.films) {
        if (results == null || results.containsKey(f.id)) {
          entries.add(
            _FilmEntry(
              f.brand,
              f.name,
              f.iso.round(),
              FilmRef.catalog(f.id),
              false,
            ),
          );
        }
      }
      for (final f in userFilms) {
        if (f.matchedCatalogId != null) continue;
        if (results == null || results.containsKey(f.id)) {
          entries.add(
            _FilmEntry(f.brand, f.name, f.boxIso, FilmRef.user(f.id), true),
          );
        }
      }
      if (results != null) {
        entries.sort(
          (a, b) => (results[a.ref.id] ?? 9).compareTo(results[b.ref.id] ?? 9),
        );
      } else {
        entries.sort((a, b) {
          final c = a.brand.compareTo(b.brand);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
      }
    }

    final children = <Widget>[];
    String? lastBrand;
    for (final e in entries) {
      if (q.isEmpty && e.brand != lastBrand) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SectionLabel(e.brand),
          ),
        );
        lastBrand = e.brand;
      }
      children.add(
        ListRow(
          key: Key('film-${e.ref.id}'),
          minHeight: 48,
          padding: const EdgeInsets.symmetric(vertical: 10),
          onTap: () => _choose(e.ref),
          child: Row(
            children: [
              Expanded(
                child: Text(q.isEmpty ? e.name : '${e.brand} ${e.name}'),
              ),
              if (e.user) ...[
                const DrkChip('user-added', small: true, muted: true),
                const SizedBox(width: 8),
              ],
              Text('ISO ${e.iso}', style: DrkType.sm.copyWith(color: p.mut)),
            ],
          ),
        ),
      );
    }
    if (entries.isEmpty && catalog != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            'No film matches "$q".',
            style: DrkType.bd.copyWith(color: p.mut),
          ),
        ),
      );
    }

    return Column(
      children: [
        DrkField(
          key: const Key('film-search'),
          controller: _query,
          hint: 'Search films',
          prefix: Icon(Icons.search, color: p.mut),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DrkSpace.s12),
        Expanded(child: ListView(children: children)),
        const SizedBox(height: DrkSpace.s12),
        DrkButton(
          key: const Key('add-film'),
          label: 'Add a film not listed',
          size: DrkButtonSize.large,
          icon: Icons.add,
          onPressed: () async {
            final ref_ = await showAddEntrySheet<FilmRef>(context, film: true);
            if (ref_ != null && mounted) _choose(ref_);
          },
        ),
      ],
    );
  }
}

class _FilmEntry {
  const _FilmEntry(this.brand, this.name, this.iso, this.ref, this.user);

  final String brand, name;
  final int iso;
  final FilmRef ref;
  final bool user;
}
