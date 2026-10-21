import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/session_repository.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/session_meta.dart';
import 'package:drktimes/domain/sessions.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:drktimes/features/session/session_controller.dart';
import 'package:drktimes/platform/notification_permission.dart';
import 'package:drktimes/platform/volume_keys.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../platform/fake_cue_scheduler.dart';
import '../../platform/fake_foreground_service.dart';
import '../../platform/fake_notification_permission.dart';
import '../../platform/fake_screen_wake.dart';
import '../../platform/fake_volume_keys.dart';

Duration s(int n) => Duration(seconds: n);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeClock clock;
  late FakeCueScheduler scheduler;
  late FakeScreenWake wake;
  late FakeForegroundService service;
  late FakeVolumeKeys keys;
  late FakeNotificationPermission permission;
  late SettingsRepository settings;
  late SessionRepository repo;
  late SessionController c;

  SessionController build() => SessionController(
    clock: clock,
    repository: repo,
    settings: settings,
    scheduler: scheduler,
    wake: wake,
    foregroundService: service,
    volumeKeys: keys,
    permission: permission,
    housekeeping: const Duration(days: 1), // drive tick() by hand
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedDatabase(db);
    clock = FakeClock();
    scheduler = FakeCueScheduler();
    wake = FakeScreenWake();
    service = FakeForegroundService();
    keys = FakeVolumeKeys();
    permission = FakeNotificationPermission();
    settings = SettingsRepository(db);
    repo = SessionRepository(db);
    c = build()..attach();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<SessionRun> go({int devS = 60}) => c.start(
    process: Process.defaults(),
    devTimeS: devS,
    meta: const SessionMeta(),
  );

  test(
    'first start asks for notification permission before the timer',
    () async {
      await go();
      expect(permission.requests, 1);
      expect((await settings.get()).notificationsAsked, isTrue);
      await c.abort(c.active.first);
      await go();
      expect(permission.requests, 1, reason: 'asked once');
    },
  );

  test('wake, service and cues follow the session lifecycle', () async {
    final run = await go();
    expect(wake.held, isTrue);
    expect(service.running, isTrue);
    expect(scheduler.foreground, isNotEmpty);
    expect(c.active, [run]);

    await c.abort(run);
    expect(wake.held, isFalse);
    expect(service.running, isFalse);
    expect(scheduler.foreground, isEmpty);
    expect(c.active, isEmpty);
    expect(c.finished.single, run);
  });

  test(
    'wake and service stay while a tank is left, stop with the last',
    () async {
      final a = await go();
      final b = await go();
      expect(b.tankSlot, 2);
      await c.abort(a);
      expect(wake.held, isTrue);
      expect(service.running, isTrue);
      await c.abort(b);
      expect(wake.held, isFalse);
    },
  );

  test('volume keys are armed only while a tank awaits Next', () async {
    final run = await go(devS: 60);
    await c.tick();
    expect(keys.armed, isFalse);
    clock.advance(s(61));
    await c.tick();
    expect(keys.armed, isTrue);
    keys.emit(VolumeKey.up);
    await Future<void>.delayed(Duration.zero);
    expect(run.stateAt(clock.now()).stepIndex, 1);
    expect(keys.armed, isFalse, reason: 'disarmed once Next was taken');
  });

  test('volume_key_next off never arms', () async {
    await settings.update(volumeKeyNext: false);
    await go(devS: 60);
    clock.advance(s(61));
    await c.tick();
    expect(keys.armed, isFalse);
  });

  test('denied permission: session still runs, banner flag set', () async {
    permission.grantOnRequest = false;
    final run = await go();
    expect(c.backgroundCuesOff, isTrue);
    expect(run.stateAt(clock.now()).phase, SessionPhase.agitate);
    expect(wake.held, isTrue);
  });

  test('restore rebuilds active sessions from storage', () async {
    final run = await go();
    clock.advance(s(20));
    final c2 = build()..attach();
    addTearDown(c2.dispose);
    await c2.restore();
    expect(c2.active.single.id, run.id);
    expect(c2.active.single.stateAt(clock.now()).remaining, s(40));
    expect(wake.held, isTrue);
    expect(service.running, isTrue);
  });

  test('undo and pause go through persistence', () async {
    final run = await go(devS: 60);
    clock.advance(s(10));
    await c.pause(run);
    expect(run.stateAt(clock.now()).phase, SessionPhase.paused);
    await c.resume(run);
    final saved = (await repo.loadActive()).active.single;
    expect(saved.runs.first.pauses.single.to, isNotNull);
  });

  test('the iOS notice shows once, after going to background', () async {
    final ios = SessionController(
      clock: clock,
      repository: repo,
      settings: settings,
      scheduler: scheduler,
      wake: wake,
      foregroundService: service,
      volumeKeys: keys,
      permission: permission,
      isIos: true,
      housekeeping: const Duration(days: 1),
    );
    addTearDown(ios.dispose);
    await ios.start(process: Process.defaults(), devTimeS: 60);
    ios.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ios.showBackgroundNotice, isTrue);
    await ios.acknowledgeBackgroundNotice();
    expect(ios.showBackgroundNotice, isFalse);
    ios.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ios.showBackgroundNotice, isFalse);
    expect(permission.state, PermissionState.granted);
  });

  test('tank limit surfaces as an exception', () async {
    await go();
    await go();
    await go();
    expect(go, throwsA(isA<TankLimitReached>()));
  });
}
