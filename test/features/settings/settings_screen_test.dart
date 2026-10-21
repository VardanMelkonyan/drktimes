import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

Future<TestEnv> open(WidgetTester tester, {bool keys = true}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await TestEnv.create(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => SettingsScreen(showVolumeKeys: keys),
      ),
      GoRoute(path: '/process/edit', builder: (_, _) => const Text('editor')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: MaterialApp.router(theme: darkTheme, routerConfig: router),
    ),
  );
  await env.settle(tester);
  return env;
}

Future<Settings> read(WidgetTester tester, TestEnv env) async =>
    (await tester.runAsync(() => SettingsRepository(env.db).get()))!;

void main() {
  testWidgets('volume steppers write the tank volumes', (tester) async {
    final env = await open(tester);
    final plus35 = find.descendant(
      of: find.byKey(const Key('vol-35')),
      matching: find.text('+'),
    );
    await tester.ensureVisible(plus35);
    await tester.tap(plus35);
    await env.settle(tester);
    expect((await read(tester, env)).volume35mmMl, 350);
    final minus120 = find.descendant(
      of: find.byKey(const Key('vol-120')),
      matching: find.text('−'),
    );
    await tester.ensureVisible(minus120);
    await tester.tap(minus120);
    await env.settle(tester);
    expect((await read(tester, env)).volume120Ml, 450);
    await env.dispose(tester);
  });

  testWidgets('units, sound and theme', (tester) async {
    final env = await open(tester);
    await tester.ensureVisible(find.text('°F'));
    await tester.tap(find.text('°F'));
    await env.settle(tester);
    expect((await read(tester, env)).tempUnit, TempUnit.f);

    final sw = find.byKey(const Key('sound-switch'));
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await env.settle(tester);
    expect((await read(tester, env)).soundOn, isFalse);

    await tester.ensureVisible(find.text('DARK'));
    await tester.tap(find.text('DARK'));
    await env.settle(tester);
    expect((await read(tester, env)).theme, ThemeSetting.dark);
    await env.dispose(tester);
  });

  testWidgets('inversion pace steps by half a second', (tester) async {
    final env = await open(tester);
    final slower = find.descendant(
      of: find.byKey(const Key('pace')),
      matching: find.text('−'),
    );
    await tester.ensureVisible(slower);
    await tester.tap(slower);
    await env.settle(tester);
    expect((await read(tester, env)).inversionPaceS, 2.5);
    await env.dispose(tester);
  });

  testWidgets('the volume-button row is Android only', (tester) async {
    var env = await open(tester, keys: false);
    expect(find.byKey(const Key('volume-keys-switch')), findsNothing);
    await env.dispose(tester);
    env = await open(tester, keys: true);
    expect(find.byKey(const Key('volume-keys-switch')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('there is no safelight theme in Part 1', (tester) async {
    final env = await open(tester);
    expect(find.text('SAFELIGHT'), findsNothing);
    await env.dispose(tester);
  });
}
