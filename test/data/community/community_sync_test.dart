import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
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

final key = CombinationKey(
  film: const FilmRef.catalog('tri-x'),
  developer: const DeveloperRef.catalog('d76'),
  dilution: '1+1',
  ei: 400,
  tempC: 20,
);

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late FakeCommunitySource fake;
  late CommunityRepository repo;
  late SettingsRepository settings;
  late CommunitySync sync;

  Future<void> recipe(String id, String ownership) => db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: id,
          version: 1,
          createdAt: clock.now(),
          updatedAt: clock.now(),
          authorName: 'a',
          ownership: ownership,
          originJson: '{}',
          keyCanonical: key.canonical,
          keyJson: jsonEncode(key.toJson()),
          devTimeS: 600,
          devAgitationJson: '{}',
        ),
      );

  Future<void> session(
    String id, {
    String status = 'completed',
    Map<String, dynamic> source = const {'kind': 'recipe', 'recipe_id': 'mine'},
    int time = 600,
    int finishedMin = 1,
  }) => db
      .into(db.sessions)
      .insert(
        SessionsCompanion.insert(
          id: id,
          tankSlot: 1,
          tankLabel: 'A',
          keyCanonical: Value(key.canonical),
          keyJson: Value(jsonEncode(key.toJson())),
          timeSourceJson: jsonEncode(source),
          devTimeS: time,
          format: '35mm',
          volumeMl: 300,
          processSnapshotJson: '{}',
          inversionPaceS: 2,
          status: status,
          startedAt: DateTime.utc(2026, 1, 1),
          finishedAt: Value(DateTime.utc(2026, 1, 1, 0, finishedMin)),
          stepRunsJson: '[]',
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    fake = FakeCommunitySource();
    repo = CommunityRepository(db);
    settings = SettingsRepository(db);
    await db.into(db.settingsRows).insert(SettingsRowsCompanion());
    await repo.addSource(
      const SourceConfig(
        id: 'src',
        name: 'Fake',
        kind: SourceKind.supabase,
        url: 'u',
        publicKey: 'k',
        shareTo: true,
      ),
    );
    sync = CommunitySync(
      db: db,
      repo: repo,
      settings: settings,
      clock: clock,
      sourceFor: (_) => fake,
    );
    await recipe('mine', 'own');
    await recipe('theirs', 'received');
  });
  tearDown(() => db.close());

  test('switch off: a completed session makes zero calls (SC-002)', () async {
    await session('s1');
    await sync.onSessionCompleted('s1');
    expect(fake.submitted, isEmpty);
    expect(await repo.queue(), isEmpty);
  });

  test(
    'switch on: a completed own-recipe session is sent once, with the ID',
    () async {
      await sync.onShareSwitchedOn();
      await session('s1');
      await sync.onSessionCompleted('s1');
      expect(fake.submitted, hasLength(1));
      final (sub, id) = fake.submitted.single;
      expect(sub.timeS, 600);
      expect(id, (await settings.get()).contributionId);
      expect(await repo.queue(), isEmpty);
    },
  );

  test('ineligible sessions are never sent', () async {
    await sync.onShareSwitchedOn();
    await session('a', status: 'aborted');
    await session('b', source: {'kind': 'recipe', 'recipe_id': 'theirs'});
    await session('c', source: {'kind': 'manual'});
    await session('d', time: 5);
    for (final s in 'abcd'.split('')) {
      await sync.onSessionCompleted(s);
    }
    expect(fake.submitted, isEmpty);
  });

  test('offline keeps the queue; a later flush sends it (SC-007)', () async {
    await sync.onShareSwitchedOn();
    fake.offline = true;
    await session('s1');
    await sync.onSessionCompleted('s1');
    expect(fake.submitted, isEmpty);
    expect(await repo.queue(), hasLength(1));
    expect((await repo.queue()).single.attempts, 1);
    fake.offline = false;
    await sync.flush();
    expect(fake.submitted, hasLength(1));
    expect(await repo.queue(), isEmpty);
  });

  test('a rejected submission is dropped, not retried', () async {
    await sync.onShareSwitchedOn();
    fake.rejects = true;
    await session('s1');
    await sync.onSessionCompleted('s1');
    expect(await repo.queue(), isEmpty);
  });

  test(
    'switching on backfills past sessions once per combination and time',
    () async {
      await session('s1', finishedMin: 1);
      await session('s2', finishedMin: 2); // same combination and time
      await session('s3', finishedMin: 3, time: 700);
      await sync.onShareSwitchedOn();
      expect([for (final (s, _) in fake.submitted) s.timeS]..sort(), [
        600,
        700,
      ]);
      // off and on again does not resend what was already handled
      await sync.onShareSwitchedOff();
      await sync.onShareSwitchedOn();
      expect(fake.submitted, hasLength(2));
    },
  );

  test('switching off clears the queue', () async {
    await sync.onShareSwitchedOn();
    fake.offline = true;
    await session('s1');
    await sync.onSessionCompleted('s1');
    expect(await repo.queue(), hasLength(1));
    await sync.onShareSwitchedOff();
    expect(await repo.queue(), isEmpty);
    expect((await settings.get()).shareTimes, isFalse);
  });

  test(
    'the contribution ID is created once, reused, and renewed by Reset',
    () async {
      await sync.onShareSwitchedOn();
      final first = (await settings.get()).contributionId;
      expect(first, isNotNull);
      await sync.onShareSwitchedOff();
      await sync.onShareSwitchedOn();
      expect((await settings.get()).contributionId, first);
      await sync.resetContributionId();
      expect((await settings.get()).contributionId, isNull);
      await session('s1', finishedMin: 9);
      await sync.onSessionCompleted('s1');
      final second = fake.submitted.last.$2;
      expect(second, isNot(first));
      expect((await settings.get()).contributionId, second);
    },
  );

  test('a read-only or share-off source gets nothing', () async {
    await repo.setShareTo('src', false);
    await sync.onShareSwitchedOn();
    await session('s1');
    await sync.onSessionCompleted('s1');
    expect(fake.submitted, isEmpty);
  });

  group('refresh', () {
    CommunityEntry entry() => CommunityEntry(
      key: key,
      timeS: 540,
      installs: 3,
      lastConfirmed: DateTime.utc(2026),
    );

    test('at most once per 24 h; failure keeps the cache', () async {
      fake.feed = CommunityFeed(entries: [entry()]);
      expect(await sync.refreshStale(), isTrue);
      expect(await repo.entriesFor(key), hasLength(1));
      expect(await sync.refreshStale(), isFalse);
      expect(fake.fetches, 1);

      clock.advance(const Duration(hours: 25));
      fake.offline = true;
      expect(await sync.refreshStale(), isFalse);
      expect(
        await repo.entriesFor(key),
        hasLength(1),
        reason: 'old cache kept',
      );

      fake.offline = false;
      fake.feed = const CommunityFeed(entries: []);
      expect(await sync.refreshStale(), isTrue);
      expect(await repo.entriesFor(key), isEmpty);
    });

    test('with no sources no source is touched (FR-015)', () async {
      await repo.removeSource('src');
      expect(await sync.refreshStale(force: true), isFalse);
      await sync.onShareSwitchedOn();
      expect(fake.fetches, 0);
      expect(fake.submitted, isEmpty);
    });
  });
}
