import 'package:drktimes/app/providers.dart';
import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/data/community/community_repository.dart';
import 'package:drktimes/data/community/community_sync.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:drktimes/features/community_sources/community_sources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/community/fake_community_source.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets('add a feed, see it listed, remove it', (tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await TestEnv.create(tester);
    final fake = FakeCommunitySource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides,
          communitySyncProvider.overrideWithValue(
            CommunitySync(
              db: env.db,
              repo: CommunityRepository(env.db),
              settings: SettingsRepository(env.db),
              clock: env.clock,
              sourceFor: (_) => fake,
            ),
          ),
          communitySourcesProvider.overrideWith(
            (ref) => CommunityRepository(env.db).watchSources(),
          ),
        ],
        child: MaterialApp(
          theme: darkTheme,
          home: const CommunitySourcesScreen(),
        ),
      ),
    );
    await env.settle(tester);
    expect(find.byKey(const Key('no-sources')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('source-name')), 'Club');
    await tester.enterText(
      find.byKey(const Key('source-url')),
      'http://nope.test',
    );
    await tester.tap(find.byKey(const Key('add-source')));
    await env.settle(tester);
    expect(find.byKey(const Key('source-error')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('source-url')),
      'https://club.test/feed.json',
    );
    await tester.tap(find.byKey(const Key('add-source')));
    await env.settle(tester);
    expect(find.byKey(const Key('source-error')), findsNothing);
    expect(find.text('Club'), findsOneWidget);
    expect(find.byKey(const Key('no-sources')), findsNothing);

    final remove = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'remove-"),
    );
    await tester.tap(remove);
    await env.settle(tester);
    await tester.tap(find.byKey(const Key('confirm-remove')));
    await env.settle(tester);
    expect(find.byKey(const Key('no-sources')), findsOneWidget);
    await env.dispose(tester);
  });
}
