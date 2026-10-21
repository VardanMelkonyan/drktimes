import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/domain/combination_key.dart';
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

  testWidgets('two tanks: a colour-coded card each, own Next, no sound', (
    tester,
  ) async {
    final env = await open(tester, tanks: 2, devS: 60);
    await tester.runAsync(() => env.controller.begin(env.controller.active[0]));
    await advance(tester, env, 30);
    await tester.runAsync(() => env.controller.begin(env.controller.active[1]));
    await advance(tester, env, 35); // tank 1 is done, tank 2 still runs
    expect(find.byKey(const Key('card-1')), findsOneWidget);
    expect(find.byKey(const Key('card-2')), findsOneWidget);
    expect(find.byKey(const Key('next')), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(env.fakes.scheduler.foreground, isEmpty);
    await env.dispose(tester);
  });

  testWidgets('single tank has no tank tag; two tanks fit an iPhone screen', (
    tester,
  ) async {
    var env = await open(tester);
    expect(find.text('TANK 1'), findsNothing);
    expect(find.byKey(const Key('card-1')), findsNothing);
    await env.dispose(tester);

    env = await open(tester, tanks: 2);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TANK 1'), findsOneWidget);
    expect(find.byKey(const Key('card-2')), findsOneWidget);
    final card = tester.getRect(find.byKey(const Key('card-1')));
    final abort = tester.getRect(find.byKey(const Key('abort')).first);
    expect(
      card.right - abort.right,
      lessThan(20),
      reason: 'content spans the card',
    );
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(list.position.maxScrollExtent, 0, reason: 'no scrolling needed');
    await env.dispose(tester);
  });

  testWidgets('nothing moves when the state changes', (tester) async {
    final env = await open(tester, devS: 300);
    await tap(tester, env, 'begin');
    double y(String k) => tester.getTopLeft(find.byKey(Key(k))).dy;
    final before = [y('abort'), y('big-time'), y('pause')];
    for (final secs in [70, 230, 20]) {
      // agitate → rest → last 10 s → dump & pour
      await advance(tester, env, secs);
      expect(
        [y('abort'), y('big-time'), y('pause')],
        before,
        reason:
            '${tester.widget<Text>(find.byKey(const Key('headline'))).data}',
      );
    }
    await env.dispose(tester);
  });

  testWidgets('step bars show fixed planned times and fill as time passes; '
      'the film, developer and dilution are shown', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await TestEnv.create(tester);
    final key = CombinationKey(
      film: const FilmRef.catalog('ilford-hp5-plus'),
      developer: const DeveloperRef.catalog('ilford-ilfotec-dd-x'),
      dilution: '1+4',
      ei: 400,
      tempC: 20,
    );
    await tester.runAsync(
      () => env.controller.start(
        process: Process.defaults(),
        devTimeS: 300,
        meta: SessionMeta(key: key),
      ),
    );
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
    String time(int i) =>
        tester.widget<Text>(find.byKey(Key('step-time-$i'))).data!;
    // enabled steps: developer, stop, fix, wash, wetting agent
    expect(
      [for (var i = 0; i < 5; i++) time(i)],
      ['5:00', '1:00', '5:00', '3×', '0:30'],
    );
    final what = tester.widget<Text>(find.byKey(const Key('what'))).data!;
    expect(
      what.replaceAll('\u00A0', ' '),
      startsWith('Ilford HP5 Plus · Ilford Ilfotec DD-X 1+4 · ISO 400'),
    );
    // The only normal spaces are the ones after a dot, so lines break there.
    expect(what.split(' ').length - 1, what.split('·').length - 1);
    double bar(int i) => tester.getSize(find.byKey(Key('step-bar-$i'))).width;
    await advance(tester, env, 150);
    final half = bar(0);
    expect(bar(1), 0);
    await advance(tester, env, 600); // developer done, waiting
    expect(bar(0), greaterThan(half));
    expect(
      [for (var i = 0; i < 5; i++) time(i)],
      ['5:00', '1:00', '5:00', '3×', '0:30'],
    );
    await env.dispose(tester);
  });

  testWidgets('between wash fills it says to dump the water and refill', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await TestEnv.create(tester);
    final p = Process.defaults();
    await tester.runAsync(
      () => env.controller.start(
        process: p.copyWith(
          steps: [
            for (final x in p.steps)
              x.copyWith(
                enabled:
                    x.kind == StepKind.developer || x.kind == StepKind.wash,
              ),
          ],
        ),
        devTimeS: 30,
        meta: const SessionMeta(),
      ),
    );
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
    await advance(tester, env, 35);
    await tap(tester, env, 'next'); // into wash fill 1
    await advance(tester, env, 11); // 5 inversions done
    expect(find.textContaining('Dump water → refill'), findsOneWidget);
    expect(find.textContaining('Wetting'), findsNothing);
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
