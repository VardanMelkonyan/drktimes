import 'dart:io';

import 'package:drktimes/devdata/loader.dart';
import 'package:drktimes/devdata/models.dart';
import 'package:drktimes/devdata/validator.dart';
import 'package:flutter_test/flutter_test.dart';

final data = loadDataset(Directory('resources/devdata'));

int timeFor(String source, String film, String dev, String dil, num ei,
        num tempC, String method) =>
    data.times
        .singleWhere((DevTime t) =>
            t.sourceId == source &&
            t.filmId == film &&
            t.developerId == dev &&
            t.dilution == dil &&
            t.ei == ei &&
            t.tempC == tempC &&
            t.method == method)
        .timeS;

void main() {
  test('committed dataset passes validation', () {
    expect(validate(data), isEmpty);
  });

  test('loader rejects a times file whose source_id does not match its name',
      () {
    final dir = Directory.systemTemp.createTempSync('devdata');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final f in ['films', 'developers', 'sources']) {
      File('${dir.path}/$f.json')
          .writeAsStringSync('{"schema_version": 1, "$f": []}');
    }
    Directory('${dir.path}/times').createSync();
    File('${dir.path}/times/a.json').writeAsStringSync(
        '{"schema_version": 1, "source_id": "b", "times": []}');
    expect(() => loadDataset(dir), throwsFormatException);
  });

  group('spot checks: kodak-f4017-2021-10 page 3 (Tri-X 400)', () {
    const s = 'kodak-f4017-2021-10', f = 'kodak-tri-x-400';
    test('D-76 stock 20C small tank = 6 3/4 min', () {
      expect(timeFor(s, f, 'kodak-d-76', 'stock', 400, 20, 'small_tank'), 405);
    });
    test('HC-110 B 20C small tank = 3 3/4 min', () {
      expect(timeFor(s, f, 'kodak-hc-110', '1+31', 400, 20, 'small_tank'), 225);
    });
    test('XTOL 1+1 24C large tank = 8 1/4 min', () {
      expect(timeFor(s, f, 'kodak-xtol', '1+1', 400, 24, 'large_tank'), 495);
    });
  });
}
