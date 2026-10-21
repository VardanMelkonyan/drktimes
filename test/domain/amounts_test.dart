import 'package:drktimes/domain/amounts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rodinal 1+50', () {
    final a300 = amountsFor('1+50', 300);
    expect(a300.solutionsMl, [5.9]);
    expect(a300.waterMl, 294.1);
    final a500 = amountsFor('1+50', 500);
    expect(a500.solutionsMl, [9.8]);
    expect(a500.waterMl, 490.2);
  });

  test('1+1+5 at 300 ml', () {
    final a = amountsFor('1+1+5', 300);
    expect(a.solutionsMl, [42.9, 42.9]);
    expect(a.waterMl, 214.3);
  });

  test('stock and working are the whole volume with no water', () {
    for (final d in ['stock', 'working']) {
      final a = amountsFor(d, 300);
      expect(a.solutionsMl, [300.0]);
      expect(a.waterMl, 0);
    }
  });

  test('1+4 and decimals', () {
    expect(amountsFor('1+4', 300).solutionsMl, [60.0]);
    expect(amountsFor('1+4', 300).waterMl, 240.0);
    expect(amountsFor('1+1.5', 250).solutionsMl, [100.0]);
  });

  test('describe', () {
    expect(amountsFor('1+50', 300).describe(), '5.9 ml + 294.1 ml water');
    expect(
      amountsFor('1+1+5', 300).describe(),
      '42.9 ml + 42.9 ml + 214.3 ml water',
    );
    expect(amountsFor('stock', 300).describe(), '300 ml');
  });

  test('rejects nonsense', () {
    expect(() => amountsFor('1+', 300), throwsFormatException);
  });
}
