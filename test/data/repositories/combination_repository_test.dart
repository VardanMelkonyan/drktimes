import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/combination_repository.dart';
import 'package:drktimes/data/repositories/note_repository.dart';
import 'package:drktimes/data/repositories/recipe_repository.dart';
import 'package:drktimes/data/repositories/session_repository.dart';
import 'package:drktimes/data/repositories/user_catalog_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/preselect.dart';
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
  late RecipeRepository recipes;
  late NoteRepository notes;
  late SessionRepository sessions;
  late CombinationRepository repo;

  CombinationKey key({
    String film = 'ilford-hp5-plus',
    String dev = 'ilford-ilfotec-dd-x',
    String dil = '1+4',
    int ei = 400,
    int t = 20,
  }) => CombinationKey(
    film: FilmRef.catalog(film),
    developer: DeveloperRef.catalog(dev),
    dilution: dil,
    ei: ei,
    tempC: t,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    recipes = RecipeRepository(db, clock);
    notes = NoteRepository(db, clock);
    sessions = SessionRepository(db);
    repo = CombinationRepository(
      catalog: catalog,
      recipes: recipes,
      notes: notes,
      sessions: sessions,
      userCatalog: UserCatalogRepository(db, clock),
    );
  });
  tearDown(() => db.close());

  test(
    'flow A: HP5 Plus · DD-X 1+4 · 400 · 20 °C is 9:00 from an Ilford sheet',
    () async {
      final v = await repo.load(key());
      expect(v.filmLabel, 'Ilford HP5 Plus');
      expect(v.rows.every((r) => r.kind == TimeRowKind.datasheet), isTrue);
      expect(v.preselection!.branch, PreselectBranch.datasheet);
      expect(v.preselection!.timeS, 540);
      expect(
        v.preselectedRow!.datasheet!.source.publisher,
        'Harman Technology',
      );
      expect(v.summary, isNotNull);
    },
  );

  test('a combination without data is empty', () async {
    final v = await repo.load(
      key(film: 'kodak-tri-x-400', dev: 'ilford-ilfotec-dd-x', ei: 12800),
    );
    expect(v.isEmpty, isTrue);
    expect(v.preselection, isNull);
  });

  test(
    'datasheet, own and received rows share one list in that order',
    () async {
      final k = key();
      final own = await recipes.create(
        key: k,
        devTimeS: 600,
        devAgitation: const Continuous(),
        origin: const ScratchOrigin(),
        authorName: 'Me',
      );
      final rec = await recipes.receive(
        own.copyWith(
          id: 'r',
          ownership: Ownership.received,
          authorName: 'Alex',
          devTimeS: 630,
        ),
      );
      await notes.add(recipeId: own.id, authorName: 'Me', text: 'n1');
      final v = await repo.load(k);
      final kinds = [for (final r in v.rows) r.kind];
      expect(kinds.first, TimeRowKind.datasheet);
      expect(kinds.sublist(kinds.length - 2), [
        TimeRowKind.own,
        TimeRowKind.received,
      ]);
      expect(v.notes.single.text, 'n1');
      expect(rec.id, 'r');
    },
  );

  test('"used last time" wins over the datasheet', () async {
    final k = key();
    final own = await recipes.create(
      key: k,
      devTimeS: 600,
      devAgitation: const Continuous(),
      origin: const ScratchOrigin(),
      authorName: 'Me',
    );
    final c = SessionCoordinator();
    final s = c.create(
      process: Process.defaults(),
      devTimeS: 600,
      inversionPaceS: 2,
      meta: SessionMeta(
        key: k,
        timeSource: {
          'kind': 'recipe',
          'recipe_id': own.id,
          'recipe_version': 1,
        },
      ),
    )..start(clock.now());
    await sessions.save(s);
    final v = await repo.load(k);
    expect(v.preselection!.branch, PreselectBranch.lastUsed);
    expect(v.preselection!.timeS, 600);
  });

  test('a rebrand shows the original’s rows as inherited', () async {
    final v = await repo.load(
      key(
        film: 'adox-scala-50',
        dev: 'ilford-ilfotec-dd-x',
        dil: '1+4',
        ei: 50,
      ),
    );
    expect(v.filmIsRebrand, isTrue);
  });
}
