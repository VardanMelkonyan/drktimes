import 'package:drift/native.dart';
import 'package:drktimes/app/app.dart';
import 'package:drktimes/app/providers.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/settings_repository.dart';
import 'package:flutter/widgets.dart' show Key, SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the Develop home and switches modes', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => seedDatabase(db));
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const Settings()),
          ),
        ],
        child: const DrkApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('empty-favourites')), findsOneWidget);
    expect(find.text('PRINT'), findsOneWidget);

    await tester.tap(find.text('PRINT'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('BACK TO DEVELOP'), findsOneWidget);
    await tester.tap(find.text('BACK TO DEVELOP'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('empty-favourites')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
