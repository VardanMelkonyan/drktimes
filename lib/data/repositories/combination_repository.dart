import '../../domain/combination_key.dart';
import '../../domain/preselect.dart';
import '../../domain/recipe.dart';
import '../../domain/summary.dart';
import '../dataset/catalog.dart';
import '../dataset/datasheet_time.dart';
import 'note_repository.dart';
import 'recipe_repository.dart';
import 'session_repository.dart';
import 'user_catalog_repository.dart';

enum TimeRowKind { datasheet, own, received }

/// One row on the combination page. Datasheet, own and received times all
/// render as this same row (SC-013); only [kind] changes the label.
class TimeRow {
  const TimeRow.datasheet(DatasheetTime this.datasheet)
    : kind = TimeRowKind.datasheet,
      recipe = null;

  TimeRow.recipe(Recipe this.recipe)
    : kind = recipe.isOwn ? TimeRowKind.own : TimeRowKind.received,
      datasheet = null;

  final TimeRowKind kind;
  final DatasheetTime? datasheet;
  final Recipe? recipe;

  int get timeS => datasheet?.defaultRunTimeS ?? recipe!.devTimeS;
  int? get timeMaxS => datasheet?.timeMaxS;
  bool get isRange => timeMaxS != null;

  /// The time_source this row stands for, as stored on a session.
  Map<String, dynamic> get timeSource => datasheet != null
      ? datasheetSource(datasheet!)
      : {
          'kind': 'recipe',
          'recipe_id': recipe!.id,
          'recipe_version': recipe!.version,
        };
}

class CombinationView {
  const CombinationView({
    required this.key,
    required this.filmLabel,
    required this.developerLabel,
    required this.rows,
    required this.summary,
    required this.preselection,
    required this.notes,
    required this.filmIsRebrand,
    this.note = '',
  });

  final CombinationKey key;
  final String filmLabel, developerLabel;

  /// Datasheet rows first, then own, then received.
  final List<TimeRow> rows;
  final TimeSummary? summary;
  final Preselection? preselection;
  final List<Note> notes;
  final bool filmIsRebrand;

  /// "Tri-X 400 · Rodinal": a short name for a tank card.
  final String note;

  bool get isEmpty => rows.isEmpty;

  TimeRow? get preselectedRow {
    final p = preselection;
    if (p == null) return null;
    for (final r in rows) {
      if (r.timeSource['kind'] == p.timeSource['kind'] &&
          (r.timeSource['source_id'] ?? r.timeSource['recipe_id']) ==
              (p.timeSource['source_id'] ?? p.timeSource['recipe_id']) &&
          r.timeSource['page'] == p.timeSource['page']) {
        return r;
      }
    }
    return null;
  }
}

/// Assembles a [CombinationView] for a key (T066).
class CombinationRepository {
  CombinationRepository({
    required this.catalog,
    required this.recipes,
    required this.notes,
    required this.sessions,
    required this.userCatalog,
  });

  final Catalog catalog;
  final RecipeRepository recipes;
  final NoteRepository notes;
  final SessionRepository sessions;
  final UserCatalogRepository userCatalog;

  Future<CombinationView> load(CombinationKey key) async {
    final film = key.film;
    final dev = key.developer;

    final datasheet =
        (film.kind == RefKind.catalog && dev.kind == RefKind.catalog)
        ? catalog.timesFor(
            film.id,
            dev.id,
            dilution: key.dilution,
            ei: key.ei,
            tempC: key.tempC,
          )
        : const <DatasheetTime>[];
    // Newest source first, primary rows ahead of the rest.
    final ordered = [...datasheet]
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return 0;
      });

    final all = await recipes.forKey(key.canonical);
    final own = [
      for (final r in all)
        if (r.isOwn) r,
    ];
    final received = [
      for (final r in all)
        if (!r.isOwn) r,
    ];

    final rows = <TimeRow>[
      for (final t in ordered) TimeRow.datasheet(t),
      for (final r in own) TimeRow.recipe(r),
      for (final r in received) TimeRow.recipe(r),
    ];

    final latest = await sessions.latestFor(key.canonical);
    final source = latest?.meta.timeSource;
    final pre = preselect(
      latestSessionSource: (source == null || source['kind'] == 'manual')
          ? null
          : source,
      datasheet: datasheet,
      recipes: [
        for (final r in all)
          RecipeCandidate(
            id: r.id,
            own: r.isOwn,
            timeS: r.devTimeS,
            version: r.version,
            updatedAt: r.updatedAt,
            importedAt: r.importedAt,
            hidden: r.hidden,
          ),
      ],
    );

    final summary = summarise([
      for (final t in datasheet)
        if (t.isPrimary) t.defaultRunTimeS,
      for (final r in all) r.devTimeS,
    ]);

    return CombinationView(
      key: key,
      filmLabel: await _filmLabel(film),
      developerLabel: await _developerLabel(dev),
      rows: rows,
      summary: summary,
      preselection: pre,
      notes: await notes.forRecipes([for (final r in all) r.id]),
      note: '${await _filmName(film)} · ${await _developerName(dev)}',
      filmIsRebrand:
          film.kind == RefKind.catalog &&
          catalog.film(film.id)?.rebrandOf != null,
    );
  }

  Future<String> _filmName(FilmRef ref) async {
    if (ref.kind == RefKind.catalog) {
      return catalog.film(ref.id)?.name ?? ref.id;
    }
    for (final f in await userCatalog.films()) {
      if (f.id == ref.id) return f.name;
    }
    return ref.id;
  }

  Future<String> _developerName(DeveloperRef ref) async {
    if (ref.kind == RefKind.catalog) {
      return catalog.developer(ref.id)?.name ?? ref.id;
    }
    for (final d in await userCatalog.developers()) {
      if (d.id == ref.id) return d.name;
    }
    return ref.id;
  }

  Future<String> _filmLabel(FilmRef ref) async {
    if (ref.kind == RefKind.catalog) {
      final f = catalog.film(ref.id);
      return f == null ? ref.id : '${f.brand} ${f.name}';
    }
    for (final f in await userCatalog.films()) {
      if (f.id == ref.id) return '${f.brand} ${f.name}';
    }
    return ref.id;
  }

  Future<String> _developerLabel(DeveloperRef ref) async {
    if (ref.kind == RefKind.catalog) {
      final d = catalog.developer(ref.id);
      return d == null ? ref.id : '${d.brand} ${d.name}';
    }
    for (final d in await userCatalog.developers()) {
      if (d.id == ref.id) return '${d.brand} ${d.name}';
    }
    return ref.id;
  }
}
