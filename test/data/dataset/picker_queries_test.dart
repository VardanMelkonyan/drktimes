import 'dart:convert';
import 'dart:io';

import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/dataset/picker_queries.dart';
import 'package:drktimes/domain/combination_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = Catalog.fromJson(
    jsonDecode(File('assets/devdata.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final q = PickerQueries(
    catalog: catalog,
    recipes: const [],
    userFilms: const [],
    userDevelopers: const [],
  );
  const hp5 = FilmRef.catalog('ilford-hp5-plus');
  const ddx = DeveloperRef.catalog('ilford-ilfotec-dd-x');

  test('developers with times come first, others after', () {
    final r = q.developersFor(hp5);
    expect(r.withTimes.map((o) => o.ref), contains(ddx));
    expect(
      r.withTimes.first.count,
      greaterThanOrEqualTo(r.withTimes.last.count),
    );
    expect(r.others.every((o) => o.count == 0), isTrue);
    expect(r.others.map((o) => o.ref), isNot(contains(ddx)));
    expect(r.withTimes.length + r.others.length, catalog.developers.length);
  });

  test('EIs start with box speed and include push/pull entries', () {
    final eis = q.eisFor(hp5, ddx);
    expect(eis.first.ei, 400);
    expect(eis.map((e) => e.ei), containsAll([400, 800, 1600, 3200]));
  });

  test('dilutions for an EI report counts, typical time and temperature', () {
    final d = q.dilutionsFor(hp5, ddx, 400);
    expect(d.first.dilution, '1+4');
    expect(d.first.typicalTimeS, 540);
    expect(d.first.tempC, 20);
  });

  test('box speed is offered even without data', () {
    final eis = q.eisFor(
      const FilmRef.catalog('kodak-tri-x-400'),
      const DeveloperRef.catalog('ilford-ilfotec-dd-x'),
    );
    expect(eis.first.ei, 400);
  });
}
