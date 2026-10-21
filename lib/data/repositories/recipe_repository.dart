import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/clock.dart';
import '../../domain/combination_key.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';
import '../db/database.dart';

class RecipeRepository {
  RecipeRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? (() => const Uuid().v4());

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  static void _checkTime(int s) {
    if (s < minDevTimeS || s > maxDevTimeS) {
      throw ArgumentError.value(
        s,
        'devTimeS',
        'must be $minDevTimeS–$maxDevTimeS s',
      );
    }
  }

  Future<Recipe> create({
    required CombinationKey key,
    required int devTimeS,
    required AgitationPattern devAgitation,
    required RecipeOrigin origin,
    required String authorName,
    Process? process,
  }) async {
    _checkTime(devTimeS);
    final now = _clock.now();
    final r = Recipe(
      id: _newId(),
      version: 1,
      createdAt: now,
      updatedAt: now,
      authorName: authorName,
      ownership: Ownership.own,
      origin: origin,
      key: key,
      devTimeS: devTimeS,
      devAgitation: devAgitation,
      process: process,
    );
    await _write(r);
    return r;
  }

  /// Saves an edit. Editing an `own` recipe bumps its version. Editing a
  /// `received` one leaves it untouched and creates a new `own` copy (FR-023).
  Future<Recipe> update(
    Recipe r, {
    CombinationKey? key,
    int? devTimeS,
    AgitationPattern? devAgitation,
    Process? process,
    bool clearProcess = false,
    String? authorName,
  }) async {
    if (devTimeS != null) _checkTime(devTimeS);
    final now = _clock.now();
    if (!r.isOwn) {
      final copy = Recipe(
        id: _newId(),
        version: 1,
        createdAt: now,
        updatedAt: now,
        authorName: authorName ?? '',
        ownership: Ownership.own,
        origin: CopyOfOrigin(r.id, r.authorName),
        key: key ?? r.key,
        devTimeS: devTimeS ?? r.devTimeS,
        devAgitation: devAgitation ?? r.devAgitation,
        process: clearProcess ? null : (process ?? r.process),
      );
      await _write(copy);
      return copy;
    }
    final next = r.copyWith(
      version: r.version + 1,
      updatedAt: now,
      key: key,
      devTimeS: devTimeS,
      devAgitation: devAgitation,
      process: process,
      clearProcess: clearProcess,
    );
    await _write(next);
    return next;
  }

  /// Stores a recipe that arrived by import as `received` (merge rules live
  /// with the exchange code).
  Future<Recipe> receive(Recipe r) async {
    final stored = r.copyWith(
      ownership: Ownership.received,
      importedAt: r.importedAt ?? _clock.now(),
    );
    await _write(stored);
    return stored;
  }

  Future<void> setHidden(String id, bool hidden) =>
      (_db.update(_db.recipes)..where((t) => t.id.equals(id))).write(
        RecipesCompanion(hidden: Value(hidden)),
      );

  Future<void> delete(String id) => _db.transaction(() async {
    await (_db.delete(_db.notes)..where((t) => t.recipeId.equals(id))).go();
    await (_db.delete(_db.recipes)..where((t) => t.id.equals(id))).go();
  });

  Future<Recipe?> byId(String id) async {
    final row = await (_db.select(
      _db.recipes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Recipe>> forKey(
    String keyCanonical, {
    bool includeHidden = false,
  }) async {
    final q = _db.select(_db.recipes)
      ..where((t) => t.keyCanonical.equals(keyCanonical))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (!includeHidden) q.where((t) => t.hidden.equals(false));
    return [for (final r in await q.get()) _fromRow(r)];
  }

  Future<List<Recipe>> all({bool includeHidden = false}) async {
    final q = _db.select(_db.recipes)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (!includeHidden) q.where((t) => t.hidden.equals(false));
    return [for (final r in await q.get()) _fromRow(r)];
  }

  Stream<List<Recipe>> watchAll() =>
      (_db.select(
        _db.recipes,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            if (!r.hidden) _fromRow(r),
        ],
      );

  Future<void> _write(Recipe r) => _db
      .into(_db.recipes)
      .insertOnConflictUpdate(
        RecipesCompanion.insert(
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
        ),
      );

  Recipe _fromRow(RecipeRow row) => Recipe(
    id: row.id,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    authorName: row.authorName,
    ownership: Ownership.values.byName(row.ownership),
    origin: RecipeOrigin.fromJson(
      jsonDecode(row.originJson) as Map<String, dynamic>,
    ),
    key: CombinationKey.fromJson(
      jsonDecode(row.keyJson) as Map<String, dynamic>,
    ),
    devTimeS: row.devTimeS,
    devAgitation: AgitationPattern.fromJson(
      jsonDecode(row.devAgitationJson) as Map<String, dynamic>,
    ),
    process: row.processJson == null
        ? null
        : Process.fromJson(
            jsonDecode(row.processJson!) as Map<String, dynamic>,
          ),
    hidden: row.hidden,
    importedAt: row.importedAt,
  );
}
