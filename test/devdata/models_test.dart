import 'package:drktimes/devdata/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> filmJson() => {
  'id': 'arista-edu-ultra-100',
  'brand': 'Arista EDU',
  'name': 'Ultra 100',
  'iso': 100,
  'process': 'bw_negative',
  'spectral': 'panchromatic',
  'formats': ['135', '120'],
  'status': 'current',
  'rebrand_of': 'foma-fomapan-100',
  'rebrand_basis': 'reported',
};

void main() {
  test('Film.fromJson reads required and optional fields', () {
    final f = Film.fromJson(filmJson());
    expect(f.id, 'arista-edu-ultra-100');
    expect(f.iso, 100);
    expect(f.formats, ['135', '120']);
    expect(f.aliases, isEmpty);
    expect(f.rebrandOf, 'foma-fomapan-100');
    expect(f.rebrandBasis, 'reported');
    expect(f.verifiedBy, isNull);
  });

  test('Film.fromJson rejects unknown keys', () {
    expect(
      () => Film.fromJson({...filmJson(), 'rebrandOf': 'x'}),
      throwsFormatException,
    );
  });

  test('Film.fromJson rejects a missing required field', () {
    expect(
      () => Film.fromJson({...filmJson()}..remove('iso')),
      throwsA(isA<TypeError>()),
    );
  });

  test('DevTime.fromJson attaches the file source id', () {
    final t = DevTime.fromJson({
      'film_id': 'kodak-tri-x-400',
      'developer_id': 'kodak-d-76',
      'dilution': 'stock',
      'ei': 400,
      'temp_c': 20,
      'time_s': 405,
      'method': 'small_tank',
      'page': 3,
    }, 'kodak-f4017-2021-10');
    expect(t.sourceId, 'kodak-f4017-2021-10');
    expect(t.timeS, 405);
    expect(t.timeMaxS, isNull);
    expect(t.page, 3);
  });

  test('DevTime.fromJson rejects fractional seconds', () {
    expect(
      () => DevTime.fromJson({
        'film_id': 'a',
        'developer_id': 'b',
        'dilution': 'stock',
        'ei': 400,
        'temp_c': 20,
        'time_s': 405.5,
        'method': 'small_tank',
      }, 's'),
      throwsA(isA<TypeError>()),
    );
  });

  test('Source.fromJson reads provenance fields', () {
    final s = Source.fromJson({
      'id': 'kodak-f4017-2021-10',
      'kind': 'manufacturer',
      'publisher': 'Kodak Alaris',
      'title': 'TRI-X',
      'url': 'https://kodakprofessional.com/x.pdf',
      'retrieved': '2026-09-14',
      'sha256': 'a' * 64,
    });
    expect(s.kind, 'manufacturer');
    expect(s.sha256, 'a' * 64);
    expect(s.permissionRef, isNull);
  });

  test('Developer.fromJson reads aliases', () {
    final d = Developer.fromJson({
      'id': 'adox-adonal',
      'brand': 'Adox',
      'name': 'Adonal',
      'aliases': ['Rodinal formula'],
    });
    expect(d.aliases, ['Rodinal formula']);
  });
}
