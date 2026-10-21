import 'package:drift/drift.dart';

import '../db/database.dart';

enum TempUnit { c, f }

enum ThemeSetting { system, dark, light }

enum AppMode { develop, print }

enum FilmFormat {
  mm35('35mm'),
  mm120('120');

  const FilmFormat(this.db);
  final String db;
  static FilmFormat parse(String s) => values.firstWhere((v) => v.db == s);
}

/// Typed view of the single settings row (data-model.md "Settings").
class Settings {
  const Settings({
    this.authorName = '',
    this.volume35mmMl = 300,
    this.volume120Ml = 500,
    this.defaultProcessId = 'default',
    this.inversionPaceS = 2.0,
    this.soundOn = true,
    this.volume = 0.7,
    this.volumeKeyNext = true,
    this.tempUnit = TempUnit.c,
    this.theme = ThemeSetting.system,
    this.lastMode = AppMode.develop,
    this.backgroundLimitSeen = false,
    this.notificationsAsked = false,
    this.lastFormat = FilmFormat.mm35,
  });

  final String authorName;
  final int volume35mmMl, volume120Ml;
  final String defaultProcessId;
  final double inversionPaceS, volume;
  final bool soundOn, volumeKeyNext, backgroundLimitSeen, notificationsAsked;
  final TempUnit tempUnit;
  final ThemeSetting theme;
  final AppMode lastMode;
  final FilmFormat lastFormat;

  int volumeMlFor(FilmFormat f) =>
      f == FilmFormat.mm35 ? volume35mmMl : volume120Ml;
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$SettingsRowsTable, SettingsRow> get _row =>
      _db.select(_db.settingsRows)..where((t) => t.id.equals(1));

  Future<Settings> get() async {
    final r = await _row.getSingleOrNull();
    return r == null ? const Settings() : _map(r);
  }

  Stream<Settings> watch() => _row.watchSingleOrNull().map(
    (r) => r == null ? const Settings() : _map(r),
  );

  /// Writes only the fields that are passed.
  Future<void> update({
    String? authorName,
    int? volume35mmMl,
    int? volume120Ml,
    String? defaultProcessId,
    double? inversionPaceS,
    bool? soundOn,
    double? volume,
    bool? volumeKeyNext,
    TempUnit? tempUnit,
    ThemeSetting? theme,
    AppMode? lastMode,
    bool? backgroundLimitSeen,
    bool? notificationsAsked,
    FilmFormat? lastFormat,
  }) async {
    final c = SettingsRowsCompanion(
      authorName: Value.absentIfNull(authorName),
      volume35mmMl: Value.absentIfNull(volume35mmMl),
      volume120Ml: Value.absentIfNull(volume120Ml),
      defaultProcessId: Value.absentIfNull(defaultProcessId),
      inversionPaceS: Value.absentIfNull(inversionPaceS),
      soundOn: Value.absentIfNull(soundOn),
      volume: Value.absentIfNull(volume),
      volumeKeyNext: Value.absentIfNull(volumeKeyNext),
      tempUnit: Value.absentIfNull(tempUnit?.name),
      theme: Value.absentIfNull(theme?.name),
      lastMode: Value.absentIfNull(lastMode?.name),
      backgroundLimitSeen: Value.absentIfNull(backgroundLimitSeen),
      notificationsAsked: Value.absentIfNull(notificationsAsked),
      lastFormat: Value.absentIfNull(lastFormat?.db),
    );
    await (_db.update(_db.settingsRows)..where((t) => t.id.equals(1))).write(c);
  }

  Settings _map(SettingsRow r) => Settings(
    authorName: r.authorName,
    volume35mmMl: r.volume35mmMl,
    volume120Ml: r.volume120Ml,
    defaultProcessId: r.defaultProcessId,
    inversionPaceS: r.inversionPaceS,
    soundOn: r.soundOn,
    volume: r.volume,
    volumeKeyNext: r.volumeKeyNext,
    tempUnit: TempUnit.values.byName(r.tempUnit),
    theme: ThemeSetting.values.byName(r.theme),
    lastMode: AppMode.values.byName(r.lastMode),
    backgroundLimitSeen: r.backgroundLimitSeen,
    notificationsAsked: r.notificationsAsked,
    lastFormat: FilmFormat.parse(r.lastFormat),
  );
}
