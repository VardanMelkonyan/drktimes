import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drktimes/app/app.dart';
import 'package:drktimes/app/providers.dart';
import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/session_repository.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/features/session/session_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../platform/fake_cue_scheduler.dart';
import '../platform/fake_foreground_service.dart';
import '../platform/fake_notification_permission.dart';
import '../platform/fake_screen_wake.dart';
import '../platform/fake_volume_keys.dart';

/// Everything a widget test needs: an in-memory database, the real
/// dataset, the fake platform services and a controllable clock.
class TestEnv {
  TestEnv._(this.db, this.catalog, this.clock, this.controller, this.fakes);

  final AppDatabase db;
  final Catalog catalog;
  final FakeClock clock;
  final SessionController controller;
  final TestFakes fakes;
  Settings settings = const Settings();

  static Future<TestEnv> create(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => seedDatabase(db));
    final catalog = Catalog.fromJson(
      jsonDecode(File('assets/devdata.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final clock = FakeClock();
    final fakes = TestFakes();
    final controller = SessionController(
      clock: clock,
      repository: SessionRepository(db),
      settings: SettingsRepository(db),
      scheduler: fakes.scheduler,
      wake: fakes.wake,
      foregroundService: fakes.service,
      volumeKeys: fakes.keys,
      permission: fakes.permission,
      housekeeping: const Duration(days: 1),
    );
    addTearDown(() => tester.runAsync(db.close));
    return TestEnv._(db, catalog, clock, controller, fakes);
  }

  List<Override> get overrides => [
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(clock),
    catalogProvider.overrideWith((ref) async => catalog),
    settingsProvider.overrideWith((ref) => Stream.value(settings)),
    sessionControllerProvider.overrideWith((ref) => controller),
    intakeProvider.overrideWithValue(null),
  ];

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const DrkApp()),
    );
    await settle(tester);
  }

  /// Lets futures and a few frames run without waiting on animations.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }
}

class TestFakes {
  final scheduler = FakeCueScheduler();
  final wake = FakeScreenWake();
  final service = FakeForegroundService();
  final keys = FakeVolumeKeys();
  final permission = FakeNotificationPermission();
}
