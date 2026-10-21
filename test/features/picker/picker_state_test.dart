import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/features/picker/picker_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selections build a key and later steps reset on change', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(pickerProvider.notifier);
    n.pickFilm(const FilmRef.catalog('f'));
    n.pickDeveloper(const DeveloperRef.catalog('d'));
    n.pickEi(400);
    expect(c.read(pickerProvider).key, isNull);
    n.pickDilution('1+50', tempC: 21);
    final key = c.read(pickerProvider).key!;
    expect(key.canonical, 'catalog:f|catalog:d|1+50|400|21');
    n.startFrom(const FilmRef.catalog('g'));
    expect(c.read(pickerProvider).developer, isNull);
    expect(c.read(pickerProvider).key, isNull);
  });

  test('a developer from search survives picking the film', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(pickerProvider.notifier);
    n.startWithDeveloper(const DeveloperRef.catalog('rodinal'));
    n.pickFilm(const FilmRef.catalog('f'));
    expect(
      c.read(pickerProvider).developer,
      const DeveloperRef.catalog('rodinal'),
    );
  });

  test('combo path round-trips a key', () {
    final key = CombinationKey(
      film: const FilmRef.user('u-1'),
      developer: const DeveloperRef.catalog('rodinal'),
      dilution: '1+50',
      ei: 800,
      tempC: 22,
    );
    expect(comboKeyFromParam(comboPath(key).substring('/combo/'.length)), key);
  });
}
