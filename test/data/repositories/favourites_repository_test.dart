import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/favourites_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:flutter_test/flutter_test.dart';

CombinationKey key(int ei) => CombinationKey(
  film: const FilmRef.catalog('kodak-tri-x-400'),
  developer: const DeveloperRef.catalog('rodinal'),
  dilution: '1+50',
  ei: ei,
  tempC: 20,
);

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late FavouritesRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    repo = FavouritesRepository(db, clock);
  });
  tearDown(() => db.close());

  test('add, remove and toggle by canonical key', () async {
    await repo.add(key(400));
    expect(await repo.isFavourite(key(400)), isTrue);
    expect(await repo.isFavourite(key(800)), isFalse);
    await repo.add(key(400));
    expect(await repo.all(), hasLength(1));
    await repo.toggle(key(400));
    expect(await repo.isFavourite(key(400)), isFalse);
    await repo.toggle(key(400));
    expect(await repo.isFavourite(key(400)), isTrue);
    await repo.remove(key(400));
    expect(await repo.all(), isEmpty);
  });

  test('newest first', () async {
    await repo.add(key(400));
    clock.advance(const Duration(minutes: 1));
    await repo.add(key(800));
    expect([for (final k in await repo.all()) k.ei], [800, 400]);
  });

  test('watch emits changes', () async {
    final seen = expectLater(
      repo.watch().map((l) => l.length),
      emitsInOrder([0, 1]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.add(key(400));
    await seen;
  });
}
