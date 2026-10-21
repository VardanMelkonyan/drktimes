import 'package:drktimes/domain/summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('needs two or more times', () {
    expect(summarise([]), isNull);
    expect(summarise([540]), isNull);
  });

  test('count, median rounded to 15 s, range', () {
    final s = summarise([540, 600, 480])!;
    expect(s.count, 3);
    expect(s.medianS, 540);
    expect(s.minS, 480);
    expect(s.maxS, 600);
  });

  test('even count averages the middle pair and rounds to 15 s', () {
    expect(summarise([480, 600])!.medianS, 540);
    expect(summarise([480, 590])!.medianS, 540); // 535 → 540
    expect(summarise([500, 520])!.medianS, 510); // 510
  });

  test('input order does not matter', () {
    expect(summarise([900, 100, 500])!.medianS, 495); // 500 rounds to 495
  });
}
