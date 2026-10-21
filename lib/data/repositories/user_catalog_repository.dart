import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/clock.dart';
import '../../domain/search.dart';
import '../db/database.dart';

class UserFilm {
  const UserFilm({
    required this.id,
    required this.brand,
    required this.name,
    required this.boxIso,
    required this.createdAt,
    this.matchedCatalogId,
  });

  final String id, brand, name;
  final int boxIso;
  final String? matchedCatalogId;
  final DateTime createdAt;
}

class UserDeveloper {
  const UserDeveloper({
    required this.id,
    required this.brand,
    required this.name,
    required this.createdAt,
    this.matchedCatalogId,
  });

  final String id, brand, name;
  final String? matchedCatalogId;
  final DateTime createdAt;
}

/// Films and developers the user added themselves (FR-015).
class UserCatalogRepository {
  UserCatalogRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? (() => const Uuid().v4());

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  static void _check(String brand, String name) {
    if (brand.trim().isEmpty || brand.length > 60) {
      throw ArgumentError.value(brand, 'brand', 'must be 1–60 characters');
    }
    if (name.trim().isEmpty || name.length > 80) {
      throw ArgumentError.value(name, 'name', 'must be 1–80 characters');
    }
  }

  Future<UserFilm> addFilm({
    required String brand,
    required String name,
    required int boxIso,
  }) async {
    _check(brand, name);
    if (boxIso < 1 || boxIso > 25600) {
      throw ArgumentError.value(boxIso, 'boxIso', 'must be 1–25600');
    }
    final f = UserFilm(
      id: _newId(),
      brand: brand.trim(),
      name: name.trim(),
      boxIso: boxIso,
      createdAt: _clock.now(),
    );
    await _db
        .into(_db.userFilms)
        .insert(
          UserFilmsCompanion.insert(
            id: f.id,
            brand: f.brand,
            name: f.name,
            boxIso: f.boxIso,
            createdAt: f.createdAt,
          ),
        );
    return f;
  }

  Future<UserDeveloper> addDeveloper({
    required String brand,
    required String name,
  }) async {
    _check(brand, name);
    final d = UserDeveloper(
      id: _newId(),
      brand: brand.trim(),
      name: name.trim(),
      createdAt: _clock.now(),
    );
    await _db
        .into(_db.userDevelopers)
        .insert(
          UserDevelopersCompanion.insert(
            id: d.id,
            brand: d.brand,
            name: d.name,
            createdAt: d.createdAt,
          ),
        );
    return d;
  }

  Future<void> matchFilm(String id, String catalogId) =>
      (_db.update(_db.userFilms)..where((t) => t.id.equals(id))).write(
        UserFilmsCompanion(matchedCatalogId: Value(catalogId)),
      );

  Future<void> matchDeveloper(String id, String catalogId) =>
      (_db.update(_db.userDevelopers)..where((t) => t.id.equals(id))).write(
        UserDevelopersCompanion(matchedCatalogId: Value(catalogId)),
      );

  Future<List<UserFilm>> films() async => [
    for (final r in await (_db.select(
      _db.userFilms,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get())
      UserFilm(
        id: r.id,
        brand: r.brand,
        name: r.name,
        boxIso: r.boxIso,
        createdAt: r.createdAt,
        matchedCatalogId: r.matchedCatalogId,
      ),
  ];

  Future<List<UserDeveloper>> developers() async => [
    for (final r in await (_db.select(
      _db.userDevelopers,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get())
      UserDeveloper(
        id: r.id,
        brand: r.brand,
        name: r.name,
        createdAt: r.createdAt,
        matchedCatalogId: r.matchedCatalogId,
      ),
  ];

  /// User entries as search items, marked user-added. Entries matched to a
  /// catalogue entry are left out: they resolve to the catalogue one.
  Future<List<SearchItem>> searchItems() async => [
    for (final f in await films())
      if (f.matchedCatalogId == null)
        SearchItem(
          kind: SearchKind.film,
          id: f.id,
          brand: f.brand,
          name: f.name,
          userAdded: true,
        ),
    for (final d in await developers())
      if (d.matchedCatalogId == null)
        SearchItem(
          kind: SearchKind.developer,
          id: d.id,
          brand: d.brand,
          name: d.name,
          userAdded: true,
        ),
  ];
}
