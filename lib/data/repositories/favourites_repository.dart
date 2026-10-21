import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/clock.dart';
import '../../domain/combination_key.dart';
import '../db/database.dart';

/// Starred combinations (FR-051).
class FavouritesRepository {
  FavouritesRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Future<void> add(CombinationKey key) => _db
      .into(_db.favourites)
      .insertOnConflictUpdate(
        FavouritesCompanion.insert(
          keyCanonical: key.canonical,
          keyJson: jsonEncode(key.toJson()),
          createdAt: _clock.now(),
        ),
      );

  Future<void> remove(CombinationKey key) => (_db.delete(
    _db.favourites,
  )..where((t) => t.keyCanonical.equals(key.canonical))).go();

  Future<void> toggle(CombinationKey key) async =>
      await isFavourite(key) ? remove(key) : add(key);

  Future<bool> isFavourite(CombinationKey key) async =>
      (await (_db.select(_db.favourites)
            ..where((t) => t.keyCanonical.equals(key.canonical)))
          .getSingleOrNull()) !=
      null;

  /// Newest first.
  Future<List<CombinationKey>> all() async => [
    for (final r in await (_db.select(
      _db.favourites,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get())
      CombinationKey.fromJson(jsonDecode(r.keyJson) as Map<String, dynamic>),
  ];

  Stream<List<CombinationKey>> watch() =>
      (_db.select(
        _db.favourites,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            CombinationKey.fromJson(
              jsonDecode(r.keyJson) as Map<String, dynamic>,
            ),
        ],
      );
}
