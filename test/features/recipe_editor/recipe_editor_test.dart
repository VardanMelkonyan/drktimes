import 'package:drktimes/app/providers.dart';
import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:drktimes/features/recipe_editor/recipe_editor_args.dart';
import 'package:drktimes/features/recipe_editor/recipe_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

final key400 = CombinationKey(
  film: const FilmRef.catalog('kodak-tri-x-400'),
  developer: const DeveloperRef.catalog('rodinal'),
  dilution: '1+50',
  ei: 400,
  tempC: 20,
);

Future<TestEnv> open(WidgetTester tester, RecipeEditorArgs args) async {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await TestEnv.create(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => RecipeEditorScreen(args: args),
      ),
      GoRoute(path: '/combo/:key', builder: (_, _) => const Text('combo')),
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

RecipeEditorArgs datasheetArgs({RecipeOrigin? origin, int tempC = 20}) =>
    RecipeEditorArgs(
      key: CombinationKey(
        film: key400.film,
        developer: key400.developer,
        dilution: '1+50',
        ei: 400,
        tempC: tempC,
      ),
      devTimeS: 780,
      agitation: const Intermittent(initialS: 60, everyS: 60, burstS: 10),
      origin: origin ?? const DatasheetOrigin('kodak-f4017-2021-10', page: 3),
      baseLabel: 'Kodak F-4017 datasheet · 13:00',
    );

Future<List<Recipe>> saved(WidgetTester tester, TestEnv env) async {
  final c = ProviderContainer(overrides: env.overrides);
  addTearDown(c.dispose);
  return (await tester.runAsync(() => c.read(recipeRepositoryProvider).all()))!;
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
}

void main() {
  testWidgets('validation messages', (tester) async {
    final env = await open(tester, datasheetArgs());
    await enter(tester, 'editor-dilution', 'abc');
    await tester.tap(find.byKey(const Key('editor-save')));
    await env.settle(tester);
    expect(find.text('Use 1+N, 1+A+B, stock or working.'), findsOneWidget);

    await enter(tester, 'editor-dilution', '1:50');
    await enter(tester, 'editor-iso', '0');
    await tester.tap(find.byKey(const Key('editor-save')));
    await env.settle(tester);
    expect(find.text('ISO must be from 1 to 25600.'), findsOneWidget);
    expect(await saved(tester, env), isEmpty);
    await env.dispose(tester);
  });

  testWidgets('EI 800 on a 400 film is labelled push +1', (tester) async {
    final env = await open(tester, datasheetArgs());
    expect(find.byKey(const Key('push-pull')), findsNothing);
    await enter(tester, 'editor-iso', '800');
    await env.settle(tester);
    expect(find.text('push +1'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('saving from a datasheet baseline sets the origin', (
    tester,
  ) async {
    final env = await open(tester, datasheetArgs());
    expect(
      find.textContaining('Based on Kodak F-4017 datasheet'),
      findsOneWidget,
    );
    final plus = find.byKey(const Key('time-plus'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await env.settle(tester);
    await tester.tap(find.byKey(const Key('editor-save')));
    await env.settle(tester);
    final r = (await saved(tester, env)).single;
    expect(r.ownership, Ownership.own);
    expect(r.devTimeS, 795);
    expect(r.origin, isA<DatasheetOrigin>());
    expect((r.origin as DatasheetOrigin).sourceId, 'kodak-f4017-2021-10');
    expect(r.version, 1);
    await env.dispose(tester);
  });

  testWidgets('saving from a temperature estimate keeps the new temperature '
      'and points the origin at the base source', (tester) async {
    final args = RecipeEditorArgs(
      key: CombinationKey(
        film: key400.film,
        developer: key400.developer,
        dilution: '1+50',
        ei: 400,
        tempC: 22,
      ),
      devTimeS: 660,
      agitation: const Intermittent(initialS: 60, everyS: 60, burstS: 10),
      origin: const EstimateOrigin(
        DatasheetOrigin('kodak-f4017-2021-10', page: 3),
      ),
      baseLabel:
          'Estimated for 22 °C from Kodak F-4017 datasheet · 13:00 at 20 °C',
    );
    final env = await open(tester, args);
    expect(find.textContaining('Estimated for 22 °C'), findsOneWidget);
    await tester.tap(find.byKey(const Key('editor-save')));
    await env.settle(tester);
    final r = (await saved(tester, env)).single;
    expect(r.key.tempC, 22);
    expect(r.devTimeS, 660);
    expect(r.ownership, Ownership.own);
    final origin = r.origin as EstimateOrigin;
    expect((origin.base as DatasheetOrigin).sourceId, 'kodak-f4017-2021-10');
    await env.dispose(tester);
  });

  testWidgets('a note can be added once the recipe exists', (tester) async {
    final env = await open(tester, datasheetArgs());
    await enter(tester, 'editor-note', 'Dense highlights');
    await tester.ensureVisible(find.byKey(const Key('editor-add-note')));
    await tester.tap(find.byKey(const Key('editor-add-note')));
    await env.settle(tester);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);
    final recipes = await saved(tester, env);
    expect(recipes, hasLength(1));
    final notes = await tester.runAsync(
      () => c.read(noteRepositoryProvider).forRecipe(recipes.single.id),
    );
    expect(notes!.single.text, 'Dense highlights');
    await env.dispose(tester);
  });
}
