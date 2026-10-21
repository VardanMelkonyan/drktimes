import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/session_meta.dart';
import 'package:drktimes/features/session/session_screen.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

Duration s(int n) => Duration(seconds: n);

Future<TestEnv> open(
  WidgetTester tester, {
  int tanks = 1,
  int devS = 60,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await TestEnv.create(tester);
  for (var i = 0; i < tanks; i++) {
    await tester.runAsync(
      () => env.controller.start(
        process: Process.defaults(),
        devTimeS: devS,
        meta: const SessionMeta(),
        autoBegin: false,
      ),
    );
  }
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SessionScreen()),
      GoRoute(path: '/develop', builder: (_, _) => const Text('home')),
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

Future<void> advance(WidgetTester tester, TestEnv env, int secs) async {
  env.clock.advance(s(secs));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> tap(WidgetTester tester, TestEnv env, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await env.settle(tester);
}

void main() {
  testWidgets(
    'ready, agitate, rest, last 10 s, dump & pour, each with its chip',
    (tester) async {
      final env = await open(tester, devS: 300);
      expect(find.byKey(const Key('chip-ready')), findsOneWidget);
      expect(find.textContaining('Pour Developer'), findsOneWidget);
      await tap(tester, env, 'begin');
      expect(find.byKey(const Key('chip-agitate')), findsOneWidget);
      await advance(tester, env, 70);
      expect(find.byKey(const Key('chip-rest')), findsOneWidget);
      await env.dispose(tester);
    },
  );

  testWidgets('time up shows Dump & pour and Next; Next then Undo', (
    tester,
  ) async {
    final env = await open(tester);
    await tap(tester, env, 'begin');
    await advance(tester, env, 65);
    expect(find.byKey(const Key('chip-dumpPour')), findsOneWidget);
    expect(find.textContaining('Dump Developer → pour Stop'), findsOneWidget);
    await tap(tester, env, 'next');
    expect(find.textContaining('Stop'), findsWidgets);
    expect(find.byKey(const Key('undo-toast')), findsOneWidget);
    await tap(tester, env, 'undo');
    expect(find.byKey(const Key('chip-dumpPour')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('last 10 s shows ten pips and the hatched chip', (tester) async {
    final env = await open(tester, devS: 60);
    await tap(tester, env, 'begin');
    await advance(tester, env, 54);
    expect(find.byKey(const Key('chip-final10')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('pause asks first and keeps the time', (tester) async {
    final env = await open(tester);
    await tap(tester, env, 'begin');
    await advance(tester, env, 10);
    await tap(tester, env, 'pause');
    expect(
      find.text('The chemistry keeps working while paused.'),
      findsOneWidget,
    );
    await tap(tester, env, 'confirm-yes');
    expect(find.byKey(const Key('chip-paused')), findsOneWidget);
    await advance(tester, env, 300);
    expect(find.byKey(const Key('chip-paused')), findsOneWidget);
    await tap(tester, env, 'resume');
    expect(find.byKey(const Key('chip-agitate')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('two tanks: the one waiting leads and Next names its tank', (
    tester,
  ) async {
    final env = await open(tester, tanks: 2, devS: 60);
    await tap(tester, env, 'begin');
    await advance(tester, env, 30);
    // Start the second tank 30 s later.
    await tester.runAsync(() => env.controller.begin(env.controller.active[1]));
    await advance(tester, env, 35); // tank 1 is done, tank 2 still runs
    expect(find.byKey(const Key('next')), findsOneWidget);
    expect(find.text('NEXT · TANK 1'), findsOneWidget);
    expect(find.byKey(const Key('tank-2')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('abort asks first and ends the run', (tester) async {
    final env = await open(tester);
    await tap(tester, env, 'begin');
    await tap(tester, env, 'abort');
    await tap(tester, env, 'confirm-yes');
    expect(env.controller.active, isEmpty);
    expect(find.byKey(const Key('done-title')), findsOneWidget);
    await env.dispose(tester);
  });
}
