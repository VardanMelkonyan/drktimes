// ignore_for_file: recursive_getters  (drift check-constraint idiom)

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../community/default_source.dart';

part 'database.g.dart';

@DataClassName('UserFilmRow')
class UserFilms extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text().withLength(min: 1, max: 60)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get boxIso => integer().check(boxIso.isBetweenValues(1, 25600))();
  TextColumn get matchedCatalogId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserDeveloperRow')
class UserDevelopers extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text().withLength(min: 1, max: 60)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get matchedCatalogId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'recipes_key', columns: {#keyCanonical})
@DataClassName('RecipeRow')
class Recipes extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer().check(version.isBiggerOrEqualValue(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get authorName => text()();
  TextColumn get ownership =>
      text().check(ownership.isIn(['own', 'received']))();
  TextColumn get originJson => text()();
  DateTimeColumn get importedAt => dateTime().nullable()();
  TextColumn get keyCanonical => text()();
  TextColumn get keyJson => text()();
  IntColumn get devTimeS =>
      integer().check(devTimeS.isBetweenValues(30, 7200))();
  TextColumn get devAgitationJson => text()();
  TextColumn get processJson => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text().references(Recipes, #id)();
  TextColumn get authorName => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get text_ => text().named('text').withLength(min: 1, max: 4000)();

  @override
  Set<Column> get primaryKey => {id};
}

class Processes extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  IntColumn get tankSlot => integer().check(tankSlot.isBetweenValues(1, 3))();
  TextColumn get tankLabel => text()();
  TextColumn get keyCanonical => text().nullable()();
  TextColumn get keyJson => text().nullable()();
  TextColumn get timeSourceJson => text()();
  IntColumn get devTimeS => integer()();
  TextColumn get format => text().check(format.isIn(['35mm', '120']))();
  IntColumn get volumeMl => integer()();
  TextColumn get processSnapshotJson => text()();
  RealColumn get inversionPaceS => real()();
  TextColumn get status =>
      text().check(status.isIn(['active', 'completed', 'aborted']))();
  IntColumn get abortedAtStep => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get stepRunsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Favourites extends Table {
  TextColumn get keyCanonical => text()();
  TextColumn get keyJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {keyCanonical};
}

/// One row (id = 1) holding every field of data-model.md "Settings".
class SettingsRows extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get authorName => text().withDefault(const Constant(''))();
  IntColumn get volume35mmMl => integer().withDefault(const Constant(300))();
  IntColumn get volume120Ml => integer().withDefault(const Constant(500))();
  TextColumn get defaultProcessId =>
      text().withDefault(const Constant('default'))();
  RealColumn get inversionPaceS => real().withDefault(const Constant(2.0))();
  BoolColumn get soundOn => boolean().withDefault(const Constant(true))();
  RealColumn get volume => real().withDefault(const Constant(0.7))();
  BoolColumn get volumeKeyNext => boolean().withDefault(const Constant(true))();
  TextColumn get tempUnit => text().withDefault(const Constant('c'))();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  TextColumn get lastMode => text().withDefault(const Constant('develop'))();
  BoolColumn get backgroundLimitSeen =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationsAsked =>
      boolean().withDefault(const Constant(false))();
  TextColumn get lastFormat => text().withDefault(const Constant('35mm'))();
  BoolColumn get shareTimes => boolean().withDefault(const Constant(false))();
  TextColumn get contributionId => text().nullable()();
  DateTimeColumn get sharedUpTo => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Community times (spec 002): stored apart from datasheet data, recipes and
/// sessions, and never part of backup or the exchange format.
@DataClassName('CommunitySourceRow')
class CommunitySources extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get kind => text().check(kind.isIn(['static', 'supabase']))();
  TextColumn get url => text()();
  TextColumn get publicKey => text().nullable()();
  BoolColumn get shareTo => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'community_entries_key', columns: {#keyCanonical})
@DataClassName('CommunityEntryRow')
class CommunityEntries extends Table {
  TextColumn get sourceId => text().references(CommunitySources, #id)();
  TextColumn get keyCanonical => text()();
  IntColumn get timeS => integer()();
  IntColumn get installs => integer().check(installs.isBiggerOrEqualValue(2))();
  DateTimeColumn get lastConfirmed => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId, keyCanonical, timeS};
}

class CommunityFetches extends Table {
  TextColumn get sourceId => text().references(CommunitySources, #id)();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceId};
}

@TableIndex(
  name: 'share_queue_unique',
  columns: {#sourceId, #keyCanonical, #timeS},
  unique: true,
)
class ShareQueue extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().references(CommunitySources, #id)();
  TextColumn get keyCanonical => text()();
  IntColumn get timeS => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class DatasetStates extends Table {
  @override
  String get tableName => 'dataset_state';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get activeVersion => text()();
  TextColumn get activeSha256 => text()();
  TextColumn get source =>
      text().check(source.isIn(['bundled', 'downloaded']))();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    UserFilms,
    UserDevelopers,
    Recipes,
    Notes,
    Processes,
    Sessions,
    Favourites,
    SettingsRows,
    DatasetStates,
    CommunitySources,
    CommunityEntries,
    CommunityFetches,
    ShareQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-disk database in the app support directory.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'drktimes'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // The default source is seeded once, when the schema is first created or
    // first reaches v2, so removing it sticks (FR-014).
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultSource();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(settingsRows, settingsRows.shareTimes);
        await m.addColumn(settingsRows, settingsRows.contributionId);
        await m.addColumn(settingsRows, settingsRows.sharedUpTo);
        await m.createTable(communitySources);
        await m.createTable(communityEntries);
        await m.createTable(communityFetches);
        await m.createTable(shareQueue);
        await m.createIndex(communityEntriesKey);
        await m.createIndex(shareQueueUnique);
        await _seedDefaultSource();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedDefaultSource() async {
    if (!hasDefaultSource) return;
    await into(communitySources).insert(
      CommunitySourcesCompanion.insert(
        id: kDefaultSourceId,
        name: kDefaultSourceName,
        kind: 'supabase',
        url: kDefaultSourceUrl,
        publicKey: const Value(kDefaultSourceKey),
        shareTo: const Value(true),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
