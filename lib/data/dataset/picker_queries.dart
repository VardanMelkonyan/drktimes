import '../../domain/combination_key.dart';
import '../../domain/recipe.dart';
import '../../domain/summary.dart';
import '../repositories/user_catalog_repository.dart';
import 'catalog.dart';

class DeveloperOption {
  const DeveloperOption({
    required this.ref,
    required this.label,
    required this.count,
    required this.dilutions,
    this.userAdded = false,
  });

  final DeveloperRef ref;
  final String label;

  /// Datasheet rows plus recipes for the chosen film.
  final int count;
  final List<String> dilutions;
  final bool userAdded;
}

class EiOption {
  const EiOption(this.ei, this.count);

  final int ei;
  final int count;
}

class DilutionOption {
  const DilutionOption({
    required this.dilution,
    required this.count,
    required this.typicalTimeS,
    required this.tempC,
  });

  final String dilution;
  final int count;

  /// Median of the known times, or null with no data.
  final int? typicalTimeS;

  /// The temperature most of its rows use.
  final int tempC;
}

/// Questions the picker asks of the catalogue, user entries and recipes.
class PickerQueries {
  PickerQueries({
    required this.catalog,
    required this.recipes,
    required this.userFilms,
    required this.userDevelopers,
  });

  final Catalog catalog;
  final List<Recipe> recipes;
  final List<UserFilm> userFilms;
  final List<UserDeveloper> userDevelopers;

  double? boxIso(FilmRef film) {
    if (film.kind == RefKind.catalog) {
      return catalog.film(film.id)?.iso.toDouble();
    }
    for (final f in userFilms) {
      if (f.id == film.id) return f.boxIso.toDouble();
    }
    return null;
  }

  Iterable<Recipe> _recipesFor(FilmRef film, [DeveloperRef? dev]) =>
      recipes.where(
        (r) => r.key.film == film && (dev == null || r.key.developer == dev),
      );

  String developerLabel(DeveloperRef ref) {
    if (ref.kind == RefKind.catalog) {
      final d = catalog.developer(ref.id);
      return d == null
          ? ref.id
          : '${d.brand} ${d.name}'.replaceFirst(RegExp(r'^Various '), '');
    }
    for (final d in userDevelopers) {
      if (d.id == ref.id) return '${d.brand} ${d.name}';
    }
    return ref.id;
  }

  /// Developers that have times (datasheet or recipes) for [film], most times
  /// first, then every other developer (FR-007).
  ({List<DeveloperOption> withTimes, List<DeveloperOption> others})
  developersFor(FilmRef film) {
    final counts = <DeveloperRef, int>{};
    final dilutions = <DeveloperRef, Set<String>>{};
    if (film.kind == RefKind.catalog) {
      for (final d in catalog.developers) {
        final rows = catalog.timesFor(film.id, d.id);
        if (rows.isEmpty) continue;
        final ref = DeveloperRef.catalog(d.id);
        counts[ref] = rows.length;
        dilutions[ref] = {for (final r in rows) r.dilution};
      }
    }
    for (final r in _recipesFor(film)) {
      counts[r.key.developer] = (counts[r.key.developer] ?? 0) + 1;
      (dilutions[r.key.developer] ??= {}).add(r.key.dilution);
    }

    DeveloperOption option(
      DeveloperRef ref, {
      int count = 0,
      bool user = false,
    }) => DeveloperOption(
      ref: ref,
      label: developerLabel(ref),
      count: count,
      dilutions: (dilutions[ref] ?? {}).toList()..sort(),
      userAdded: user,
    );

    final withTimes =
        [for (final e in counts.entries) option(e.key, count: e.value)]
          ..sort((a, b) {
            final c = b.count.compareTo(a.count);
            return c != 0 ? c : a.label.compareTo(b.label);
          });
    final others = [
      for (final d in catalog.developers)
        if (!counts.containsKey(DeveloperRef.catalog(d.id)))
          option(DeveloperRef.catalog(d.id)),
      for (final d in userDevelopers)
        if (d.matchedCatalogId == null &&
            !counts.containsKey(DeveloperRef.user(d.id)))
          option(DeveloperRef.user(d.id), user: true),
    ]..sort((a, b) => a.label.compareTo(b.label));
    return (withTimes: withTimes, others: others);
  }

  /// Exposure indexes that have data, box speed first.
  List<EiOption> eisFor(FilmRef film, DeveloperRef dev) {
    final counts = <int, int>{};
    if (film.kind == RefKind.catalog && dev.kind == RefKind.catalog) {
      for (final t in catalog.timesFor(film.id, dev.id)) {
        counts[t.ei] = (counts[t.ei] ?? 0) + 1;
      }
    }
    for (final r in _recipesFor(film, dev)) {
      counts[r.key.ei] = (counts[r.key.ei] ?? 0) + 1;
    }
    final box = boxIso(film)?.round();
    final eis = counts.keys.toList()
      ..sort((a, b) {
        if (a == box) return -1;
        if (b == box) return 1;
        return a.compareTo(b);
      });
    return [
      if (box != null && !counts.containsKey(box)) EiOption(box, 0),
      for (final e in eis) EiOption(e, counts[e]!),
    ];
  }

  /// Dilutions with data for this film, developer and EI, most rows first.
  List<DilutionOption> dilutionsFor(FilmRef film, DeveloperRef dev, int ei) {
    final times = <String, List<int>>{};
    final temps = <String, Map<int, int>>{};
    void add(String dil, int timeS, int tempC) {
      times.putIfAbsent(dil, () => []).add(timeS);
      final t = temps.putIfAbsent(dil, () => {});
      t[tempC] = (t[tempC] ?? 0) + 1;
    }

    if (film.kind == RefKind.catalog && dev.kind == RefKind.catalog) {
      for (final t in catalog.timesFor(film.id, dev.id, ei: ei)) {
        if (t.isPrimary) add(t.dilution, t.defaultRunTimeS, t.tempC);
      }
    }
    for (final r in _recipesFor(film, dev)) {
      if (r.key.ei == ei) add(r.key.dilution, r.devTimeS, r.key.tempC);
    }
    final out =
        [
          for (final e in times.entries)
            DilutionOption(
              dilution: e.key,
              count: e.value.length,
              typicalTimeS: e.value.length >= 2
                  ? summarise(e.value)!.medianS
                  : e.value.first,
              tempC:
                  (temps[e.key]!.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .first
                      .key,
            ),
        ]..sort((a, b) {
          final c = b.count.compareTo(a.count);
          return c != 0 ? c : a.dilution.compareTo(b.dilution);
        });
    return out;
  }
}
