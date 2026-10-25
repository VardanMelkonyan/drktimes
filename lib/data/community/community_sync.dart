import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../domain/clock.dart';
import '../../domain/combination_key.dart';
import '../../domain/community/eligibility.dart';
import '../../domain/community/share_queue.dart';
import '../../domain/community/submission.dart';
import '../db/database.dart';
import '../repositories/settings_repository.dart';
import 'community_repository.dart';
import 'community_source.dart';
import 'static_feed_source.dart';
import 'supabase_source.dart';

const refreshInterval = Duration(hours: 24);

typedef SourceFactory = CommunitySource Function(SourceConfig);

CommunitySource Function(SourceConfig) httpSources(http.Client client) =>
    (c) => switch (c.kind) {
      SourceKind.static => StaticFeedSource(
        id: c.id,
        name: c.name,
        url: c.url,
        client: client,
      ),
      SourceKind.supabase => SupabaseSource(
        id: c.id,
        name: c.name,
        url: c.url,
        publicKey: c.publicKey ?? '',
        client: client,
      ),
    };

/// Glue between sessions, the queue, the sources and the cache (spec 002).
/// Every network failure is silent: sharing and reading never block or
/// interrupt a session or a lookup.
class CommunitySync {
  CommunitySync({
    required this.db,
    required this.repo,
    required this.settings,
    required this.clock,
    required this.sourceFor,
  });

  final AppDatabase db;
  final CommunityRepository repo;
  final SettingsRepository settings;
  final Clock clock;
  final SourceFactory sourceFor;

  bool _flushing = false;

  // ---- sharing ----

  Future<void> onShareSwitchedOn() async {
    await settings.update(shareTimes: true);
    if ((await settings.get()).contributionId == null) {
      await settings.setContributionId(const Uuid().v4());
    }
    final after = (await settings.get()).sharedUpTo;
    await _queueCompleted(after: after);
    await flush();
  }

  /// Nothing queued is sent after this; what was already sent stays sent.
  Future<void> onShareSwitchedOff() async {
    await settings.update(shareTimes: false);
    await repo.clearQueue();
  }

  /// A new ID is created at the next submission (FR-007a).
  Future<void> resetContributionId() => settings.setContributionId(null);

  Future<void> onSessionCompleted(String sessionId) async {
    if (!(await settings.get()).shareTimes) return;
    await _queueCompleted(sessionId: sessionId);
    await flush();
  }

  /// Sends the queue in order. Stops quietly at the first transient failure.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final s = await settings.get();
      if (!s.shareTimes) return;
      var id = s.contributionId;
      if (id == null) {
        id = const Uuid().v4();
        await settings.setContributionId(id);
      }
      final configs = {for (final c in await repo.sources()) c.id: c};
      for (final item in await repo.queue()) {
        final cfg = configs[item.sourceId];
        final sub = Submission.fromCanonical(item.keyCanonical, item.timeS);
        if (cfg == null || !cfg.shareTo || sub == null) {
          await repo.dequeue(item.id);
          continue;
        }
        final source = sourceFor(cfg);
        if (!source.canSubmit) {
          await repo.dequeue(item.id);
          continue;
        }
        try {
          await source.submit(sub, id);
          await repo.dequeue(item.id);
        } on SubmitInvalid {
          await repo.dequeue(item.id);
        } on Exception {
          await repo.noteFailure(item.id);
          return;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// Queues eligible completed sessions (one [sessionId], or all finished
  /// after [after]) for every source that takes submissions.
  Future<void> _queueCompleted({String? sessionId, DateTime? after}) async {
    final targets = [
      for (final c in await repo.sources())
        if (c.shareTo && c.kind == SourceKind.supabase) c,
    ];
    final q = db.select(db.sessions)
      ..where((t) => t.status.equals('completed'))
      ..orderBy([(t) => OrderingTerm.asc(t.finishedAt)]);
    if (sessionId != null) q.where((t) => t.id.equals(sessionId));
    if (after != null) {
      q.where((t) => t.finishedAt.isBiggerThanValue(after));
    }
    final rows = await q.get();
    if (rows.isEmpty) return;
    final own = {
      for (final r in await (db.select(
        db.recipes,
      )..where((t) => t.ownership.equals('own'))).get())
        r.id,
    };
    final items = <QueueItem>[];
    DateTime? newest;
    for (final r in rows) {
      final finished = r.finishedAt;
      if (finished != null && (newest == null || finished.isAfter(newest))) {
        newest = finished;
      }
      final sub = eligibleSubmission(
        status: r.status,
        timeSource: jsonDecode(r.timeSourceJson) as Map<String, dynamic>,
        devTimeS: r.devTimeS,
        key: r.keyJson == null
            ? null
            : CombinationKey.fromJson(
                jsonDecode(r.keyJson!) as Map<String, dynamic>,
              ),
        isOwnRecipe: own.contains,
      );
      if (sub == null) continue;
      final canonical = CombinationKey.fromJson(
        jsonDecode(r.keyJson!) as Map<String, dynamic>,
      ).canonical;
      for (final t in targets) {
        items.add(
          QueueItem(
            id: const Uuid().v4(),
            sourceId: t.id,
            keyCanonical: canonical,
            timeS: sub.timeS,
            createdAt: clock.now(),
          ),
        );
      }
    }
    await repo.enqueue(items);
    final prev = (await settings.get()).sharedUpTo;
    if (newest != null && (prev == null || newest.isAfter(prev))) {
      await settings.setSharedUpTo(newest);
    }
  }

  // ---- sources ----

  /// Checks that [url] (with [publicKey] for a Supabase project) is
  /// reachable and returns a valid feed, then saves it. Returns a one-line
  /// reason when it cannot be saved, null on success (FR-014, US4).
  Future<String?> addSource({
    required String name,
    required String url,
    String? publicKey,
  }) async {
    final n = name.trim();
    final u = url.trim();
    final k = (publicKey ?? '').trim();
    if (n.isEmpty || n.length > 60) return 'Give it a name of 1–60 characters.';
    final uri = Uri.tryParse(u);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'The address must start with https://';
    }
    final cfg = SourceConfig(
      id: const Uuid().v4(),
      name: n,
      kind: k.isEmpty ? SourceKind.static : SourceKind.supabase,
      url: u,
      publicKey: k.isEmpty ? null : k,
    );
    try {
      final feed = await sourceFor(cfg).fetchFeed();
      await repo.addSource(cfg);
      await repo.replaceEntries(cfg.id, feed.entries, clock.now());
      return null;
    } on FormatException {
      return 'That address does not return a drktimes community feed.';
    } on Exception {
      return 'Could not reach that address.';
    }
  }

  // ---- reading ----

  /// Refreshes each source whose cache is older than 24 h (or [force]).
  /// A failure keeps the old cache. Returns true when any cache changed.
  Future<bool> refreshStale({bool force = false}) async {
    var changed = false;
    for (final c in await repo.sources()) {
      final at = await repo.fetchedAt(c.id);
      if (!force &&
          at != null &&
          clock.now().difference(at) < refreshInterval) {
        continue;
      }
      try {
        final feed = await sourceFor(c).fetchFeed();
        await repo.replaceEntries(c.id, feed.entries, clock.now());
        changed = true;
      } on Exception {
        // keep the old cache; the next open or lookup tries again
      }
    }
    return changed;
  }
}
