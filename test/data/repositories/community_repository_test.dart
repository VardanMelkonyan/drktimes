import 'package:drift/native.dart';
import 'package:drktimes/data/community/community_repository.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/community/community_feed.dart';
import 'package:drktimes/domain/community/share_queue.dart';
import 'package:flutter_test/flutter_test.dart';

final key = CombinationKey(
  film: const FilmRef.catalog('tri-x'),
  developer: const DeveloperRef.catalog('d76'),
  dilution: '1+1',
  ei: 400,
  tempC: 20,
);

CommunityEntry entry(int t, int installs) => CommunityEntry(
  key: key,
  timeS: t,
  installs: installs,
  lastConfirmed: DateTime.utc(2026, 10),
);

QueueItem item(String id, String src, int t, {int attempts = 0}) => QueueItem(
  id: id,
  sourceId: src,
  keyCanonical: key.canonical,
  timeS: t,
  createdAt: DateTime.utc(2026, 10, 1, 0, 0, int.parse(id.substring(1))),
  attempts: attempts,
);

void main() {
  late AppDatabase db;
  late CommunityRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = CommunityRepository(db);
    for (final id in ['a', 'b']) {
      await repo.addSource(
        SourceConfig(
          id: id,
          name: 'Src $id',
          kind: SourceKind.static,
          url: 'u',
        ),
      );
    }
  });
  tearDown(() => db.close());

  test('sources keep their order', () async {
    expect([for (final s in await repo.sources()) s.id], ['a', 'b']);
  });

  test(
    'replaceEntries swaps a source\'s whole set and records the fetch',
    () async {
      await repo.replaceEntries('a', [
        entry(500, 3),
        entry(900, 2),
      ], DateTime.utc(2026, 10, 2));
      await repo.replaceEntries('b', [
        entry(520, 4),
      ], DateTime.utc(2026, 10, 2));
      await repo.replaceEntries('a', [
        entry(510, 5),
      ], DateTime.utc(2026, 10, 3));
      final all = await repo.entriesFor(key);
      expect(
        {for (final e in all) '${e.sourceId}:${e.timeS}'},
        {'a:510', 'b:520'},
      );
      expect((await repo.fetchedAt('a'))!.toUtc(), DateTime.utc(2026, 10, 3));
      expect(await repo.fetchedAt('zzz'), isNull);
    },
  );

  test('removing a source deletes its cache and queue rows', () async {
    await repo.replaceEntries('a', [entry(500, 3)], DateTime.utc(2026, 10, 2));
    await repo.enqueue([item('q1', 'a', 500), item('q2', 'b', 500)]);
    await repo.removeSource('a');
    expect(await repo.entriesFor(key), isEmpty);
    expect([for (final q in await repo.queue()) q.id], ['q2']);
    expect(await repo.fetchedAt('a'), isNull);
    expect([for (final s in await repo.sources()) s.id], ['b']);
  });

  test(
    'queue dedupes by source, combination and time; clear empties it',
    () async {
      expect(
        await repo.enqueue([item('q1', 'a', 500), item('q2', 'a', 500)]),
        1,
      );
      expect(
        await repo.enqueue([item('q3', 'a', 500), item('q4', 'a', 501)]),
        1,
      );
      expect(await repo.queue(), hasLength(2));
      await repo.noteFailure('q1');
      expect(
        (await repo.queue()).first.id,
        'q4',
        reason: 'failed items go last',
      );
      await repo.dequeue('q4');
      await repo.clearQueue();
      expect(await repo.queue(), isEmpty);
    },
  );
}
