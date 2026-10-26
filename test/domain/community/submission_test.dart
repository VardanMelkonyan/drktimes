import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/community/submission.dart';
import 'package:flutter_test/flutter_test.dart';

CombinationKey key({bool userFilm = false, bool userDev = false}) =>
    CombinationKey(
      film: userFilm ? const FilmRef.user('f') : const FilmRef.catalog('tri-x'),
      developer: userDev
          ? const DeveloperRef.user('d')
          : const DeveloperRef.catalog('d76'),
      dilution: '1:1',
      ei: 400,
      tempC: 20,
    );

void main() {
  test('the map has exactly the FR-004 fields', () {
    final s = Submission.from(key(), 540)!;
    expect(s.toJson(), {
      'film_id': 'tri-x',
      'developer_id': 'd76',
      'dilution': '1+1',
      'ei': 400,
      'temp_c': 20,
      'time_s': 540,
    });
  });

  test('user-added films, developers and implausible times are refused', () {
    expect(Submission.from(key(userFilm: true), 540), isNull);
    expect(Submission.from(key(userDev: true), 540), isNull);
    expect(Submission.from(key(), 29), isNull);
    expect(Submission.from(key(), 10801), isNull);
    expect(Submission.from(key(), 30), isNotNull);
    expect(Submission.from(key(), 10800), isNotNull);
  });
}
