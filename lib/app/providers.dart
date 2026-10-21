import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dataset/catalog.dart';
import '../data/db/database.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/clock.dart';

/// Every provider here throws or has a real default and can be overridden in
/// tests with `ProviderScope(overrides: [...])`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final settingsProvider = StreamProvider<Settings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final catalogProvider = FutureProvider<Catalog>(
  (ref) => Catalog.load(rootBundle),
);
