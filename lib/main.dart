import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'data/db/database.dart';
import 'data/db/seed.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  await seedDatabase(db);

  // Where to open: a running session wins, then the last mode (FR-002/003).
  final hasActive = (await SessionRepository(
    db,
  ).loadActive()).active.isNotEmpty;
  final settings = await SettingsRepository(db).get();
  final initial = hasActive
      ? '/session'
      : settings.lastMode == AppMode.print
      ? '/print'
      : '/develop';

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      routerProvider.overrideWithValue(buildRouter(initialLocation: initial)),
    ],
  );
  await container.read(sessionControllerProvider).restore();
  runApp(
    UncontrolledProviderScope(container: container, child: const DrkApp()),
  );
}
