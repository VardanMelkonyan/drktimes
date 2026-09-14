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

  // Each value was read off the source page text by the reviewer, not the transcriber.
  const checks = <(String, String, String, String, num, num, String, int)>[
    ('kodak-h-1-5222', 'kodak-eastman-double-x', 'kodak-d-96', 'working', 250, 21, 'other', 420),
    ('kodak-f4017-2021-10', 'kodak-tri-x-400', 'kodak-d-76', '1+1', 3200, 18, 'rotary', 1050),
    ('kodak-f4017-2021-10', 'kodak-tri-x-400', 'kodak-t-max-rs', 'working', 1600, 20, 'rotary', 465),
    ('kodak-edbwf', 'kodak-ektapan-100', 'kodak-d-76', 'stock', 100, 20, 'tray', 345),
    ('ilford-ilfotec-dd-x-2019-08', 'ilford-delta-400', 'ilford-ilfotec-dd-x', '1+4', 500, 24, 'small_tank', 420),
    ('ilford-ilfotec-dd-x-2019-08', 'ilford-delta-400', 'ilford-ilfotec-dd-x', '1+4', 400, 20, 'small_tank', 480),
    ('ilford-hp5-plus-2018-11', 'ilford-hp5-plus', 'ilford-ilfosol-3', '1+14', 400, 20, 'small_tank', 660),
    ('ilford-hp5-plus-2018-11', 'ilford-hp5-plus', 'ilford-ilfotec-hc', '1+31', 400, 20, 'small_tank', 390),
    ('bergger-pancro-400-2017-01', 'bergger-pancro-400', 'bergger-ber49', '1+1', 400, 21, 'small_tank', 1290),
    ('foma-fomapan-400-fomafoto', 'foma-fomapan-400', 'foma-fomadon-lqn', '1+10', 400, 30, 'small_tank', 240),
    ('fujifilm-acros-ii-135', 'fujifilm-acros-ii', 'kodak-d-76', 'stock', 200, 20, 'small_tank', 600),
    ('fujifilm-acros-ii-135', 'fujifilm-acros-ii', 'kodak-d-76', '1+1', 100, 22, 'small_tank', 525),
    ('fujifilm-acros-ii-120', 'fujifilm-acros-ii', 'kodak-d-76', 'stock', 100, 18, 'small_tank', 510),
    ('ferrania-p30-best-practices-v3', 'ferrania-p30', 'kodak-d-76', 'stock', 50, 20, 'small_tank', 480),
    ('rollei-rpx-100-2021', 'rollei-rpx-100', 'rollei-rls', '1+4', 100, 24, 'small_tank', 960),
    ('rollei-rpx-100-2021', 'rollei-rpx-100', 'rodinal', '1+50', 100, 20, 'small_tank', 960),
    ('rollei-retro-80s-2021', 'rollei-retro-80s', 'rollei-rls', '1+4', 100, 24, 'small_tank', 900),
    ('rollei-retro-80s-2021', 'rollei-retro-80s', 'kodak-hc-110', '1+31', 80, 20, 'small_tank', 480),
  ];
  for (final c in checks) {
    test('spot check ${c.$1}: ${c.$3} ${c.$4} EI ${c.$5} ${c.$6}C ${c.$7}', () {
      expect(timeFor(c.$1, c.$2, c.$3, c.$4, c.$5, c.$6, c.$7), c.$8);
    });
  }
}
