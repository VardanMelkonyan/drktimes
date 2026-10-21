import 'package:drktimes/domain/temperature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('13:00 at 20 °C to 22 °C', () {
    // 780 · e^(−0.081·2) = 663.3 s → 660 s
    expect(estimateTimeS(780, fromC: 20, toC: 22), 660);
  });

  test('colder is longer', () {
    // 780 · e^(0.162) = 917.4 s → 915 s
    expect(estimateTimeS(780, fromC: 20, toC: 18), 915);
  });

  test('same temperature returns the time rounded to 15 s', () {
    expect(estimateTimeS(780, fromC: 20, toC: 20), 780);
    expect(estimateTimeS(790, fromC: 20, toC: 20), 795);
  });

  test('no estimate outside 18–26 °C', () {
    expect(estimateTimeS(780, fromC: 20, toC: 17), isNull);
    expect(estimateTimeS(780, fromC: 20, toC: 27), isNull);
    expect(estimateTimeS(780, fromC: 16, toC: 20), isNull);
    expect(estimateTimeS(780, fromC: 18, toC: 26), isNotNull);
  });

  test('result never drops below 15 s', () {
    expect(estimateTimeS(15, fromC: 18, toC: 26), 15);
  });

  test('citation constant', () {
    expect(
      temperatureEstimateCitation,
      contains("Ilford's published time/temperature compensation chart"),
    );
  });
}
