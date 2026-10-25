import 'package:drift/native.dart';
import 'package:drktimes/data/community/community_repository.dart';
import 'package:drktimes/data/community/community_sync.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/community/community_feed.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_community_source.dart';

void main() {
  late AppDatabase db;
  late FakeCommunitySource fake;
  late CommunityRepository repo;
  late CommunitySync sync;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fake = FakeCommunitySource();
    repo = CommunityRepository(db);
    sync = CommunitySync(
      db: db,
      repo: repo,
      settings: SettingsRepository(db),
      clock: FakeClock(),
      sourceFor: (_) => fake,
    );
  });
  tearDown(() => db.close());

  final key = CombinationKey(
    film: const FilmRef.catalog('f'),
    developer: const DeveloperRef.catalog('d'),
    dilution: 'stock',
    ei: 400,
    tempC: 20,
  );

  test('a valid feed is added, its entries cached under its name', () async {
    fake.feed = CommunityFeed(
      entries: [
        CommunityEntry(
          key: key,
          timeS: 500,
          installs: 2,
          lastConfirmed: DateTime.utc(2026),
        ),
      ],
    );
    expect(
      await sync.addSource(name: ' Club ', url: 'https://x.test/f.json'),
      isNull,
    );
    final s = (await repo.sources()).single;
    expect((s.name, s.kind, s.shareTo), ('Club', SourceKind.static, false));
    expect(await repo.entriesFor(key), hasLength(1));
  });

  test('a key makes it a project source', () async {
    await sync.addSource(name: 'P', url: 'https://x.test', publicKey: 'k');
    expect((await repo.sources()).single.kind, SourceKind.supabase);
  });

  test(
    'unreachable, malformed or badly addressed sources are not saved',
    () async {
      fake.offline = true;
      expect(await sync.addSource(name: 'A', url: 'https://x.test'), isNotNull);
      fake.offline = false;
      fake.malformed = true;
      expect(
        await sync.addSource(name: 'A', url: 'https://x.test'),
        contains('feed'),
      );
      fake.malformed = false;
      expect(await sync.addSource(name: 'A', url: 'http://x.test'), isNotNull);
      expect(await sync.addSource(name: '', url: 'https://x.test'), isNotNull);
      expect(await repo.sources(), isEmpty);
    },
  );

  test(
    'a source that goes bad keeps its old cache and shows no error',
    () async {
      await sync.addSource(name: 'A', url: 'https://x.test');
      final id = (await repo.sources()).single.id;
      await repo.replaceEntries(id, [
        CommunityEntry(
          key: key,
          timeS: 500,
          installs: 2,
          lastConfirmed: DateTime.utc(2026),
        ),
      ], DateTime.utc(2020));
      fake.malformed = true;
      expect(await sync.refreshStale(), isFalse);
      expect(await repo.entriesFor(key), hasLength(1));
    },
  );
}
