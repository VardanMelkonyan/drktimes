import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/user_catalog_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late UserCatalogRepository repo;
  var n = 0;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserCatalogRepository(db, FakeClock(), newId: () => 'u${++n}');
  });
  tearDown(() => db.close());

  test('adds a film and a developer', () async {
    final f = await repo.addFilm(brand: 'Shanghai', name: 'GP3', boxIso: 100);
    final d = await repo.addDeveloper(brand: 'Home', name: 'Coffenol');
    expect((await repo.films()).single.id, f.id);
    expect((await repo.developers()).single.id, d.id);
  });

  test('validates lengths and ISO', () async {
    expect(
      () => repo.addFilm(brand: '', name: 'x', boxIso: 100),
      throwsArgumentError,
    );
    expect(
      () => repo.addFilm(brand: 'x' * 61, name: 'x', boxIso: 100),
      throwsArgumentError,
    );
    expect(
      () => repo.addFilm(brand: 'x', name: 'y' * 81, boxIso: 100),
      throwsArgumentError,
    );
    expect(
      () => repo.addFilm(brand: 'x', name: 'y', boxIso: 0),
      throwsArgumentError,
    );
    expect(
      () => repo.addFilm(brand: 'x', name: 'y', boxIso: 25601),
      throwsArgumentError,
    );
    expect(() => repo.addDeveloper(brand: 'x', name: ''), throwsArgumentError);
  });

  test(
    'search items are marked user-added; matched entries drop out',
    () async {
      final f = await repo.addFilm(brand: 'Shanghai', name: 'GP3', boxIso: 100);
      await repo.addDeveloper(brand: 'Home', name: 'Coffenol');
      var items = await repo.searchItems();
      expect(items.length, 2);
      expect(items.every((i) => i.userAdded), isTrue);
      expect(items.first.kind, SearchKind.film);
      await repo.matchFilm(f.id, 'shanghai-gp3');
      items = await repo.searchItems();
      expect(items.length, 1);
    },
  );
}
