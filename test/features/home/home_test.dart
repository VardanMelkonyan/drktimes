import 'package:drktimes/app/providers.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/session_meta.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final hp5 = CombinationKey(
  film: const FilmRef.catalog('ilford-hp5-plus'),
  developer: const DeveloperRef.catalog('ilford-ilfotec-dd-x'),
  dilution: '1+4',
  ei: 800,
  tempC: 20,
);

void main() {
  testWidgets('Favourites lists starred combinations with their time', (
    tester,
  ) async {
    final env = await TestEnv.create(tester);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(favouritesRepositoryProvider).add(hp5));
    await env.pump(tester);
    expect(find.text('1 starred'.toUpperCase()), findsOneWidget);
    expect(find.text('Ilford HP5 Plus'), findsOneWidget);
    expect(find.textContaining('ISO 800 push +1'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget); // ISO 800 at 20 °C
    await env.dispose(tester);
  });

  testWidgets('Recent lists finished and aborted runs, newest first', (
    tester,
  ) async {
    final env = await TestEnv.create(tester);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);
    await tester.runAsync(() async {
      final repo = c.read(sessionRepositoryProvider);
      final coordinator = c.read(sessionControllerProvider).coordinator;
      final a = coordinator.create(
        process: Process.defaults(),
        devTimeS: 600,
        inversionPaceS: 2,
        meta: SessionMeta(key: hp5),
      )..start(env.clock.now());
      a.abort(env.clock.now().add(const Duration(minutes: 5)));
      await repo.save(a);
    });
    await env.pump(tester);
    await tester.tap(find.text('RECENT'));
    await env.settle(tester);
    expect(find.text('Ilford HP5 Plus'), findsOneWidget);
    expect(find.textContaining('Aborted at Developer'), findsOneWidget);
    expect(find.text('RUN AGAIN'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('empty Recent has a hint', (tester) async {
    final env = await TestEnv.create(tester);
    await env.pump(tester);
    await tester.tap(find.text('RECENT'));
    await env.settle(tester);
    expect(find.byKey(const Key('empty-recent')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('Search finds films with forgiving spelling', (tester) async {
    final env = await TestEnv.create(tester);
    await env.pump(tester);
    await tester.tap(find.text('SEARCH'));
    await env.settle(tester);
    await tester.enterText(find.byKey(const Key('home-search')), 'trix');
    await env.settle(tester);
    expect(
      find.byKey(const Key('result-film-kodak-tri-x-400')),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('home-search')), 'rodinal');
    await env.settle(tester);
    expect(find.byKey(const Key('result-dev-rodinal')), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('a running session shows a banner back to it', (tester) async {
    final env = await TestEnv.create(tester);
    await tester.runAsync(
      () => env.controller.start(
        process: Process.defaults(),
        devTimeS: 60,
        meta: const SessionMeta(),
      ),
    );
    await env.pump(tester);
    expect(find.byKey(const Key('active-1')), findsOneWidget);
    expect(find.textContaining('Agitate · Developer'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('the last mode is remembered', (tester) async {
    final env = await TestEnv.create(tester);
    await env.pump(tester);
    await tester.tap(find.text('PRINT'));
    await env.settle(tester);
    final s = await tester.runAsync(() => SettingsRepository(env.db).get());
    expect(s!.lastMode, AppMode.print);
    await env.dispose(tester);
  });
}
