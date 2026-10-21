import 'dart:convert';

import 'package:drktimes/app/app.dart';
import 'package:drktimes/app/providers.dart';
import 'package:drktimes/domain/exchange/codec.dart';
import 'package:drktimes/platform/intake.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/exchange/support.dart';
import '../support/test_app.dart';

void main() {
  testWidgets(
    'an opened file previews, imports, and imports again as up to date',
    (tester) async {
      final env = await TestEnv.create(tester);
      await env.pump(tester);
      final r = sampleRecipe();
      final bytes = utf8.encode(
        ExchangeCodec.encodeString(recipeDoc(r, [sampleNote(r.id)])),
      );
      final app = tester.element(find.byType(DrkApp));
      final live = ProviderScope.containerOf(app).read(routerProvider);

      routeIncoming(live, IncomingFile('x.drktimes', bytes));
      await env.settle(tester);
      expect(find.text('NEW TO YOU'), findsOneWidget);
      await tester.tap(find.byKey(const Key('import-go')));
      await env.settle(tester);
      expect(find.byKey(const Key('import-done')), findsOneWidget);
      expect(find.text('Imported.'), findsOneWidget);

      routeIncoming(live, IncomingFile('x.drktimes', bytes));
      await env.settle(tester);
      expect(find.text('ALREADY UP TO DATE'), findsOneWidget);

      routeIncoming(live, IncomingFile('bad', utf8.encode('nope')));
      await env.settle(tester);
      expect(find.byKey(const Key('import-invalid')), findsOneWidget);
      await env.dispose(tester);
    },
  );
}
