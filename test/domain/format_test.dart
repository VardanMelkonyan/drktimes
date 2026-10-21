import 'package:drktimes/domain/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatTime', () {
    expect(formatTime(780), '13:00');
    expect(formatTime(405), '6:45');
    expect(formatTime(0), '0:00');
    expect(formatTime(3600), '1:00:00');
    expect(formatTime(3725), '1:02:05');
  });

  test('parseTime', () {
    expect(parseTime('13:00'), 780);
    expect(parseTime('1:30:00'), 5400);
    expect(parseTime('90'), 90);
    expect(parseTime(''), isNull);
    expect(parseTime('a:b'), isNull);
    expect(parseTime('-1:00'), isNull);
  });

  test('formatTemp', () {
    expect(formatTemp(20), '20 °C');
    expect(formatTemp(20, fahrenheit: true), '68 °F');
  });

  test('pushPullLabel', () {
    expect(pushPullLabel(400, 400), isNull);
    expect(pushPullLabel(800, 400), 'push +1');
    expect(pushPullLabel(1600, 400), 'push +2');
    expect(pushPullLabel(3200, 400), 'push +3');
    expect(pushPullLabel(200, 400), 'pull −1');
    expect(pushPullLabel(640, 400), 'push +0.5');
  });
}
