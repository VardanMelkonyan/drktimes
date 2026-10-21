import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/clock.dart';
import '../../domain/combination_key.dart';
import '../../domain/exchange/document.dart';
import '../../domain/exchange/merge.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';
import '../../domain/user_entries.dart';
import '../dataset/catalog.dart';
import '../db/database.dart';
import 'settings_repository.dart';

class ImportResult {
  const ImportResult({
    required this.added,
    required this.updated,
    required this.upToDate,
    required this.plan,
  });

  final int added, updated, upToDate;
  final MergePlan plan;

  bool get nothingChanged => added == 0 && updated == 0;
}

/// Applies an exchange document to the local database (T098). The plan is
/// pure (domain/exchange/merge.dart); this runs it in one transaction.
class ImportService {
  ImportService(this._db, this._clock, this._catalog);

  final AppDatabase _db;
  final Clock _clock;
  final Catalog _catalog;

  Future<LocalSnapshot> snapshot() async {
    final recipeRows = await _db.select(_db.recipes).get();
    final noteRows = await _db.select(_db.notes).get();
    final noteIds = <String, Set<String>>{};
    for (final n in noteRows) {
      (noteIds[n.recipeId] ??= {}).add(n.id);
    }
    final films = await _db.select(_db.userFilms).get();
    final devs = await _db.select(_db.userDevelopers).get();
    return LocalSnapshot(
      recipes: {for (final r in recipeRows) r.id: recipeFromRow(r)},
      noteIds: noteIds,
      userFilms: [
        for (final f in films)
          UserFilm(
            id: f.id,
            brand: f.brand,
            name: f.name,
            boxIso: f.boxIso,
            createdAt: f.createdAt,
            matchedCatalogId: f.matchedCatalogId,
          ),
      ],
      userDevelopers: [
        for (final d in devs)
          UserDeveloper(
            id: d.id,
            brand: d.brand,
            name: d.name,
            createdAt: d.createdAt,
            matchedCatalogId: d.matchedCatalogId,
          ),
      ],
      catalogFilms: [
        for (final f in _catalog.films) CatalogEntry(f.id, f.brand, f.name),
      ],
      catalogDevelopers: [
        for (final d in _catalog.developers)
          CatalogEntry(d.id, d.brand, d.name),
      ],
      sessionIds: {for (final s in await _db.select(_db.sessions).get()) s.id},
      processIds: {for (final p in await _db.select(_db.processes).get()) p.id},
      favouriteKeys: {
        for (final f in await _db.select(_db.favourites).get()) f.keyCanonical,
      },
    );
  }

  /// The user-added entries in [doc] that look like ones we already know.
  Future<List<MatchOffer>> offersFor(ExchangeDocument doc) async =>
      findMatchOffers(doc, await snapshot());

  Future<ImportResult> import(
    ExchangeDocument doc, {
    Set<String> accepted = const {},
    bool restoreSettings = false,
  }) async {
    final plan = planImport(
      doc,
      await snapshot(),
      accepted: accepted,
      restoreSettings: restoreSettings,
    );
    await apply(plan);
    return ImportResult(
      added: plan.inserts.length,
      updated: plan.updates.length,
      upToDate: plan.upToDate.length,
      plan: plan,
    );
  }

