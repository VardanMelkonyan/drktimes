import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('boots into the Develop home and switches modes', (tester) async {
    final env = await TestEnv.create(tester);
    await env.pump(tester);
    expect(find.byKey(const Key('empty-favourites')), findsOneWidget);
    expect(find.text('PRINT'), findsNothing, reason: 'modes live in Settings');

    await tester.tap(find.byKey(const Key('settings-button')));
    await env.settle(tester);
    await tester.tap(find.text('PRINT'));
    await env.settle(tester);
    expect(find.text('BACK TO DEVELOP'), findsOneWidget);
    await tester.tap(find.text('BACK TO DEVELOP'));
    await env.settle(tester);
    expect(find.byKey(const Key('empty-favourites')), findsOneWidget);
    await env.dispose(tester);
  });
}
