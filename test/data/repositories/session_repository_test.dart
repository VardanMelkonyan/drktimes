import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/session_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/session_meta.dart';
import 'package:drktimes/domain/sessions.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repo;
  late FakeClock clock;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SessionRepository(db);
    clock = FakeClock();
  });
  tearDown(() => db.close());

  SessionRun make(SessionCoordinator c, {SessionMeta? meta}) => c.create(
    process: Process.defaults(),
    devTimeS: 780,
    inversionPaceS: 2,
    meta: meta ?? const SessionMeta(),
  );

  test('saves on each transition and rebuilds the same state', () async {
    final c = SessionCoordinator();
    final a = make(c)..start(clock.now());
    await repo.save(a);
    clock.advance(const Duration(seconds: 100));
    a.pause(clock.now());
    await repo.save(a);
    clock.advance(const Duration(seconds: 40));
    a.resume(clock.now());
    await repo.save(a);
    clock.advance(const Duration(seconds: 10));

    final restored = (await repo.loadActive()).active;
    expect(restored, hasLength(1));
    final b = restored.single;
    expect(b.tankSlot, 1);
    expect(b.stateAt(clock.now()).remaining, a.stateAt(clock.now()).remaining);
    expect(b.stateAt(clock.now()).phase, a.stateAt(clock.now()).phase);
    expect(b.process.toJson(), a.process.toJson());
  });

  test('finished sessions are not restored as active', () async {
    final c = SessionCoordinator();
    final a = make(c)..start(clock.now());
    a.abort(clock.now());
    await repo.save(a);
    expect((await repo.loadActive()).active, isEmpty);
    final row = await db.select(db.sessions).getSingle();
    expect(row.status, 'aborted');
    expect(row.abortedAtStep, 0);
  });

  test(
    'keeps the combination key and finds the latest session for it',
    () async {
      final key = CombinationKey(
        film: const FilmRef.catalog('ilford-hp5-plus'),
        developer: const DeveloperRef.catalog('ilford-ilfotec-dd-x'),
        dilution: '1+4',
        ei: 400,
        tempC: 20,
      );
      final c = SessionCoordinator();
      final a = make(
        c,
        meta: SessionMeta(
          key: key,
          timeSource: const {'kind': 'datasheet', 'source_id': 'x'},
          format: '120',
          volumeMl: 500,
        ),
      )..start(clock.now());
      await repo.save(a);
      final found = await repo.latestFor(key.canonical);
      expect(found!.meta.key, key);
      expect(found.meta.format, '120');
      expect(found.meta.volumeMl, 500);
      expect(found.meta.timeSource['source_id'], 'x');
      expect(await repo.latestFor('other'), isNull);
    },
  );

  test('a manual session has no key', () async {
    final c = SessionCoordinator();
    final a = make(c)..start(clock.now());
    await repo.save(a);
    final b = (await repo.loadActive()).active.single;
    expect(b.meta.key, isNull);
    expect(b.meta.timeSource['kind'], 'manual');
  });
}
