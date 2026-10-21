import 'dart:convert';

import '../../domain/process.dart';
import '../db/database.dart';

/// Stored processes. The `default` one is seeded on first launch.
class ProcessRepository {
  ProcessRepository(this._db);

  final AppDatabase _db;

  Future<Process> get(String id) async {
    final row = await (_db.select(
      _db.processes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return Process.defaults();
    return Process.fromJson(jsonDecode(row.json) as Map<String, dynamic>);
  }

  Future<List<Process>> all() async => [
    for (final r in await _db.select(_db.processes).get())
      Process.fromJson(jsonDecode(r.json) as Map<String, dynamic>),
  ];

  Future<void> save(Process p) {
    final problems = p.validate();
    if (problems.isNotEmpty) throw ArgumentError(problems.join('; '));
    return _db
        .into(_db.processes)
        .insertOnConflictUpdate(
          ProcessesCompanion.insert(id: p.id, json: jsonEncode(p.toJson())),
        );
  }

  Future<void> delete(String id) async {
    if (id == Process.defaultId) return;
    await (_db.delete(_db.processes)..where((t) => t.id.equals(id))).go();
  }
}
