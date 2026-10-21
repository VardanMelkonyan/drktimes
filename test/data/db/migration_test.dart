import 'dart:convert';

import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/process.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memory() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  setUp(() => db = memory());
  tearDown(() => db.close());

  test('schema v1 seeds the default process and settings', () async {
    await seedDatabase(db);
    final p = await (db.select(db.processes)
          ..where((t) => t.id.equals('default')))
        .getSingle();
    expect(Process.fromJson(jsonDecode(p.json) as Map<String, dynamic>).toJson(),
        Process.defaults().toJson());
  });

  test('seeding twice is a no-op', () async {
    await seedDatabase(db);
    await SettingsRepository(db).update(authorName: 'Me');
    await seedDatabase(db);
    expect((await SettingsRepository(db).get()).authorName, 'Me');
    expect(await db.select(db.processes).get(), hasLength(1));
  });

  test('settings defaults', () async {
    await seedDatabase(db);
    final s = await SettingsRepository(db).get();
    expect(s.authorName, '');
    expect(s.volume35mmMl, 300);
    expect(s.volume120Ml, 500);
    expect(s.inversionPaceS, 2.0);
    expect(s.soundOn, isTrue);
    expect(s.volume, 0.7);
    expect(s.volumeKeyNext, isTrue);
    expect(s.tempUnit, TempUnit.c);
    expect(s.theme, ThemeSetting.system);
    expect(s.lastMode, AppMode.develop);
    expect(s.backgroundLimitSeen, isFalse);
    expect(s.notificationsAsked, isFalse);
    expect(s.lastFormat, FilmFormat.mm35);
    expect(s.defaultProcessId, 'default');
  });

  test('settings update and watch', () async {
    await seedDatabase(db);
    final repo = SettingsRepository(db);
    final next = expectLater(
        repo.watch().map((s) => s.tempUnit), emitsThrough(TempUnit.f));
    await repo.update(tempUnit: TempUnit.f, lastFormat: FilmFormat.mm120);
    await next;
    final s = await repo.get();
    expect(s.lastFormat, FilmFormat.mm120);
    expect(s.soundOn, isTrue, reason: 'untouched fields keep their value');
  });

  test('check constraints hold', () async {
    await seedDatabase(db);
    expect(
        () => db.into(db.userFilms).insert(UserFilmsCompanion.insert(
            id: 'a',
            brand: 'B',
            name: 'N',
            boxIso: 0,
            createdAt: DateTime.utc(2026))),
        throwsA(anything));
  });
}
