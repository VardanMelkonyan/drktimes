import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/clock.dart';
import '../../domain/combination_key.dart';
import '../../domain/exchange/document.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';
import '../../domain/user_entries.dart';
import '../db/database.dart';
import 'import_service.dart';
import 'settings_repository.dart';

/// Builds exchange documents from the local database: one recipe to share
/// (FR-053) or a full backup (FR-061, T109).
class BackupService {
  BackupService(this._db, this._clock, {this.appVersion});

  final AppDatabase _db;
  final Clock _clock;
  final String? appVersion;

  /// Only the user's own recipes can be shared.
  Future<ExchangeDocument> recipeDocument(String recipeId) async {
    final row = await (_db.select(
      _db.recipes,
    )..where((t) => t.id.equals(recipeId))).getSingleOrNull();
    if (row == null) throw ArgumentError.value(recipeId, 'recipeId', 'unknown');
    final recipe = recipeFromRow(row);
    if (!recipe.isOwn) {
      throw StateError('only your own recipes can be shared');
    }
    final notes = await _notes(recipeId);
    return ExchangeDocument(
      kind: ExchangeKind.recipe,
      exportedAt: _clock.now(),
      appVersion: appVersion,
      userFilms: await _userFilmsFor([recipe.key]),
      userDevelopers: await _userDevelopersFor([recipe.key]),
      recipes: [ExchangeRecipe(recipe, notes)],
    );
  }

  Future<ExchangeDocument> backupDocument() async {
    final recipes = <ExchangeRecipe>[];
    for (final row in await _db.select(_db.recipes).get()) {
      recipes.add(ExchangeRecipe(recipeFromRow(row), await _notes(row.id)));
    }
    final films = await _db.select(_db.userFilms).get();
    final devs = await _db.select(_db.userDevelopers).get();
    final favourites = await _db.select(_db.favourites).get();
    final sessions = await (_db.select(
      _db.sessions,
    )..where((t) => t.status.isIn(['completed', 'aborted']))).get();
    final processes = await _db.select(_db.processes).get();
    final settings = SettingsRepository(_db);
    return ExchangeDocument(
      kind: ExchangeKind.backup,
      exportedAt: _clock.now(),
      appVersion: appVersion,
      userFilms: [
        for (final f in films)
          UserFilm(
            id: f.id,
            brand: f.brand,
            name: f.name,
            boxIso: f.boxIso,
            createdAt: f.createdAt,
          ),
      ],
      userDevelopers: [
        for (final d in devs)
          UserDeveloper(
            id: d.id,
            brand: d.brand,
            name: d.name,
            createdAt: d.createdAt,
          ),
      ],
      recipes: recipes,
      favourites: [
        for (final f in favourites)
          CombinationKey.fromJson(
            jsonDecode(f.keyJson) as Map<String, dynamic>,
          ),
      ],
      // Manually typed sessions have no combination and are not kept.
      sessions: [
        for (final s in sessions)
          if (s.keyJson != null) _session(s),
      ],
      processes: [
        for (final p in processes)
          if (p.id != Process.defaultId)
            Process.fromJson(jsonDecode(p.json) as Map<String, dynamic>),
      ],
      settings: settings.toJson(await settings.get()),
    );
  }

  ExchangeSession _session(Session s) => ExchangeSession(
    id: s.id,
    tankLabel: s.tankLabel,
    key: CombinationKey.fromJson(
      jsonDecode(s.keyJson!) as Map<String, dynamic>,
    ),
    timeSource: Map<String, dynamic>.from(jsonDecode(s.timeSourceJson) as Map),
    devTimeS: s.devTimeS,
    format: s.format,
    status: s.status,
    startedAt: s.startedAt,
    abortedAtStep: s.abortedAtStep,
    finishedAt: s.finishedAt,
  );

  Future<List<Note>> _notes(String recipeId) async => [
    for (final n
        in await (_db.select(_db.notes)
              ..where((t) => t.recipeId.equals(recipeId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get())
      Note(
        id: n.id,
        recipeId: n.recipeId,
        authorName: n.authorName,
        createdAt: n.createdAt,
        text: n.text_,
      ),
  ];

  Future<List<UserFilm>> _userFilmsFor(List<CombinationKey> keys) async {
    final ids = {
      for (final k in keys)
        if (k.film.kind == RefKind.user) k.film.id,
    };
    if (ids.isEmpty) return const [];
    return [
      for (final f in await (_db.select(
        _db.userFilms,
      )..where((t) => t.id.isIn(ids))).get())
        UserFilm(
          id: f.id,
          brand: f.brand,
          name: f.name,
          boxIso: f.boxIso,
          createdAt: f.createdAt,
        ),
    ];
  }

  Future<List<UserDeveloper>> _userDevelopersFor(
    List<CombinationKey> keys,
  ) async {
    final ids = {
      for (final k in keys)
        if (k.developer.kind == RefKind.user) k.developer.id,
    };
    if (ids.isEmpty) return const [];
    return [
      for (final d in await (_db.select(
        _db.userDevelopers,
      )..where((t) => t.id.isIn(ids))).get())
        UserDeveloper(
          id: d.id,
          brand: d.brand,
          name: d.name,
          createdAt: d.createdAt,
        ),
    ];
  }
}
