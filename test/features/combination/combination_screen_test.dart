import 'package:drktimes/app/providers.dart';
import 'package:drktimes/data/community/community_repository.dart';
import 'package:drktimes/domain/community/community_feed.dart';
import 'package:drktimes/features/recipe_editor/recipe_editor_args.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:drktimes/features/combination/combination_screen.dart';
import 'package:drktimes/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

CombinationKey key({
  String film = 'ilford-hp5-plus',
  String dev = 'ilford-ilfotec-dd-x',
  String dil = '1+4',
  int ei = 400,
  int t = 20,
}) => CombinationKey(
  film: FilmRef.catalog(film),
  developer: DeveloperRef.catalog(dev),
  dilution: dil,
  ei: ei,
  tempC: t,
);

Future<TestEnv> open(
  WidgetTester tester,
  CombinationKey k, {
  Settings? settings,
  Future<void> Function(TestEnv)? seed,
}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await TestEnv.create(tester);
  if (settings != null) env.settings = settings;
  if (seed != null) await tester.runAsync(() => seed(env));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => CombinationScreen(comboKey: k),
      ),
      GoRoute(path: '/session', builder: (_, _) => const Text('session')),
      GoRoute(path: '/pick/developer', builder: (_, _) => const Text('pick')),
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

void main() {
  testWidgets(
    'flow A: HP5 · DD-X 1+4 · 400 · 20 °C shows 9:00 and its source',
    (tester) async {
      final env = await open(tester, key());
      expect(find.text('Ilford HP5 Plus'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('time-to-use'))).data,
        '9:00',
      );
      expect(
        find.textContaining('Datasheet · Harman Technology'),
        findsWidgets,
      );
      await env.dispose(tester);
    },
  );

  testWidgets('chemistry follows the format toggle (35mm 300 ml)', (
    tester,
  ) async {
    final env = await open(
      tester,
      key(dev: 'rodinal', dil: '1+50', film: 'bergger-pancro-400'),
    );
    // 1+50 at 300 ml
    expect(find.text('5.9'), findsOneWidget);
    expect(find.text('294.1'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('120 format uses 500 ml', (tester) async {
    final env = await open(
      tester,
      key(dev: 'rodinal', dil: '1+50', film: 'bergger-pancro-400'),
      settings: const Settings(lastFormat: FilmFormat.mm120),
    );
    expect(find.text('9.8'), findsOneWidget);
    expect(find.text('490.2'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('SC-013: datasheet, own and received share one row widget and '
      'are labelled differently', (tester) async {
    final k = key();
    final env = await open(
      tester,
      k,
      seed: (env) async {
        final recipes = (await _repos(env)).$1;
        final own = await recipes.create(
          key: k,
          devTimeS: 570,
          devAgitation: const Continuous(),
          origin: const ScratchOrigin(),
          authorName: 'Me',
        );
        await recipes.receive(
          own.copyWith(
            id: 'r-ani',
            ownership: Ownership.received,
            authorName: 'Ani M.',
            devTimeS: 600,
          ),
        );
      },
    );
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('time-row-'),
    );
    final n = rows.evaluate().length;
    expect(n, greaterThanOrEqualTo(3));
    // Datasheet rows say Datasheet; own says Your recipe; received the sharer.
    expect(find.text('Datasheet'), findsWidgets);
    expect(find.text('Your recipe'), findsOneWidget);
    expect(find.text('Ani M.'), findsOneWidget);
    // Order: datasheet first, own, then received.
    final order = <String>[];
    for (var i = 0; i < n; i++) {
      final row = find.byKey(Key('time-row-$i'));
      final texts = [
        for (final t
            in find.descendant(of: row, matching: find.byType(Text)).evaluate())
          (t.widget as Text).data ?? '',
      ];
      order.add(
        texts.contains('Your recipe')
            ? 'own'
            : texts.contains('Ani M.')
            ? 'received'
            : 'datasheet',
      );
    }
    expect(order.first, 'datasheet');
    expect(order.sublist(order.length - 2), ['own', 'received']);
    await env.dispose(tester);
  });

  testWidgets('the estimate appears only within 18–26 °C', (tester) async {
    final env = await open(tester, key());
    expect(find.byKey(const Key('estimate-citation')), findsNothing);
    Future<void> warmer() async {
      final plus = find.descendant(
        of: find.byKey(const Key('water-temp')),
        matching: find.text('+'),
      );
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await env.settle(tester);
    }

    await warmer(); // 21 °C
    expect(find.byKey(const Key('estimate-citation')), findsOneWidget);
    expect(find.textContaining('≈'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await warmer(); // up to 27 °C
    }
    expect(find.byKey(const Key('estimate-citation')), findsNothing);
    await env.dispose(tester);
  });

  testWidgets('a combination with nothing shows the empty state', (
    tester,
  ) async {
    final env = await open(tester, key(film: 'kodak-tri-x-400', ei: 12800));
    expect(find.byKey(const Key('no-published-time')), findsOneWidget);
    expect(find.byKey(const Key('add-yours')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('a rebrand shows where its times were inherited from', (
    tester,
  ) async {
    final env = await open(
      tester,
      key(
        film: 'arista-edu-ultra-100',
        dev: 'adox-fx-39-ii',
        dil: '1+9',
        ei: 100,
      ),
    );
    expect(find.textContaining('Inherited from'), findsWidgets);
    expect(
      find.textContaining('rebrand reported, not confirmed'),
      findsWidgets,
    );
    await env.dispose(tester);
  });

  testWidgets('Start opens a session with this combination and time', (
    tester,
  ) async {
    final env = await open(tester, key());
    await tester.ensureVisible(find.byKey(const Key('start')));
    await tester.tap(find.byKey(const Key('start')));
    await env.settle(tester);
    expect(env.controller.active, hasLength(1));
    final run = env.controller.active.single;
    expect(run.devTimeS, 540);
    expect(run.meta.key, key());
    expect(run.meta.timeSource['kind'], 'datasheet');
    await env.dispose(tester);
  });

  group('community times', () {
    Future<void> seedCommunity(TestEnv env) async {
      final repo = CommunityRepository(env.db);
      await repo.addSource(
        const SourceConfig(
          id: 'c1',
          name: 'Darkroom Club',
          kind: SourceKind.static,
          url: 'u',
        ),
      );
      await repo.replaceEntries('c1', [
        CommunityEntry(
          key: key(),
          timeS: 570,
          installs: 3,
          lastConfirmed: DateTime.utc(2026, 10),
        ),
      ], DateTime.now());
    }

    testWidgets('shown after datasheet times, labelled with source and count', (
      tester,
    ) async {
      final env = await open(tester, key(), seed: seedCommunity);
      expect(find.text('Community'), findsWidgets);
      expect(find.textContaining('Darkroom Club'), findsOneWidget);
      expect(find.textContaining('3 installs'), findsOneWidget);
      final datasheetY = tester
          .getTopLeft(find.byKey(const Key('time-row-0')))
          .dy;
      final communityY = tester
          .getTopLeft(find.textContaining('3 installs'))
          .dy;
      expect(datasheetY, lessThan(communityY));
      // The datasheet time is still the one preselected.
      expect(
        tester.widget<Text>(find.byKey(const Key('time-to-use'))).data,
        '9:00',
      );
      await env.dispose(tester);
    });

    testWidgets('a community time can be customised into an own recipe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final env = await TestEnv.create(tester);
      await tester.runAsync(() => seedCommunity(env));
      RecipeEditorArgs? got;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => CombinationScreen(comboKey: key()),
          ),
          GoRoute(
            path: '/recipe/edit',
            builder: (_, state) {
              got = state.extra as RecipeEditorArgs;
              return const Text('editor');
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: MaterialApp.router(theme: darkTheme, routerConfig: router),
        ),
      );
      await env.settle(tester);
      final row = find.textContaining('3 installs');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await env.settle(tester);
      final customise = find.byKey(const Key('customise'));
      await tester.ensureVisible(customise);
      await tester.tap(customise);
      await env.settle(tester);
      expect(got!.devTimeS, 570);
      expect(got!.baseLabel, contains('Darkroom Club'));
      await env.dispose(tester);
    });
  });
}

Future<(dynamic, dynamic)> _repos(TestEnv env) async {
  final container = ProviderContainer(overrides: env.overrides);
  addTearDown(container.dispose);
  return (
    container.read(recipeRepositoryProvider),
    container.read(noteRepositoryProvider),
  );
}