  Future<void> apply(MergePlan plan) => _db.transaction(() async {
    final now = _clock.now();
    for (final f in plan.userFilms) {
      await _db
          .into(_db.userFilms)
          .insertOnConflictUpdate(
            UserFilmsCompanion.insert(
              id: f.id,
              brand: f.brand,
              name: f.name,
              boxIso: f.boxIso,
              createdAt: now,
            ),
          );
    }
    for (final d in plan.userDevelopers) {
      await _db
          .into(_db.userDevelopers)
          .insertOnConflictUpdate(
            UserDevelopersCompanion.insert(
              id: d.id,
              brand: d.brand,
              name: d.name,
              createdAt: now,
            ),
          );
    }
    for (final p in plan.processes) {
      await _db
          .into(_db.processes)
          .insert(
            ProcessesCompanion.insert(id: p.id, json: jsonEncode(p.toJson())),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final er in plan.inserts) {
      final r = er.recipe;
      await _db
          .into(_db.recipes)
          .insert(
            _recipeCompanion(
              r.ownership == Ownership.received
                  ? r.copyWith(importedAt: r.importedAt ?? now)
                  : r,
            ),
          );
      for (final n in er.notes) {
        await _insertNote(n, r.id);
      }
    }
    for (final u in plan.updates) {
      final r = u.incoming;
      await (_db.update(_db.recipes)..where((t) => t.id.equals(r.id))).write(
        RecipesCompanion(
          version: Value(r.version),
          updatedAt: Value(r.updatedAt),
          authorName: Value(r.authorName),
          originJson: Value(jsonEncode(r.origin.toJson())),
          keyCanonical: Value(r.key.canonical),
          keyJson: Value(jsonEncode(r.key.toJson())),
          devTimeS: Value(r.devTimeS),
          devAgitationJson: Value(jsonEncode(r.devAgitation.toJson())),
          processJson: Value(
            r.process == null ? null : jsonEncode(r.process!.toJson()),
          ),
        ),
      );
      for (final n in u.newNotes) {
        await _insertNote(n, r.id);
      }
    }
    for (final k in plan.favourites) {
      await _db
          .into(_db.favourites)
          .insert(
            FavouritesCompanion.insert(
              keyCanonical: k.canonical,
              keyJson: jsonEncode(k.toJson()),
              createdAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final s in plan.sessions) {
      await _db
          .into(_db.sessions)
          .insert(_sessionCompanion(s), mode: InsertMode.insertOrIgnore);
    }
    final settings = plan.settings;
    if (settings != null) {
      await SettingsRepository(_db).restore(settings);
    }
  });

  Future<void> _insertNote(Note n, String recipeId) => _db
      .into(_db.notes)
      .insert(
        NotesCompanion.insert(
          id: n.id,
          recipeId: recipeId,
          authorName: n.authorName,
          createdAt: n.createdAt,
          text_: n.text,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  static RecipesCompanion _recipeCompanion(Recipe r) => RecipesCompanion.insert(
    id: r.id,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    authorName: r.authorName,
    ownership: r.ownership.name,
    originJson: jsonEncode(r.origin.toJson()),
    importedAt: Value(r.importedAt),
    keyCanonical: r.key.canonical,
    keyJson: jsonEncode(r.key.toJson()),
    devTimeS: r.devTimeS,
    devAgitationJson: jsonEncode(r.devAgitation.toJson()),
    processJson: Value(
      r.process == null ? null : jsonEncode(r.process!.toJson()),
    ),
    hidden: Value(r.hidden),
  );

  static SessionsCompanion _sessionCompanion(ExchangeSession s) {
    final volume = s.format == '120' ? 500 : 300;
    return SessionsCompanion.insert(
      id: s.id,
      tankSlot: 1,
      tankLabel: s.tankLabel,
      keyCanonical: Value(s.key.canonical),
      keyJson: Value(jsonEncode(s.key.toJson())),
      timeSourceJson: jsonEncode(s.timeSource),
      devTimeS: s.devTimeS,
      format: s.format,
      volumeMl: volume,
      processSnapshotJson: jsonEncode(Process.defaults().toJson()),
      inversionPaceS: 2.0,
      status: s.status,
      abortedAtStep: Value(s.abortedAtStep),
      startedAt: s.startedAt,
      finishedAt: Value(s.finishedAt),
      stepRunsJson: jsonEncode(const <Object>[]),
    );
  }
}

/// A recipe row as a domain [Recipe].
Recipe recipeFromRow(RecipeRow row) => Recipe(
  id: row.id,
  version: row.version,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
  authorName: row.authorName,
  ownership: Ownership.values.byName(row.ownership),
  origin: RecipeOrigin.fromJson(
    jsonDecode(row.originJson) as Map<String, dynamic>,
  ),
  key: CombinationKey.fromJson(jsonDecode(row.keyJson) as Map<String, dynamic>),
  devTimeS: row.devTimeS,
  devAgitation: AgitationPattern.fromJson(
    jsonDecode(row.devAgitationJson) as Map<String, dynamic>,
  ),
  process: row.processJson == null
      ? null
      : Process.fromJson(jsonDecode(row.processJson!) as Map<String, dynamic>),
  hidden: row.hidden,
  importedAt: row.importedAt,
);
