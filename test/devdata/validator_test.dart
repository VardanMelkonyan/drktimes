import 'package:drktimes/devdata/models.dart';
import 'package:drktimes/devdata/validator.dart';
import 'package:flutter_test/flutter_test.dart';

Film film(
  String id, {
  String? rebrandOf,
  String? basis,
  String? verifiedBy,
  List<String> formats = const ['135'],
}) => Film(
  id: id,
  brand: 'Brand',
  name: id,
  iso: 100,
  process: 'bw_negative',
  spectral: 'panchromatic',
  formats: formats,
  status: 'current',
  rebrandOf: rebrandOf,
  rebrandBasis: basis,
  verifiedBy: verifiedBy,
);

Source source(
  String id, {
  String kind = 'manufacturer',
  String? url = 'https://www.foma.cz/sheet.pdf',
  String? retrieved = '2026-09-14',
  String? sha256,
}) => Source(
  id: id,
  kind: kind,
  publisher: 'Foma',
  title: 'sheet',
  url: url,
  retrieved: retrieved,
  sha256: sha256 ?? 'a' * 64,
);

DevTime time({
  String filmId = 'foma-fomapan-100',
  String dilution = '1+1',
  num tempC = 20,
  int timeS = 390,
  int? page = 1,
  String method = 'small_tank',
  String sourceId = 'foma-sheet',
}) => DevTime(
  filmId: filmId,
  developerId: 'ilford-id-11',
  dilution: dilution,
  ei: 100,
  tempC: tempC,
  timeS: timeS,
  method: method,
  page: page,
  sourceId: sourceId,
);

Dataset dataset({
  List<Film>? films,
  List<Source>? sources,
  List<DevTime>? times,
}) => Dataset(
  films:
      films ??
      [
        film('foma-fomapan-100'),
        film(
          'arista-edu-ultra-100',
          rebrandOf: 'foma-fomapan-100',
          basis: 'reported',
        ),
      ],
  developers: const [
    Developer(id: 'ilford-id-11', brand: 'Ilford', name: 'ID-11'),
  ],
  sources: sources ?? [source('foma-sheet')],
  times: times ?? [time()],
);

void expectError(Dataset d, String fragment) =>
    expect(validate(d).join('\n'), contains(fragment));

void main() {
  test('a valid dataset has no errors', () {
    expect(validate(dataset()), isEmpty);
  });

  test('duplicate ids', () {
    expectError(dataset(films: [film('a'), film('a')]), 'duplicate id');
  });

  test('ids must be kebab-case', () {
    expectError(dataset(films: [film('Foma_100')], times: []), 'kebab-case');
  });

  test('unknown format', () {
    expectError(
      dataset(
        films: [
          film('a', formats: ['35mm']),
        ],
        times: [],
      ),
      'unknown format "35mm"',
    );
  });

  test('rebrand target must exist', () {
    expectError(
      dataset(
        films: [film('a', rebrandOf: 'nope', basis: 'reported')],
        times: [],
      ),
      'not a known film',
    );
  });

  test('rebrand must point at the original, not another rebrand', () {
    expectError(
      dataset(
        films: [
          film('orig'),
          film('mid', rebrandOf: 'orig', basis: 'reported'),
          film('leaf', rebrandOf: 'mid', basis: 'reported'),
        ],
        times: [],
      ),
      'itself a rebrand',
    );
  });

  test('rebrand needs a basis', () {
    expectError(
      dataset(
        films: [
          film('orig'),
          film('b', rebrandOf: 'orig'),
        ],
        times: [],
      ),
      'rebrand_basis must be',
    );
  });

  test('verified_by must name a source', () {
    expectError(
      dataset(
        films: [film('a', verifiedBy: 'nope')],
        times: [],
      ),
      'verified_by "nope"',
    );
  });

  test('forbidden hosts are rejected, including subdomains', () {
    expectError(
      dataset(
        sources: [
          source('foma-sheet', url: 'https://www.digitaltruth.com/x.pdf'),
        ],
      ),
      'forbidden source',
    );
  });

  test('manufacturer sources used by times must be fetched', () {
    expectError(
      dataset(sources: [source('foma-sheet', retrieved: null)]),
      'run tool/fetch_source.sh',
    );
  });

  test('times may not be recorded against a rebrand', () {
    expectError(
      dataset(times: [time(filmId: 'arista-edu-ultra-100')]),
      'record times against the original',
    );
  });

  test('dilution format', () {
    expectError(dataset(times: [time(dilution: '1:1')]), 'dilution must be');
  });

  test('temperature range', () {
    expectError(dataset(times: [time(tempC: 50)]), 'temp_c out of range');
  });

  test('time range', () {
    expectError(dataset(times: [time(timeS: 5)]), 'time_s out of range');
  });

  test('manufacturer rows need a page', () {
    expectError(dataset(times: [time(page: null)]), 'need a page');
  });

  test('unknown method', () {
    expectError(dataset(times: [time(method: 'jobo')]), 'unknown method');
  });

  test('duplicate rows', () {
    expectError(dataset(times: [time(), time()]), 'duplicate row');
  });
}
