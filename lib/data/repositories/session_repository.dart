import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/process.dart';
import '../../domain/session_meta.dart';
import '../../domain/sessions.dart';
import '../../domain/timeline/session_run.dart';
import '../db/database.dart';

/// Persists every [SessionRun] transition so a session survives the app being
/// killed (FR-003).
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  Future<void> save(SessionRun s) async {
    final key = s.meta.key;
    await _db
        .into(_db.sessions)
        .insertOnConflictUpdate(
          SessionsCompanion.insert(
            id: s.id,
            tankSlot: s.tankSlot,
            tankLabel: s.tankLabel,
            keyCanonical: Value(key?.canonical),
            keyJson: Value(key == null ? null : jsonEncode(key.toJson())),
            timeSourceJson: jsonEncode(s.meta.timeSource),
            devTimeS: s.devTimeS,
            format: s.meta.format,
            volumeMl: s.meta.volumeMl,
            processSnapshotJson: jsonEncode(s.process.toJson()),
            inversionPaceS: s.inversionPaceS,
            status: s.status.name,
            abortedAtStep: Value(s.abortedAtStep),
            startedAt: s.startedAt ?? DateTime.now().toUtc(),
            finishedAt: Value(s.finishedAt),
            stepRunsJson: jsonEncode([for (final r in s.runs) r.toJson()]),
          ),
        );
  }

  /// Rebuilds a coordinator from the sessions still `active`.
  Future<SessionCoordinator> loadActive() async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((t) => t.status.equals('active'))
              ..orderBy([(t) => OrderingTerm.asc(t.tankSlot)]))
            .get();
    return SessionCoordinator([for (final r in rows) _fromRow(r)]);
  }

  /// The latest session (any status) that ran [keyCanonical], for FR-071.
  Future<SessionRun?> latestFor(String keyCanonical) async {
    final row =
        await (_db.select(_db.sessions)
              ..where((t) => t.keyCanonical.equals(keyCanonical))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Finished sessions, newest first (FR-052).
  Future<List<SessionRun>> recent({int limit = 50}) async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((t) => t.status.isIn(['completed', 'aborted']))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(limit))
            .get();
    return [
      for (final r in rows)
        if (r.keyJson != null) _fromRow(r),
    ];
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.sessions)..where((t) => t.id.equals(id))).go();

  SessionRun _fromRow(Session r) {
    final meta = SessionMeta.fromJson({
      if (r.keyJson != null) 'key': jsonDecode(r.keyJson!),
      'time_source': jsonDecode(r.timeSourceJson),
      'format': r.format,
      'volume_ml': r.volumeMl,
    });
    final run =
        SessionRun(
            id: r.id,
            tankSlot: r.tankSlot,
            tankLabel: r.tankLabel,
            process: Process.fromJson(
              jsonDecode(r.processSnapshotJson) as Map<String, dynamic>,
            ),
            devTimeS: r.devTimeS,
            inversionPaceS: r.inversionPaceS,
            startedAt: r.startedAt,
            meta: meta,
          )
          ..status = SessionStatus.values.byName(r.status)
          ..abortedAtStep = r.abortedAtStep
          ..finishedAt = r.finishedAt;
    for (final j in jsonDecode(r.stepRunsJson) as List) {
      run.runs.add(StepRun.fromJson(j as Map<String, dynamic>));
    }
    return run;
  }
}
