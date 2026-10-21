import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/dataset/catalog.dart';
import '../data/dataset/picker_queries.dart';
import '../data/dataset/search_items.dart';
import '../data/db/database.dart';
import '../data/repositories/combination_repository.dart';
import '../data/repositories/favourites_repository.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/process_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_catalog_repository.dart';
import '../domain/clock.dart';
import '../domain/combination_key.dart';
import '../domain/process.dart';
import '../domain/search.dart';
import '../features/session/session_controller.dart';
import '../platform/cues/cue_scheduler.dart';
import '../platform/cues/platform_cue_scheduler.dart';
import '../platform/foreground_service.dart';
import '../platform/notification_permission.dart';
import '../platform/volume_keys.dart';
import '../platform/wake.dart';

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

// ------------------------------------------------------------------ data

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) =>
      RecipeRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) =>
      NoteRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

final userCatalogRepositoryProvider = Provider<UserCatalogRepository>(
  (ref) => UserCatalogRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  ),
);

/// Bumped whenever recipes, notes, favourites or user entries change, so
/// screens that read them once can refresh.
final dataVersionProvider = StateProvider<int>((ref) => 0);

final combinationRepositoryProvider = FutureProvider<CombinationRepository>((
  ref,
) async {
  ref.watch(dataVersionProvider);
  return CombinationRepository(
    catalog: await ref.watch(catalogProvider.future),
    recipes: ref.watch(recipeRepositoryProvider),
    notes: ref.watch(noteRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    userCatalog: ref.watch(userCatalogRepositoryProvider),
  );
});

final searchIndexProvider = FutureProvider<SearchIndex>((ref) async {
  ref.watch(dataVersionProvider);
  final catalog = await ref.watch(catalogProvider.future);
  final user = await ref.watch(userCatalogRepositoryProvider).searchItems();
  Map<String, List<String>> synonyms = {};
  try {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/search_synonyms.json'),
    ) as Map<String, dynamic>;
    synonyms = {
      for (final e in raw.entries)
        if (e.value is List) e.key: List<String>.from(e.value as List),
    };
  } catch (_) {}
  return SearchIndex([...searchItemsFor(catalog), ...user], synonyms: synonyms);
});

// -------------------------------------------------------------- platform

final screenWakeProvider = Provider<ScreenWake>(
  (ref) => WakelockPlusScreenWake(),
);

final foregroundServiceProvider = Provider<SessionForegroundService>(
  (ref) => createForegroundService(),
);

final volumeKeysProvider = Provider<VolumeKeys>((ref) => createVolumeKeys());

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => PluginNotificationPermission(FlutterLocalNotificationsPlugin()),
);

final Provider<CueScheduler> cueSchedulerProvider = Provider<CueScheduler>((
  ref,
) {
  final settings = ref.read(settingsRepositoryProvider);
  var cached = const Settings();
  settings.watch().listen((s) => cached = s);
  return PlatformCueScheduler(
    clock: ref.watch(clockProvider),
    soundOn: () => cached.soundOn,
    volume: () => cached.volume,
    upcoming: () => ref
        .read(sessionControllerProvider)
        .coordinator
        .upcomingCues(
          ref.read(clockProvider).now(),
          const Duration(minutes: 40),
          limit: 600,
        ),
    backgroundAllowed: () =>
        !ref.read(sessionControllerProvider).backgroundCuesOff,
  );
});

final sessionControllerProvider = ChangeNotifierProvider<SessionController>((
  ref,
) {
  final c = SessionController.platform(
    clock: ref.watch(clockProvider),
    repository: ref.watch(sessionRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(cueSchedulerProvider),
    wake: ref.watch(screenWakeProvider),
    foregroundService: ref.watch(foregroundServiceProvider),
    volumeKeys: ref.watch(volumeKeysProvider),
    permission: ref.watch(notificationPermissionProvider),
  )..attach();
  return c;
});

final pickerQueriesProvider = FutureProvider<PickerQueries>((ref) async {
  ref.watch(dataVersionProvider);
  final catalog = await ref.watch(catalogProvider.future);
  final user = ref.watch(userCatalogRepositoryProvider);
  return PickerQueries(
    catalog: catalog,
    recipes: await ref.watch(recipeRepositoryProvider).all(),
    userFilms: await user.films(),
    userDevelopers: await user.developers(),
  );
});

final processRepositoryProvider = Provider<ProcessRepository>(
  (ref) => ProcessRepository(ref.watch(databaseProvider)),
);

final combinationViewProvider =
    FutureProvider.family<CombinationView, CombinationKey>((ref, key) async {
      ref.watch(dataVersionProvider);
      final repo = await ref.watch(combinationRepositoryProvider.future);
      return repo.load(key);
    });

/// The process new sessions start with.
final defaultProcessProvider = FutureProvider<Process>((ref) async {
  final s = await ref.watch(settingsRepositoryProvider).get();
  return ref.watch(processRepositoryProvider).get(s.defaultProcessId);
});

final favouritesRepositoryProvider = Provider<FavouritesRepository>(
  (ref) => FavouritesRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  ),
);
