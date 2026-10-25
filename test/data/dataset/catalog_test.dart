import 'dart:convert';
import 'dart:io';

import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/dataset/datasheet_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = Catalog.fromJson(
    jsonDecode(File('assets/devdata.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('loads the real dataset', () {
    expect(catalog.films.length, 172);
    expect(catalog.developers.length, 100);
    expect(catalog.datasetVersion, isNotEmpty);
  });

  test('rebrandFamily groups rebrand_of chains', () {
    final fam = catalog.rebrandFamily('adox-scala-50');
    expect(fam, containsAll(['adox-hr-50', 'adox-scala-50']));
    expect(catalog.rebrandFamily('adox-hr-50'), fam);
    expect(catalog.rebrandFamily('ilford-hp5-plus'), ['ilford-hp5-plus']);
  });

  test('timesFor returns sourced datasheet times', () {
    final ts = catalog.timesFor(
      'ilford-hp5-plus',
      'ilford-ilfotec-dd-x',
      dilution: '1+4',
      ei: 400,
      tempC: 20,
    );
    expect(ts, isNotEmpty);
    final t = ts.first;
    expect(t.timeS, 540);
    expect(t.source.publisher, 'Harman Technology');
    expect(t.page, isNotNull);
    expect(t.inheritedFromFilmId, isNull);
    expect(ts.map((x) => x.source.id).toSet().length, greaterThanOrEqualTo(2));
  });

  test('rows inherited through a rebrand are labelled', () {
    final ts = catalog.timesFor('adox-scala-50', 'ilford-ilfotec-dd-x');
    expect(ts, isNotEmpty);
    expect(ts.every((t) => t.inheritedFromFilmId == 'adox-hr-50'), isTrue);
    expect(ts.every((t) => t.rebrandBasis == 'official'), isTrue);
    final reported = catalog.timesFor('agfaphoto-apx-100', 'ilford-ilfotec-dd');
    expect(reported.every((t) => t.rebrandBasis == 'reported'), isTrue);
  });

  test('defaultRunTimeS is the midpoint rounded to 15 s', () {
    DatasheetTime make(int s, int? max) =>
        DatasheetTime.test(timeS: s, timeMaxS: max, method: 'small_tank');
    expect(make(540, null).defaultRunTimeS, 540);
    expect(make(330, 360).defaultRunTimeS, 345);
    expect(make(420, 480).defaultRunTimeS, 450);
    expect(make(400, 425).defaultRunTimeS, 420); // 412.5 rounds half up
  });

  test('isPrimary only for small_tank', () {
    expect(
      DatasheetTime.test(timeS: 1, method: 'small_tank').isPrimary,
      isTrue,
    );
    expect(DatasheetTime.test(timeS: 1, method: 'rotary').isPrimary, isFalse);
  });

  test('combinations are enumerable per film', () {
    final devs = catalog.developersWithTimesFor('ilford-hp5-plus');
    expect(devs, contains('ilford-ilfotec-dd-x'));
    expect(
      catalog.developersWithTimesFor('adox-scala-50'),
      containsAll(catalog.developersWithTimesFor('adox-hr-50')),
    );
  });
}
