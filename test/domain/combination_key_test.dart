import 'package:drktimes/domain/combination_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliseDilution', () {
    test('separators become +', () {
      expect(normaliseDilution('1:50'), '1+50');
      expect(normaliseDilution('1/50'), '1+50');
      expect(normaliseDilution('1 + 50'), '1+50');
    });
    test('stock/working are lower-cased', () {
      expect(normaliseDilution('Stock'), 'stock');
      expect(normaliseDilution('Working'), 'working');
    });
    test('1+1+5 is unchanged', () {
      expect(normaliseDilution('1+1+5'), '1+1+5');
    });
  });

  group('fahrenheitToCelsius', () {
    test('rounds (F - 32) * 5/9', () {
      expect(fahrenheitToCelsius(68), 20);
      expect(fahrenheitToCelsius(70), 21);
      expect(fahrenheitToCelsius(72), 22);
    });
  });

  group('CombinationKey', () {
    const film = FilmRef.catalog('kodak-tri-x-400');
    const dev = DeveloperRef.catalog('rodinal');

    test('canonical string', () {
      final k = CombinationKey(
        film: film,
        developer: dev,
        dilution: '1+50',
        ei: 400,
        tempC: 20,
      );
      expect(
        k.canonical,
        'catalog:kodak-tri-x-400|catalog:rodinal|1+50|400|20',
      );
    });

    test('catalogue and user refs with the same id differ', () {
      final a = CombinationKey(
        film: const FilmRef.catalog('x'),
        developer: dev,
        dilution: 'stock',
        ei: 100,
        tempC: 20,
      );
      final b = CombinationKey(
        film: const FilmRef.user('x'),
        developer: dev,
        dilution: 'stock',
        ei: 100,
        tempC: 20,
      );
      expect(a.canonical, isNot(b.canonical));
      expect(a, isNot(b));
    });

    test('equality and json round trip', () {
      final a = CombinationKey(
        film: film,
        developer: dev,
        dilution: '1+50',
        ei: 400,
        tempC: 20,
      );
      final b = CombinationKey.fromJson(a.toJson());
      expect(b, a);
      expect(b.hashCode, a.hashCode);
      expect(a.toJson()['film'], {'kind': 'catalog', 'id': 'kodak-tri-x-400'});
    });

    test('validates dilution, ei and temperature', () {
      CombinationKey make({String d = '1+50', int ei = 400, int t = 20}) =>
          CombinationKey(
            film: film,
            developer: dev,
            dilution: d,
            ei: ei,
            tempC: t,
          );
      expect(() => make(d: 'abc'), throwsArgumentError);
      expect(() => make(d: '1+'), throwsArgumentError);
      expect(() => make(ei: 0), throwsArgumentError);
      expect(() => make(ei: 25601), throwsArgumentError);
      expect(() => make(t: 9), throwsArgumentError);
      expect(() => make(t: 46), throwsArgumentError);
      expect(make(d: '1+1.5').dilution, '1+1.5');
      expect(make(d: '1+1+5').dilution, '1+1+5');
    });
  });
}
