import 'package:drktimes/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots', (tester) async {
    await tester.pumpWidget(const DrkApp());
    expect(find.text('drktimes'), findsOneWidget);
  });
}
