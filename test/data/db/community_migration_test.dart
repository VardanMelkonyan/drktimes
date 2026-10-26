import 'dart:io';

import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a v1 database upgrades to v2 with its data intact', () async {
    final dir = Directory.systemTemp.createTempSync('drk_mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // Build a v1 file: current schema minus everything v2 added.
    var db = AppDatabase(NativeDatabase(file));
    await db.customStatement('SELECT 1');
    await db.customInsert(
      "INSERT INTO settings (id, author_name) VALUES (1, 'Me')",
    );
    await db
        .into(db.favourites)
        .insert(
          FavouritesCompanion.insert(
            keyCanonical: 'k',
            keyJson: '{}',
            createdAt: DateTime.utc(2026),
          ),
        );
    for (final t in [
      'share_queue',
      'community_fetches',
      'community_entries',
      'community_sources',
    ]) {
      await db.customStatement('DROP TABLE $t');
    }
    for (final c in ['share_times', 'contribution_id', 'shared_up_to']) {
      await db.customStatement('ALTER TABLE settings DROP COLUMN $c');
    }
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final s = await SettingsRepository(db).get();
    expect(s.authorName, 'Me');
    expect(s.shareTimes, isFalse);
    expect(s.contributionId, isNull);
    expect(s.sharedUpTo, isNull);
    expect(await db.select(db.favourites).get(), hasLength(1));
    expect(await db.select(db.communitySources).get(), isEmpty);
    expect(await db.select(db.shareQueue).get(), isEmpty);
  });
}
