// ignore_for_file: recursive_getters  (drift check-constraint idiom)

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

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
class Recipes extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer().check(version.isBiggerOrEqualValue(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get authorName => text()();
  TextColumn get ownership =>
      text().check(ownership.isIn(['own', 'received']))();
  TextColumn get originJson => text()();
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
  TextColumn get keyCanonical => text()();
  TextColumn get keyJson => text()();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-disk database in the app support directory.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'drktimes'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
