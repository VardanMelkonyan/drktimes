import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/note_repository.dart';
import 'package:drktimes/data/repositories/recipe_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late RecipeRepository recipes;
  late NoteRepository notes;
  var n = 0;

  final key = CombinationKey(
    film: const FilmRef.catalog('kodak-tri-x-400'),
    developer: const DeveloperRef.catalog('rodinal'),
    dilution: '1+50',
    ei: 400,
    tempC: 20,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    n = 0;
    recipes = RecipeRepository(db, clock, newId: () => 'id${++n}');
    notes = NoteRepository(db, clock, newId: () => 'note${++n}');
  });
  tearDown(() => db.close());

  Future<Recipe> create({RecipeOrigin? origin, int timeS = 780}) =>
      recipes.create(
        key: key,
        devTimeS: timeS,
        devAgitation: const Intermittent(initialS: 60, everyS: 60, burstS: 10),
        origin: origin ?? const ScratchOrigin(),
        authorName: 'Me',
      );

  test('create from datasheet or scratch starts at version 1', () async {
    final a = await create(
      origin: const DatasheetOrigin('kodak-f4017-2021-10', page: 3),
    );
    final b = await create();
    expect(a.version, 1);
    expect(a.ownership, Ownership.own);
    expect(a.origin, isA<DatasheetOrigin>());
    expect(b.origin, isA<ScratchOrigin>());
    expect((await recipes.byId(a.id))!.key, key);
  });

  test('each edit does version+1 and updated_at=now', () async {
    final r = await create();
    clock.advance(const Duration(days: 1));
    final r2 = await recipes.update(r, devTimeS: 800);
    expect(r2.id, r.id);
    expect(r2.version, 2);
    expect(r2.devTimeS, 800);
    expect(r2.updatedAt, clock.now());
    expect(r2.createdAt, r.createdAt);
    expect((await recipes.byId(r.id))!.version, 2);
  });

  test(
    'editing a received recipe makes a new own copy and leaves it alone',
    () async {
      final received = await recipes.receive(
        (await create()).copyWith(
          id: 'other-id',
          ownership: Ownership.received,
          authorName: 'Alex',
        ),
      );
      final edited = await recipes.update(received, devTimeS: 900);
      expect(edited.id, isNot(received.id));
      expect(edited.ownership, Ownership.own);
      expect(edited.version, 1);
      expect(edited.origin, isA<CopyOfOrigin>());
      expect((edited.origin as CopyOfOrigin).recipeId, 'other-id');
      expect((edited.origin as CopyOfOrigin).authorName, 'Alex');
      final still = (await recipes.byId('other-id'))!;
      expect(still.devTimeS, 780);
      expect(still.ownership, Ownership.received);
    },
  );

  test('dev time must be 30–7200 s', () async {
    expect(() => create(timeS: 29), throwsArgumentError);
    expect(() => create(timeS: 7201), throwsArgumentError);
    await create(timeS: 30);
    await create(timeS: 7200);
  });

  test('notes are ordered by time and limited to 1–4000 characters', () async {
    final r = await create();
    await notes.add(recipeId: r.id, authorName: 'Me', text: 'first');
    clock.advance(const Duration(minutes: 5));
    await notes.add(recipeId: r.id, authorName: 'Me', text: 'second');
    expect(
      [for (final x in await notes.forRecipe(r.id)) x.text],
      ['first', 'second'],
    );
    expect(
      () => notes.add(recipeId: r.id, authorName: 'Me', text: ''),
      throwsArgumentError,
    );
    expect(
      () => notes.add(recipeId: r.id, authorName: 'Me', text: 'x' * 4001),
      throwsArgumentError,
    );
    await notes.add(recipeId: r.id, authorName: 'Me', text: 'x' * 4000);
  });

  test(
    'forKey returns visible recipes, hidden received ones on request',
    () async {
      final own = await create();
      final rec = await recipes.receive(
        own.copyWith(
          id: 'r-x',
          ownership: Ownership.received,
          authorName: 'Alex',
        ),
      );
      expect(await recipes.forKey(key.canonical), hasLength(2));
      await recipes.setHidden(rec.id, true);
      expect(
        [for (final r in await recipes.forKey(key.canonical)) r.id],
        [own.id],
      );
      expect(
        await recipes.forKey(key.canonical, includeHidden: true),
        hasLength(2),
      );
    },
  );

  test('process override round-trips and delete removes notes too', () async {
    final r = await create();
    final p = Process.defaults().copyWith(id: 'custom');
    final r2 = await recipes.update(r, process: p);
    expect((await recipes.byId(r.id))!.process!.id, 'custom');
    await notes.add(recipeId: r.id, authorName: 'Me', text: 'hi');
    await recipes.delete(r2.id);
    expect(await recipes.byId(r.id), isNull);
    expect(await notes.forRecipe(r.id), isEmpty);
  });
}
