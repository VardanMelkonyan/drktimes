import 'package:drift/drift.dart';

import '../../domain/combination_key.dart';
import '../../domain/community/community_feed.dart';
import '../../domain/community/share_queue.dart';
import '../db/database.dart';

enum SourceKind { static, supabase }

class SourceConfig {
  const SourceConfig({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.publicKey,
    this.shareTo = false,
    this.position = 0,
  });

  final String id, name, url;
  final SourceKind kind;
  final String? publicKey;
  final bool shareTo;
  final int position;
}

/// Sources, the cached feeds and the send queue (spec 002), in drift.
class CommunityRepository {
  CommunityRepository(this._db);

  final AppDatabase _db;

  // ---- sources ----

  Future<List<SourceConfig>> sources() async {
    final rows = await (_db.select(
      _db.communitySources,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return [for (final r in rows) _source(r)];
  }

  Stream<List<SourceConfig>> watchSources() =>
      (_db.select(_db.communitySources)
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .watch()
          .map((rows) => [for (final r in rows) _source(r)]);

  Future<void> addSource(SourceConfig s) async {
    final last = await (_db.selectOnly(
      _db.communitySources,
    )..addColumns([_db.communitySources.position.max()])).getSingle();
    final next = (last.read(_db.communitySources.position.max()) ?? -1) + 1;
    await _db
        .into(_db.communitySources)
        .insertOnConflictUpdate(
          CommunitySourcesCompanion.insert(
            id: s.id,
            name: s.name,
            kind: s.kind.name,
            url: s.url,
            publicKey: Value(s.publicKey),
            shareTo: Value(s.shareTo),
            position: Value(next),
          ),
        );
  }

  Future<void> setShareTo(String id, bool on) =>
      (_db.update(_db.communitySources)..where((t) => t.id.equals(id))).write(
        CommunitySourcesCompanion(shareTo: Value(on)),
      );

  /// Removes a source with its cached entries and queued submissions.
  Future<void> removeSource(String id) => _db.transaction(() async {
    await (_db.delete(
      _db.communityEntries,
    )..where((t) => t.sourceId.equals(id))).go();
    await (_db.delete(
      _db.communityFetches,
    )..where((t) => t.sourceId.equals(id))).go();
    await (_db.delete(
      _db.shareQueue,
    )..where((t) => t.sourceId.equals(id))).go();
    await (_db.delete(
      _db.communitySources,
    )..where((t) => t.id.equals(id))).go();
  });

  // ---- cache ----

  /// Replaces all cached entries of [sourceId] at once and records the fetch.
  Future<void> replaceEntries(
    String sourceId,
    List<CommunityEntry> entries,
    DateTime fetchedAt,
  ) => _db.transaction(() async {
    await (_db.delete(
      _db.communityEntries,
    )..where((t) => t.sourceId.equals(sourceId))).go();
    final unique = <String, CommunityEntry>{};
    for (final e in entries) {
      unique['${e.key.canonical}|${e.timeS}'] = e;
    }
    await _db.batch(
      (b) => b.insertAll(_db.communityEntries, [
        for (final e in unique.values)
          CommunityEntriesCompanion.insert(
            sourceId: sourceId,
            keyCanonical: e.key.canonical,
            timeS: e.timeS,
            installs: e.installs,
            lastConfirmed: e.lastConfirmed,
          ),
      ]),
    );
    await _db
        .into(_db.communityFetches)
        .insertOnConflictUpdate(
          CommunityFetchesCompanion.insert(
            sourceId: sourceId,
            fetchedAt: fetchedAt,
          ),
        );
  });

  Future<DateTime?> fetchedAt(String sourceId) async {
    final r = await (_db.select(
      _db.communityFetches,
    )..where((t) => t.sourceId.equals(sourceId))).getSingleOrNull();
    return r?.fetchedAt;
  }

  /// Cached entries for one combination, across sources (grouping is
  /// `community_merge.dart`'s job).
  Future<List<CommunityEntry>> entriesFor(CombinationKey key) async {
    final rows = await (_db.select(
      _db.communityEntries,
    )..where((t) => t.keyCanonical.equals(key.canonical))).get();
    return [
      for (final r in rows)
        CommunityEntry(
          key: key,
          timeS: r.timeS,
          installs: r.installs,
          lastConfirmed: r.lastConfirmed,
          sourceId: r.sourceId,
        ),
    ];
  }

  // ---- queue ----

  /// Adds the items not already queued; returns how many were new.
  Future<int> enqueue(List<QueueItem> items) async {
    final existing = await queue();
    final fresh = newItems(existing, items);
    await _db.batch(
      (b) => b.insertAll(_db.shareQueue, [
        for (final i in fresh)
          ShareQueueCompanion.insert(
            id: i.id,
            sourceId: i.sourceId,
            keyCanonical: i.keyCanonical,
            timeS: i.timeS,
            createdAt: i.createdAt,
          ),
      ]),
    );
    return fresh.length;
  }

  Future<List<QueueItem>> queue() async => sendOrder([
    for (final r in await _db.select(_db.shareQueue).get())
      QueueItem(
        id: r.id,
        sourceId: r.sourceId,
        keyCanonical: r.keyCanonical,
        timeS: r.timeS,
        createdAt: r.createdAt,
        attempts: r.attempts,
      ),
  ]);

  Future<void> dequeue(String id) =>
      (_db.delete(_db.shareQueue)..where((t) => t.id.equals(id))).go();

  Future<void> noteFailure(String id) => _db.customUpdate(
    'UPDATE share_queue SET attempts = attempts + 1 WHERE id = ?',
    variables: [Variable.withString(id)],
    updates: {_db.shareQueue},
  );

  Future<void> clearQueue() => _db.delete(_db.shareQueue).go();

  SourceConfig _source(CommunitySourceRow r) => SourceConfig(
    id: r.id,
    name: r.name,
    kind: SourceKind.values.byName(r.kind),
    url: r.url,
    publicKey: r.publicKey,
    shareTo: r.shareTo,
    position: r.position,
  );
}
