import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/process.dart';
import 'database.dart';

/// First-launch seeding: the `default` process and the settings row.
/// Safe to run on every launch.
Future<void> seedDatabase(AppDatabase db) async {
  await db.transaction(() async {
    await db.into(db.processes).insert(
          ProcessesCompanion.insert(
            id: Process.defaultId,
            json: jsonEncode(Process.defaults().toJson()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await db
        .into(db.settingsRows)
        .insert(SettingsRowsCompanion(), mode: InsertMode.insertOrIgnore);
  });
}
