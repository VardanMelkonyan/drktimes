import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/backup_service.dart';
import 'package:drktimes/data/repositories/favourites_repository.dart';
import 'package:drktimes/data/repositories/import_service.dart';
import 'package:drktimes/data/repositories/note_repository.dart';
import 'package:drktimes/data/repositories/process_repository.dart';
import 'package:drktimes/data/repositories/recipe_repository.dart';
import 'package:drktimes/data/repositories/session_repository.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/data/repositories/user_catalog_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/exchange/codec.dart';
import 'package:drktimes/domain/exchange/document.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:drktimes/domain/session_meta.dart';
import 'package:drktimes/domain/sessions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = Catalog.fromJson(
    jsonDecode(File('assets/devdata.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  late AppDatabase db;
  late FakeClock clock;
  var n = 0;

  Future<AppDatabase> fresh() async {
    final d = AppDatabase(NativeDatabase.memory());
    await seedDatabase(d);
    return d;
  }

  setUp(() async {
    db = await fresh();
    clock = FakeClock();
    n = 0;
  });
  tearDown(() => db.close());

  Future<void> seedEverything() async {
    String id() =>
        '00000000-0000-4000-8000-${(++n).toString().padLeft(12, '0')}';
    final user = UserCatalogRepository(db, clock, newId: id);
    final film = await user.addFilm(
      brand: 'Shanghai',
      name: 'GP3',
      boxIso: 100,
    );
    final dev = await user.addDeveloper(brand: 'Home', name: 'Coffenol');
    final recipes = RecipeRepository(db, clock, newId: id);
    final notes = NoteRepository(db, clock, newId: id);
    final key = CombinationKey(
      film: FilmRef.user(film.id),
      developer: DeveloperRef.user(dev.id),
      dilution: 'stock',
      ei: 100,
      tempC: 20,
    );
    final own = await recipes.create(
      key: key,
      devTimeS: 1200,
      devAgitation: const Stand(
        initialS: 30,
        midAgitationAtS: 390,
        midBurstS: 10,
      ),
      origin: const ScratchOrigin(),
      authorName: 'Me',
      process: Process.defaults().copyWith(
        id: '00000000-0000-4000-8000-0000000000aa',
        transitionMode: TransitionMode.keepGoing,
      ),
    );
    await notes.add(recipeId: own.id, authorName: 'Me', text: 'first roll');
    clock.advance(const Duration(minutes: 3));
    await notes.add(recipeId: own.id, authorName: 'Me', text: 'second roll');
    final received = await recipes.receive(
      Recipe(
        id: '00000000-0000-4000-8000-0000000000bb',
        version: 3,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
        authorName: 'Ani M.',
        ownership: Ownership.received,
        origin: const DatasheetOrigin('kodak-f4017-2021-10', page: 3),
        key: CombinationKey(
          film: const FilmRef.catalog('kodak-tri-x-400'),
          developer: const DeveloperRef.catalog('rodinal'),
          dilution: '1+50',
          ei: 400,
          tempC: 20,
        ),
        devTimeS: 780,
        devAgitation: const Continuous(),
      ),
    );
    await recipes.setHidden(received.id, true);
    await FavouritesRepository(db, clock).add(key);
    await ProcessRepository(db).save(
      Process.defaults().copyWith(id: '00000000-0000-4000-8000-0000000000cc'),
    );
    final c = SessionCoordinator();
    final done = c.create(
      process: Process.defaults(),
      devTimeS: 780,
      inversionPaceS: 2,
      meta: SessionMeta(key: key, format: '120', volumeMl: 500),
    )..start(clock.now());
    done.abort(clock.now());
    await SessionRepository(db).save(done);
    final active = c.create(
      process: Process.defaults(),
      devTimeS: 60,
      inversionPaceS: 2,
      meta: SessionMeta(key: key),
    )..start(clock.now());
    await SessionRepository(db).save(active);
    await SettingsRepository(db)
        .update(authorName: 'Me', volume35mmMl: 350, tempUnit: TempUnit.f);
  }

  /// Everything a backup should bring back, in a comparable shape.
  Future<Map<String, Object?>> dump(AppDatabase d) async => {
    'recipes': [
      for (final r in await (d.select(
        d.recipes,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
        [
          r.id,
          r.version,
          r.createdAt.toUtc(),
          r.updatedAt.toUtc(),
          r.authorName,
          r.ownership,
          r.originJson,
          r.keyCanonical,
          r.devTimeS,
          r.devAgitationJson,
          r.processJson,
          r.hidden,
        ],
    ],
    'notes': [
      for (final x in await (d.select(
        d.notes,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
        [x.id, x.recipeId, x.authorName, x.createdAt.toUtc(), x.text_],
    ],
    'films': [
      for (final f in await d.select(d.userFilms).get())
        [f.id, f.brand, f.name, f.boxIso],
    ],
    'devs': [
      for (final f in await d.select(d.userDevelopers).get())
        [f.id, f.brand, f.name],
    ],
    'favs': [
      for (final f in await d.select(d.favourites).get()) f.keyCanonical,
    ],
    'finished': [
      for (final s in await (d.select(
        d.sessions,
      )..where((t) => t.status.isIn(['completed', 'aborted']))).get())
        [s.id, s.keyCanonical, s.status, s.format, s.devTimeS, s.abortedAtStep],
    ],
    'active': [
      for (final s in await (d.select(
        d.sessions,
      )..where((t) => t.status.equals('active'))).get())
        s.id,
    ],
    'processes': [
      for (final p in await (d.select(
        d.processes,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
        p.id,
    ],
  };

  test('export → wipe → import brings everything back (SC-010)', () async {
    await seedEverything();
    final before = await dump(db);
    final backup = BackupService(db, clock);
    final text = ExchangeCodec.encodeString(await backup.backupDocument());

    final other = await fresh();
    addTearDown(other.close);
    final result = await ImportService(
      other,
      clock,
      catalog,
    ).import(ExchangeCodec.decodeString(text), restoreSettings: true);
    expect(result.added, 2);

    final after = await dump(other);
    expect(
      after['active'],
      isEmpty,
      reason: 'active sessions are not exported',
    );
    expect(after['recipes'], before['recipes']);
    expect(after['notes'], before['notes']);
    expect(after['films'], before['films']);
    expect(after['devs'], before['devs']);
    expect(after['favs'], before['favs']);
    expect(after['finished'], before['finished']);
    expect(after['processes'], before['processes']);
    final s = await SettingsRepository(other).get();
    expect(s.authorName, 'Me');
    expect(s.volume35mmMl, 350);
    expect(s.tempUnit, TempUnit.f);
  });

  test('importing the same backup again changes nothing', () async {
    await seedEverything();
    final text = ExchangeCodec.encodeString(
      await BackupService(db, clock).backupDocument(),
    );
    final other = await fresh();
    addTearDown(other.close);
    final svc = ImportService(other, clock, catalog);
    await svc.import(ExchangeCodec.decodeString(text));
    final once = await dump(other);
    final second = await svc.import(ExchangeCodec.decodeString(text));
    expect(second.nothingChanged, isTrue);
    expect(second.plan.changesAnything, isFalse);
    expect(await dump(other), once);
  });

  test('an older backup never overwrites newer local rows', () async {
    await seedEverything();
    final text = ExchangeCodec.encodeString(
      await BackupService(db, clock).backupDocument(),
    );
    final recipes = RecipeRepository(db, clock);
    final own = (await recipes.all()).firstWhere((r) => r.isOwn);
    clock.advance(const Duration(days: 1));
    await recipes.update(own, devTimeS: 1500);
    final result = await ImportService(
      db,
      clock,
      catalog,
    ).import(ExchangeCodec.decodeString(text));
    expect(result.updated, 0);
    expect((await recipes.byId(own.id))!.devTimeS, 1500);
  });

  test('settings are restored only when asked', () async {
    await seedEverything();
    final text = ExchangeCodec.encodeString(
      await BackupService(db, clock).backupDocument(),
    );
    final other = await fresh();
    addTearDown(other.close);
    await ImportService(
      other,
      clock,
      catalog,
    ).import(ExchangeCodec.decodeString(text));
    expect((await SettingsRepository(other).get()).volume35mmMl, 300);
  });

  test('only own recipes can be shared', () async {
    await seedEverything();
    final backup = BackupService(db, clock);
    final recipes = RecipeRepository(db, clock);
    final own = (await recipes.all(includeHidden: true))
        .firstWhere((r) => r.isOwn);
    final doc = await backup.recipeDocument(own.id);
    expect(doc.kind, ExchangeKind.recipe);
    expect(doc.userFilms, hasLength(1));
    expect(doc.recipes.single.notes, hasLength(2));
    final rec = (await recipes.all(includeHidden: true))
        .firstWhere((r) => !r.isOwn);
    expect(() => backup.recipeDocument(rec.id), throwsStateError);
  });

  test('a shared recipe imports as received on the other phone', () async {
    await seedEverything();
    final recipes = RecipeRepository(db, clock);
    final own = (await recipes.all(includeHidden: true))
        .firstWhere((r) => r.isOwn);
    final doc = await BackupService(db, clock).recipeDocument(own.id);
    final other = await fresh();
    addTearDown(other.close);
    final svc = ImportService(other, clock, catalog);
    final first = await svc.import(
      ExchangeCodec.decodeString(ExchangeCodec.encodeString(doc)),
    );
    expect(first.added, 1);
    final got = await RecipeRepository(other, clock).byId(own.id);
    expect(got!.ownership, Ownership.received);
    expect(got.importedAt, isNotNull);
    final again = await svc.import(
      ExchangeCodec.decodeString(ExchangeCodec.encodeString(doc)),
    );
    expect(again.nothingChanged, isTrue);
  });
}
