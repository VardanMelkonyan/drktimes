# Dev-Times Dataset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `resources/devdata/` into a validated, license-clean (CC0) dataset of black-and-white film development times, then fill it by transcribing manufacturer datasheets with cheap Haiku agents.

**Architecture:** Hand-edited JSON files (`films.json`, `developers.json`, `sources.json`, one `times/<source-id>.json` per source document) are loaded by pure-Dart models in `lib/devdata/`, which the Flutter app can reuse later. A validator enforces referential integrity, value ranges and the sourcing policy (forbidden hosts, provenance, no times recorded against rebrands). A test that loads the real dataset is the gate every data change must pass. Extraction is split so each Haiku agent reads one datasheet and writes one file, with no shared-file conflicts. A stronger model reviews and spot-checks each file.

**Tech Stack:** Flutter 3.47.4 / Dart 3.13.3 (no new pub dependencies), `flutter_test`, bash + `curl` + `pdftotext`/`pdfinfo` (poppler) + `sha256sum`.

**Spec:** No separate spec. Requirements come from the 2026-09-14 conversation and are captured in `resources/devdata/README.md` (sourcing policy, already written) and in Global Constraints below.

## Global Constraints

- Flutter/Dart are NOT on PATH. Prefix every session with: `export PATH="$HOME/development/flutter/bin:$PATH"`
- Project root: `/home/vardan/Work/drktimes`. It is not a git repo yet; Task 1 runs `git init`.
- No new pub dependencies. `lib/devdata/` must not import Flutter (pure Dart, so `dart run` works).
- Dataset license: CC0 1.0. Only facts are copied; no PDF, page image, or document prose goes into the repo or the app.
- Forbidden source hosts: `digitaltruth.com`, `darkroom-solutions.com`, `massivedevchart.com`, `scribd.com`, `wikipedia.org`, `reddit.com`, `photrio.com`, `emulsive.org`.
- Times are integer seconds (`time_s`); temperatures are °C as printed in the source (`temp_c`); page numbers are 1-based PDF page indexes.
- Times are recorded only against original films (never a film with `rebrand_of`).
- Derived values (temperature compensation, push estimates) are never stored.
- Downloaded documents live in `resources/devdata/.cache/` (git-ignored).
- Data already present (from research, must pass the validator unchanged): 171 films, 26 developers, 19 sources, 65 Tri-X 400 rows in `times/kodak-f4017-2021-10.json`.

## File Structure

| Path | Responsibility |
|---|---|
| `lib/devdata/models.dart` | `Film`, `Developer`, `Source`, `DevTime`, `Dataset` + strict `fromJson` (rejects unknown keys). |
| `lib/devdata/loader.dart` | `loadDataset(Directory)`: reads the JSON files and turns any parse problem into a `FormatException` naming the file and index. |
| `lib/devdata/validator.dart` | `validate(Dataset) → List<String>` enforces all data rules. |
| `tool/validate_devdata.dart` | CLI: load + validate, print errors + counts, exit 1 on error. |
| `tool/fetch_source.sh` | Download a source by id, write per-page text, print `retrieved` + `sha256`. |
| `test/devdata/models_test.dart` | Model parsing tests. |
| `test/devdata/validator_test.dart` | One test per validation rule. |
| `test/devdata/dataset_test.dart` | Gate: real dataset validates; per-source spot checks. |
| `resources/devdata/LICENSE` | CC0 1.0 legal code. |
| `resources/devdata/*.json`, `times/*.json`, `README.md` | Data + policy (already exist). |

---

### Task 1: Repo init and data models

**Files:**
- Create: `lib/devdata/models.dart`
- Test: `test/devdata/models_test.dart`

**Interfaces:**
- Produces: `checkKeys(Map<String, dynamic>, Set<String>, String)`; classes `Film`, `Developer`, `Source`, `DevTime`, `Dataset` with the fields below; `Film.fromJson(Map)`, `Developer.fromJson(Map)`, `Source.fromJson(Map)`, `DevTime.fromJson(Map, String sourceId)`. Missing/mistyped required fields throw `TypeError`; unknown keys throw `FormatException`.

- [ ] **Step 1: Initialise git and commit the existing project + research data**

```bash
cd /home/vardan/Work/drktimes
git init
git add -A
git status --short | head -50   # confirm: no build/, .dart_tool/, secrets
git commit -m "chore: initial commit of Flutter scaffold and devdata research dump"
```

- [ ] **Step 2: Write the failing test** — `test/devdata/models_test.dart`

```dart
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
    expect(() => Film.fromJson({...filmJson(), 'rebrandOf': 'x'}),
        throwsFormatException);
  });

  test('Film.fromJson rejects a missing required field', () {
    expect(() => Film.fromJson({...filmJson()}..remove('iso')),
        throwsA(isA<TypeError>()));
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
        throwsA(isA<TypeError>()));
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/devdata/models_test.dart`
Expected: FAIL, compilation error `Target of URI doesn't exist: 'package:drktimes/devdata/models.dart'`.

- [ ] **Step 4: Write the implementation** — `lib/devdata/models.dart`

```dart
void checkKeys(Map<String, dynamic> json, Set<String> allowed, String where) {
  final unknown = json.keys.where((k) => !allowed.contains(k)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException('$where: unknown key(s) ${unknown.join(', ')}');
  }
}

List<String> _strings(Object? value) =>
    value == null ? const [] : List<String>.from(value as List);

class Film {
  const Film({
    required this.id,
    required this.brand,
    required this.name,
    required this.iso,
    required this.process,
    required this.spectral,
    required this.formats,
    required this.status,
    this.aliases = const [],
    this.rebrandOf,
    this.rebrandBasis,
    this.datasheetLead,
    this.verifiedBy,
    this.notes,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'film ${json['id']}');
    return Film(
      id: json['id'] as String,
      brand: json['brand'] as String,
      name: json['name'] as String,
      iso: json['iso'] as num,
      process: json['process'] as String,
      spectral: json['spectral'] as String,
      formats: List<String>.from(json['formats'] as List),
      status: json['status'] as String,
      aliases: _strings(json['aliases']),
      rebrandOf: json['rebrand_of'] as String?,
      rebrandBasis: json['rebrand_basis'] as String?,
      datasheetLead: json['datasheet_lead'] as String?,
      verifiedBy: json['verified_by'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {
    'id', 'brand', 'name', 'iso', 'process', 'spectral', 'formats', 'status',
    'aliases', 'rebrand_of', 'rebrand_basis', 'datasheet_lead', 'verified_by',
    'notes',
  };

  final String id, brand, name, process, spectral, status;
  final num iso;
  final List<String> formats, aliases;
  final String? rebrandOf, rebrandBasis, datasheetLead, verifiedBy, notes;
}

class Developer {
  const Developer({
    required this.id,
    required this.brand,
    required this.name,
    this.aliases = const [],
    this.notes,
  });

  factory Developer.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'developer ${json['id']}');
    return Developer(
      id: json['id'] as String,
      brand: json['brand'] as String,
      name: json['name'] as String,
      aliases: _strings(json['aliases']),
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {'id', 'brand', 'name', 'aliases', 'notes'};

  final String id, brand, name;
  final List<String> aliases;
  final String? notes;
}

class Source {
  const Source({
    required this.id,
    required this.kind,
    required this.publisher,
    required this.title,
    this.docCode,
    this.edition,
    this.url,
    this.retrieved,
    this.sha256,
    this.permissionRef,
    this.contributor,
    this.notes,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'source ${json['id']}');
    return Source(
      id: json['id'] as String,
      kind: json['kind'] as String,
      publisher: json['publisher'] as String,
      title: json['title'] as String,
      docCode: json['doc_code'] as String?,
      edition: json['edition'] as String?,
      url: json['url'] as String?,
      retrieved: json['retrieved'] as String?,
      sha256: json['sha256'] as String?,
      permissionRef: json['permission_ref'] as String?,
      contributor: json['contributor'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {
    'id', 'kind', 'publisher', 'title', 'doc_code', 'edition', 'url',
    'retrieved', 'sha256', 'permission_ref', 'contributor', 'notes',
  };

  final String id, kind, publisher, title;
  final String? docCode, edition, url, retrieved, sha256, permissionRef,
      contributor, notes;
}

class DevTime {
  const DevTime({
    required this.filmId,
    required this.developerId,
    required this.dilution,
    required this.ei,
    required this.tempC,
    required this.timeS,
    required this.method,
    required this.sourceId,
    this.timeMaxS,
    this.page,
    this.agitation,
    this.notes,
  });

  factory DevTime.fromJson(Map<String, dynamic> json, String sourceId) {
    checkKeys(json, _keys, 'time ${json['film_id']}/${json['developer_id']}');
    return DevTime(
      filmId: json['film_id'] as String,
      developerId: json['developer_id'] as String,
      dilution: json['dilution'] as String,
      ei: json['ei'] as num,
      tempC: json['temp_c'] as num,
      timeS: json['time_s'] as int,
      timeMaxS: json['time_max_s'] as int?,
      method: json['method'] as String,
      page: json['page'] as int?,
      agitation: json['agitation'] as String?,
      notes: json['notes'] as String?,
      sourceId: sourceId,
    );
  }

  static const _keys = {
    'film_id', 'developer_id', 'dilution', 'ei', 'temp_c', 'time_s',
    'time_max_s', 'method', 'page', 'agitation', 'notes',
  };

  final String filmId, developerId, dilution, method, sourceId;
  final num ei, tempC;
  final int timeS;
  final int? timeMaxS, page;
  final String? agitation, notes;
}

class Dataset {
  const Dataset({
    required this.films,
    required this.developers,
    required this.sources,
    required this.times,
  });

  final List<Film> films;
  final List<Developer> developers;
  final List<Source> sources;
  final List<DevTime> times;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/devdata/models_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/devdata/models.dart test/devdata/models_test.dart
git commit -m "feat(devdata): strict JSON models for films, developers, sources, times"
```

---

### Task 2: Validator

**Files:**
- Create: `lib/devdata/validator.dart`
- Test: `test/devdata/validator_test.dart`

**Interfaces:**
- Consumes: `Film`, `Developer`, `Source`, `DevTime`, `Dataset` from Task 1.
- Produces: `List<String> validate(Dataset d)`, empty when valid. Also exported constants `blockedHosts`, `methods`.

- [ ] **Step 1: Write the failing test** — `test/devdata/validator_test.dart`

```dart
import 'package:drktimes/devdata/models.dart';
import 'package:drktimes/devdata/validator.dart';
import 'package:flutter_test/flutter_test.dart';

Film film(String id,
        {String? rebrandOf,
        String? basis,
        String? verifiedBy,
        List<String> formats = const ['135']}) =>
    Film(
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

Source source(String id,
        {String kind = 'manufacturer',
        String? url = 'https://www.foma.cz/sheet.pdf',
        String? retrieved = '2026-09-14',
        String? sha256}) =>
    Source(
      id: id,
      kind: kind,
      publisher: 'Foma',
      title: 'sheet',
      url: url,
      retrieved: retrieved,
      sha256: sha256 ?? 'a' * 64,
    );

DevTime time(
        {String filmId = 'foma-fomapan-100',
        String dilution = '1+1',
        num tempC = 20,
        int timeS = 390,
        int? page = 1,
        String method = 'small_tank',
        String sourceId = 'foma-sheet'}) =>
    DevTime(
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

Dataset dataset(
        {List<Film>? films, List<Source>? sources, List<DevTime>? times}) =>
    Dataset(
      films: films ??
          [
            film('foma-fomapan-100'),
            film('arista-edu-ultra-100',
                rebrandOf: 'foma-fomapan-100', basis: 'reported'),
          ],
      developers: const [
        Developer(id: 'ilford-id-11', brand: 'Ilford', name: 'ID-11')
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
        dataset(films: [film('a', formats: ['35mm'])], times: []),
        'unknown format "35mm"');
  });

  test('rebrand target must exist', () {
    expectError(
        dataset(
            films: [film('a', rebrandOf: 'nope', basis: 'reported')],
            times: []),
        'not a known film');
  });

  test('rebrand must point at the original, not another rebrand', () {
    expectError(
        dataset(films: [
          film('orig'),
          film('mid', rebrandOf: 'orig', basis: 'reported'),
          film('leaf', rebrandOf: 'mid', basis: 'reported'),
        ], times: []),
        'itself a rebrand');
  });

  test('rebrand needs a basis', () {
    expectError(
        dataset(films: [film('orig'), film('b', rebrandOf: 'orig')], times: []),
        'rebrand_basis must be');
  });

  test('verified_by must name a source', () {
    expectError(dataset(films: [film('a', verifiedBy: 'nope')], times: []),
        'verified_by "nope"');
  });

  test('forbidden hosts are rejected, including subdomains', () {
    expectError(
        dataset(sources: [
          source('foma-sheet', url: 'https://www.digitaltruth.com/x.pdf')
        ]),
        'forbidden source');
  });

  test('manufacturer sources used by times must be fetched', () {
    expectError(dataset(sources: [source('foma-sheet', retrieved: null)]),
        'run tool/fetch_source.sh');
  });

  test('times may not be recorded against a rebrand', () {
    expectError(dataset(times: [time(filmId: 'arista-edu-ultra-100')]),
        'record times against the original');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/devdata/validator_test.dart`
Expected: FAIL, compilation error `Target of URI doesn't exist: 'package:drktimes/devdata/validator.dart'`.

- [ ] **Step 3: Write the implementation** — `lib/devdata/validator.dart`

```dart
import 'models.dart';

const processes = {'bw_negative', 'bw_reversal', 'c41'};
const spectrals = {
  'panchromatic', 'orthochromatic', 'superpanchromatic', 'infrared',
  'blue_sensitive',
};
const statuses = {'current', 'discontinued', 'announced', 'unknown'};
const formatCodes = {'135', '120', '127', '110', '620', 'sheet'};
const rebrandBases = {'official', 'reported'};
const sourceKinds = {'manufacturer', 'own_test', 'contributor', 'permission'};
const methods = {
  'small_tank', 'large_tank', 'nitrogen_burst', 'rotary', 'tray', 'stand',
  'other',
};
const blockedHosts = {
  'digitaltruth.com', 'darkroom-solutions.com', 'massivedevchart.com',
  'scribd.com', 'wikipedia.org', 'reddit.com', 'photrio.com', 'emulsive.org',
};

final _slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _dilution = RegExp(r'^(stock|working|\d+(\+\d+)+)$');
final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _sha256 = RegExp(r'^[0-9a-f]{64}$');

List<String> validate(Dataset d) {
  final errors = <String>[];
  void check(bool ok, String message) {
    if (!ok) errors.add(message);
  }

  Map<String, T> index<T>(String kind, List<T> items, String Function(T) id) {
    final map = <String, T>{};
    for (final item in items) {
      final key = id(item);
      check(_slug.hasMatch(key), '$kind "$key": id must be kebab-case');
      check(!map.containsKey(key), '$kind "$key": duplicate id');
      map[key] = item;
    }
    return map;
  }

  final films = index('film', d.films, (f) => f.id);
  final developers = index('developer', d.developers, (x) => x.id);
  final sources = index('source', d.sources, (s) => s.id);

  for (final f in d.films) {
    final w = 'film "${f.id}"';
    check(f.iso > 0, '$w: iso must be > 0');
    check(processes.contains(f.process), '$w: unknown process "${f.process}"');
    check(spectrals.contains(f.spectral), '$w: unknown spectral "${f.spectral}"');
    check(statuses.contains(f.status), '$w: unknown status "${f.status}"');
    for (final fmt in f.formats) {
      check(formatCodes.contains(fmt), '$w: unknown format "$fmt"');
    }
    final target = f.rebrandOf;
    if (target == null) {
      check(f.rebrandBasis == null, '$w: rebrand_basis without rebrand_of');
    } else {
      check(target != f.id, '$w: rebrand_of points to itself');
      check(films.containsKey(target),
          '$w: rebrand_of "$target" is not a known film');
      check(films[target]?.rebrandOf == null,
          '$w: rebrand_of "$target" is itself a rebrand; point at the original');
      check(rebrandBases.contains(f.rebrandBasis),
          '$w: rebrand_basis must be official or reported');
    }
    final by = f.verifiedBy;
    if (by != null) {
      check(sources.containsKey(by), '$w: verified_by "$by" is not a known source');
    }
  }

  for (final s in d.sources) {
    final w = 'source "${s.id}"';
    check(sourceKinds.contains(s.kind), '$w: unknown kind "${s.kind}"');
    final url = s.url;
    if (s.kind == 'manufacturer') {
      check(url != null, '$w: manufacturer sources need a url');
    }
    if (url != null) {
      final host = Uri.tryParse(url)?.host ?? '';
      check(host.isNotEmpty, '$w: url is not valid');
      check(!blockedHosts.any((b) => host == b || host.endsWith('.$b')),
          '$w: $host is a forbidden source (see resources/devdata/README.md)');
    }
    if (s.kind == 'permission') {
      check(s.permissionRef != null, '$w: permission sources need permission_ref');
    }
    if (s.kind == 'contributor') {
      check(s.contributor != null, '$w: contributor sources need contributor');
    }
    final r = s.retrieved;
    if (r != null) check(_date.hasMatch(r), '$w: retrieved must be YYYY-MM-DD');
    final h = s.sha256;
    if (h != null) check(_sha256.hasMatch(h), '$w: sha256 must be 64 hex chars');
  }

  final seen = <String>{};
  for (final t in d.times) {
    final w = 'time in ${t.sourceId}.json (${t.filmId} / ${t.developerId} '
        '${t.dilution} EI ${t.ei} ${t.tempC}C ${t.method})';
    final film = films[t.filmId];
    check(film != null, '$w: unknown film_id');
    check(film?.rebrandOf == null,
        '$w: film is a rebrand of "${film?.rebrandOf}"; record times against the original');
    check(developers.containsKey(t.developerId), '$w: unknown developer_id');
    final source = sources[t.sourceId];
    check(source != null, '$w: source_id is not in sources.json');
    if (source != null && source.kind == 'manufacturer') {
      check(source.retrieved != null && source.sha256 != null,
          '$w: source must have retrieved and sha256 (run tool/fetch_source.sh)');
      check(t.page != null, '$w: manufacturer rows need a page');
    }
    check(_dilution.hasMatch(t.dilution),
        '$w: dilution must be stock, working, or like 1+1 / 1+31 / 1+1+100');
    check(t.ei > 0, '$w: ei must be > 0');
    check(t.tempC >= 14 && t.tempC <= 40, '$w: temp_c out of range 14-40');
    check(t.timeS >= 30 && t.timeS <= 10800, '$w: time_s out of range 30-10800');
    final max = t.timeMaxS;
    if (max != null) check(max >= t.timeS, '$w: time_max_s is below time_s');
    final page = t.page;
    if (page != null) check(page >= 1, '$w: page must be >= 1');
    check(methods.contains(t.method), '$w: unknown method "${t.method}"');
    check(
        seen.add([t.sourceId, t.filmId, t.developerId, t.dilution, t.ei,
          t.tempC, t.method].join('|')),
        '$w: duplicate row');
  }

  return errors;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/devdata/validator_test.dart`
Expected: PASS (17 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/devdata/validator.dart test/devdata/validator_test.dart
git commit -m "feat(devdata): validator for integrity, ranges and sourcing policy"
```

---

### Task 3: Loader, CLI and the dataset gate

**Files:**
- Create: `lib/devdata/loader.dart`, `tool/validate_devdata.dart`
- Test: `test/devdata/dataset_test.dart`

**Interfaces:**
- Consumes: models (Task 1), `validate` (Task 2).
- Produces: `Dataset loadDataset(Directory dir)`, which throws `FormatException('<file>[<index>]: …')`. CLI: `dart run tool/validate_devdata.dart [dir]` exits 0 when valid and prints `N films, N developers, N sources, N times, N errors`.

- [ ] **Step 1: Write the failing test** — `test/devdata/dataset_test.dart`

```dart
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
    for (final f in ['films', 'developers', 'sources']) {
      File('${dir.path}/$f.json')
          .writeAsStringSync('{"schema_version": 1, "$f": []}');
    }
    Directory('${dir.path}/times').createSync();
    File('${dir.path}/times/a.json').writeAsStringSync(
        '{"schema_version": 1, "source_id": "b", "times": []}');
    expect(() => loadDataset(dir), throwsFormatException);
    dir.deleteSync(recursive: true);
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/devdata/dataset_test.dart`
Expected: FAIL, compilation error `Target of URI doesn't exist: 'package:drktimes/devdata/loader.dart'`.

- [ ] **Step 3: Write the loader** — `lib/devdata/loader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'models.dart';

Dataset loadDataset(Directory dir) {
  List<T> collection<T>(
      String file, String key, T Function(Map<String, dynamic>) parse) {
    final root = _readObject(File('${dir.path}/$file'));
    checkKeys(root, {'schema_version', key}, file);
    final items = root[key];
    if (items is! List) throw FormatException('$file: "$key" must be a list');
    return [
      for (final (i, item) in items.indexed)
        _parse('$file[$i]', () => parse(item as Map<String, dynamic>)),
    ];
  }

  final films = collection('films.json', 'films', Film.fromJson);
  final developers =
      collection('developers.json', 'developers', Developer.fromJson);
  final sources = collection('sources.json', 'sources', Source.fromJson);

  final times = <DevTime>[];
  final timesDir = Directory('${dir.path}/times');
  if (timesDir.existsSync()) {
    final files = timesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final root = _readObject(file);
      checkKeys(root, {'schema_version', 'source_id', 'times'}, name);
      final sourceId = _parse(name, () => root['source_id'] as String);
      if ('$sourceId.json' != name) {
        throw FormatException(
            '$name: source_id "$sourceId" must match the file name');
      }
      final rows = root['times'];
      if (rows is! List) throw FormatException('$name: "times" must be a list');
      for (final (i, row) in rows.indexed) {
        times.add(_parse('$name[$i]',
            () => DevTime.fromJson(row as Map<String, dynamic>, sourceId)));
      }
    }
  }

  return Dataset(
      films: films, developers: developers, sources: sources, times: times);
}

T _parse<T>(String where, T Function() parse) {
  try {
    return parse();
  } on FormatException catch (e) {
    throw FormatException('$where: ${e.message}');
  } on TypeError catch (e) {
    throw FormatException('$where: missing or mistyped field ($e)');
  }
}

Object? _decode(File file) {
  try {
    return jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw FormatException('${file.path}: invalid JSON (${e.message})');
  }
}

Map<String, dynamic> _readObject(File file) {
  final decoded = _decode(file);
  if (decoded is! Map<String, dynamic> || decoded['schema_version'] != 1) {
    throw FormatException(
        '${file.path}: expected an object with "schema_version": 1');
  }
  return decoded;
}
```

- [ ] **Step 4: Write the CLI** — `tool/validate_devdata.dart`

```dart
import 'dart:io';

import 'package:drktimes/devdata/loader.dart';
import 'package:drktimes/devdata/validator.dart';

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'resources/devdata' : args.first);
  try {
    final data = loadDataset(dir);
    final errors = validate(data);
    for (final e in errors) {
      stderr.writeln(e);
    }
    stdout.writeln('${data.films.length} films, ${data.developers.length} '
        'developers, ${data.sources.length} sources, ${data.times.length} '
        'times, ${errors.length} errors');
    exitCode = errors.isEmpty ? 0 : 1;
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  }
}
```

- [ ] **Step 5: Run tests and the CLI**

Run: `flutter test test/devdata/`
Expected: PASS (all tests in the three files).

Run: `dart run tool/validate_devdata.dart`
Expected: `171 films, 26 developers, 19 sources, 65 times, 0 errors`, exit code 0.

If the dataset gate fails, the research dump has a real data bug: fix the JSON, not the validator.

- [ ] **Step 6: Commit**

```bash
git add lib/devdata/loader.dart tool/validate_devdata.dart test/devdata/dataset_test.dart
git commit -m "feat(devdata): dataset loader, validate CLI and dataset gate test"
```

---

### Task 4: License, cache and fetch tool

**Files:**
- Create: `resources/devdata/LICENSE`, `tool/fetch_source.sh`
- Modify: `.gitignore` (append one line)

**Interfaces:**
- Produces: `tool/fetch_source.sh <source-id>`, which downloads the source's `url` to `resources/devdata/.cache/<id>.pdf`, writes `resources/devdata/.cache/<id>/page-<N>.txt` (layout text per 1-based page), and prints a JSON fragment `"retrieved": "YYYY-MM-DD", "sha256": "<hex>"` plus the page count. Exit 1 if the id is unknown or the download is not a PDF.

- [ ] **Step 1: Add the CC0 license text**

```bash
curl -sSL -o resources/devdata/LICENSE https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
head -3 resources/devdata/LICENSE
```
Expected: the first lines contain `Creative Commons Legal Code` and `CC0 1.0 Universal`.

- [ ] **Step 2: Ignore the download cache**

Append to `.gitignore`:
```
# Downloaded source documents (copyrighted; never commit)
/resources/devdata/.cache/
```

- [ ] **Step 3: Write** `tool/fetch_source.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

id="${1:?usage: tool/fetch_source.sh <source-id>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
data="$root/resources/devdata"
cache="$data/.cache"

url="$(python3 -c '
import json, sys
for s in json.load(open(sys.argv[1]))["sources"]:
    if s["id"] == sys.argv[2]:
        print(s.get("url") or ""); break
' "$data/sources.json" "$id")"
[ -n "$url" ] || { echo "unknown source id or no url: $id" >&2; exit 1; }

mkdir -p "$cache/$id"
pdf="$cache/$id.pdf"
curl -sSL --fail -A "Mozilla/5.0" -o "$pdf" "$url"
file "$pdf" | grep -q "PDF document" || { echo "not a PDF: $url (handle manually)" >&2; exit 1; }

pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
for p in $(seq 1 "$pages"); do
  pdftotext -layout -f "$p" -l "$p" "$pdf" "$cache/$id/page-$p.txt"
done

sha="$(sha256sum "$pdf" | cut -d' ' -f1)"
echo "pages: $pages -> $cache/$id/page-N.txt"
echo "\"retrieved\": \"$(date +%F)\", \"sha256\": \"$sha\""
```

- [ ] **Step 4: Test the tool on the already-verified source**

```bash
chmod +x tool/fetch_source.sh
tool/fetch_source.sh kodak-f4017-2021-10
```
Expected: `pages: 11`, then a line with `"sha256": "1d86b030cf7a8502e6f1414c630fa2cda30b68df53f49bccccce73c9c6562078"` (the value already in `sources.json`; if Kodak has changed the file the hash differs, so stop and report it). `grep -c "HC-110 (B)" resources/devdata/.cache/kodak-f4017-2021-10/page-3.txt` prints `1`.

Then: `tool/fetch_source.sh no-such-id; echo $?`. Expected: `unknown source id or no url: no-such-id` and `1`.

- [ ] **Step 5: Verify nothing from the cache is staged, then commit**

```bash
git add resources/devdata/LICENSE tool/fetch_source.sh .gitignore
git status --short   # must NOT list anything under resources/devdata/.cache/
git commit -m "chore(devdata): CC0 license, git-ignored source cache, fetch tool"
```

---

### Task 5: Datasheet extraction with Haiku (coordinator + one Haiku agent per source)

The coordinator (the main session, Sonnet/Opus) runs this loop. Haiku agents only transcribe. Each agent writes exactly two files, so agents can run in parallel.

**Files:**
- Create (by Haiku): `resources/devdata/times/<source-id>.json`, `resources/devdata/.cache/<source-id>.proposals.json`
- Modify (by coordinator): `resources/devdata/sources.json` (retrieved/sha256), `films.json` / `developers.json` (merged proposals), `test/devdata/dataset_test.dart` (spot checks)

**Interfaces:**
- Consumes: `tool/fetch_source.sh` (Task 4), `dart run tool/validate_devdata.dart` (Task 3), the row schema of `DevTime` (Task 1).
- Produces: one validated times file per source, plus 3 spot-check tests per source.

**Extraction queue** (sources already in `sources.json`, in priority order):

| # | source id | covers |
|---|---|---|
| 1 | `ilford-film-processing-chart-2017` | all Ilford films × Ilford developers (one table) |
| 2 | `ilford-hp5-plus-2018-11` | HP5 Plus, incl. push EIs |
| 3 | `ilford-ilfotec-dd-x-2019-08` | DD-X × many films, incl. Kodak and Fuji |
| 4 | `fujifilm-acros-ii-135` | Acros II 135 |
| 5 | `fujifilm-acros-ii-120` | Acros II 120 |
| 6 | `foma-fomapan-100-freestyle` | Fomapan 100 |
| 7 | `foma-fomapan-400-fomafoto` | Fomapan 400 |
| 8 | `kodak-h-1-5222` | Eastman Double-X |
| 9 | `kodak-edbwf` | Kodak B&W processing guide (Tri-X, T-Max/Ektapan) |
| 10 | `adox-chs-100-ii` | CHS 100 II |
| 11 | `rollei-rpx-100-2021` | RPX 100 |
| 12 | `rollei-retro-80s-2021` | Retro 80S |
| 13 | `orwo-vv-1182` | UN54, N74 Plus |
| 14 | `orwo-vv-1183` | UN54 full speed |
| 15 | `orwo-vv-1102` | Wolfen P400 |
| 16 | `bergger-pancro-400-2017-01` | Pancro 400 |
| 17 | `ferrania-p30-best-practices-v3` | P30 |
| 18 | `fujifilm-neopan-acros-100` | original Acros (discontinued) |
| 19 | `kodak-f4017-2021-10` | remaining tables: Tri-X 320 sheets (page 4), push EI 1600/3200 (page 6), and any others; page 3 is already done, so do not duplicate it |

- [ ] **Step 1: Fetch a batch (coordinator, sequential)**

For each source id in the batch (suggested batch size: 5):
```bash
tool/fetch_source.sh <source-id>
```
Paste the printed `"retrieved"` and `"sha256"` into that source's line in `sources.json`. If the tool prints `not a PDF` (an HTML page or a blocked download), remove the source from this batch and note it for Task 6.

- [ ] **Step 2: Dispatch one Haiku agent per fetched source, in parallel**

Use the Agent tool with `model: "haiku"`, `subagent_type: "general-purpose"`, and this prompt with `<SOURCE_ID>` substituted:

```text
You are transcribing development times from ONE manufacturer datasheet into JSON.
Project root: /home/vardan/Work/drktimes. Run first: export PATH="$HOME/development/flutter/bin:$PATH"

Input: the datasheet text, one file per PDF page:
  resources/devdata/.cache/<SOURCE_ID>/page-N.txt   (N = 1-based PDF page)
The PDF itself, if you need to check layout: resources/devdata/.cache/<SOURCE_ID>.pdf
Reference data (read, do not edit): resources/devdata/films.json, developers.json, sources.json
Worked example of the exact output format: resources/devdata/times/kodak-f4017-2021-10.json

Write exactly two files and nothing else:
1. resources/devdata/times/<SOURCE_ID>.json
   {"schema_version": 1, "source_id": "<SOURCE_ID>", "times": [ one object per line ]}
   Each row: film_id, developer_id, dilution, ei, temp_c, time_s, method, page
   Optional per row: time_max_s, agitation, notes (notes: at most 5 words, e.g. "Dilution B")
2. resources/devdata/.cache/<SOURCE_ID>.proposals.json
   {"films": [...], "developers": [...], "problems": [...]}
   films/developers: full objects in the same shape as films.json/developers.json
   for any film or developer the datasheet uses that is NOT already in the reference data.
   problems: short strings describing anything you skipped or were unsure about.

Rules:
- Transcribe ONLY numbers printed in the document. Never calculate, interpolate, or fill gaps.
- A row = one printed cell. Skip cells marked NR, "—", "-", "n/a", or blank.
- time_s is integer seconds. Minute fractions may appear as "63⁄4", "6 3⁄4", "6¾", "6.75", or "6:45",
  all meaning 6 min 45 s = 405. In "NN⁄M" the digit right before "⁄" is the numerator and the digits
  before it are whole minutes: "103⁄4" = 10¾ = 645, "121⁄4" = 12¼ = 735, "41⁄2" = 4½ = 270.
  A range "8-10" means time_s 480, time_max_s 600.
- temp_c: use the °C value printed. If only °F is printed, convert to °C rounded to 0.1 and add
  a note naming the printed value, e.g. "converted from 68F".
- dilution: "stock", "undiluted", "1+0" -> "stock". "1:1" or "1+1" -> "1+1". "1:31" -> "1+31".
  HC-110 "dilution B" -> "1+31" with notes "Dilution B" (A=1+15, E=1+47, H=1+63).
  If the document prints a dilution anywhere for that developer (e.g. DD-X "1+4"), use it.
  If it prints none (e.g. Kodak lists just "T-MAX RS"), use "working".
- ei: the EI/ISO the column or table states; if none is stated, the film's box ISO.
- method: small spiral tank / inversion -> "small_tank"; Kodak large tank / basket -> "large_tank";
  gaseous burst -> "nitrogen_burst"; rotary / Jobo -> "rotary"; tray / dish -> "tray"; stand -> "stand";
  anything else -> "other" with a short agitation value.
- page: the N of the page-N.txt file the cell came from.
- film_id / developer_id must be ids from the reference data. If missing, invent a kebab-case id
  in the same style (brand-name), use it in rows, and put the full object in proposals.
- If a table is for a film whose films.json entry has "rebrand_of", do NOT write rows; add a problem.
- Do not copy any sentences from the document.

When done, run: dart run tool/validate_devdata.dart
Fix every error in YOUR times file. Errors saying "unknown film_id" / "unknown developer_id" for ids
you proposed are expected; leave those.
Final reply: number of rows written, pages used, and the problems list. Under 150 words.
```

- [ ] **Step 3: Merge proposals (coordinator)**

For each `resources/devdata/.cache/<id>.proposals.json`: review every proposed film/developer (real product? id style consistent? not a duplicate under another name?), then add accepted objects to `films.json` / `developers.json`. If a proposal duplicates an existing entry, rewrite the ids in that times file instead. Read the `problems` list and resolve or record each item in Task 6.

- [ ] **Step 4: Run the validator**

Run: `dart run tool/validate_devdata.dart`
Expected: `0 errors`. Fix data, never the validator.

- [ ] **Step 5: Independent spot check (coordinator, not the Haiku agent)**

For each new times file, pick 3 rows from different tables or columns, find the cells in `.cache/<id>/page-<page>.txt` yourself, and confirm `time_s`, `temp_c`, `dilution`, `ei`. Add them to `test/devdata/dataset_test.dart` in the same shape as the Tri-X group:

```dart
  group('spot checks: <SOURCE_ID> page <N> (<film name>)', () {
    const s = '<SOURCE_ID>', f = '<film-id>';
    test('<developer> <dilution> <temp>C <method> = <printed value>', () {
      expect(timeFor(s, f, '<developer-id>', '<dilution>', <ei>, <temp>, '<method>'), <seconds>);
    });
    // two more
  });
```

If any spot check disagrees with the page text, reject the whole file: delete it and re-dispatch with a note naming the error. A wrong value means other values may be wrong too.

- [ ] **Step 6: Set `verified_by`**

For every film that now has rows from a source, set `"verified_by": "<source-id>"` in `films.json` (the first source is enough).

- [ ] **Step 7: Run all tests, then commit per source**

Run: `flutter test test/devdata/ && dart run tool/validate_devdata.dart`
Expected: all pass, `0 errors`.

```bash
git add resources/devdata/sources.json resources/devdata/films.json resources/devdata/developers.json \
        resources/devdata/times/<source-id>.json test/devdata/dataset_test.dart
git status --short   # nothing under .cache/
git commit -m "data: transcribe <source-id>"
```

Repeat Steps 1–7 until the queue is empty.

---

### Task 6: Source discovery with Haiku (find more allowed documents)

**Files:**
- Modify (by coordinator after review): `resources/devdata/sources.json`

**Interfaces:**
- Consumes: forbidden-host list (Global Constraints), `films.json`.
- Produces: new `sources.json` entries (without `retrieved`/`sha256`), which feed back into the Task 5 queue.

- [ ] **Step 1: Dispatch Haiku discovery agents** (`model: "haiku"`, one per brand group, in parallel)

Brand groups: (a) Kodak/Eastman: Ektapan datasheets, T-Max F-4016, developer sheets J-78 (D-76), J-24 (HC-110), J-109 (XTOL), J-86 (T-MAX); (b) Ilford/Harman: all film + developer sheets on https://www.ilfordphoto.com/technical-data/ incl. Kentmere Pan 200; (c) Foma: foma.cz product pages for every Foma film + Fomadon developer sheets; (d) Adox: adox.de sheets for CMS 20 II, HR-50, Silvermax, and developers Adonal, FX-39 II, XT-3, Atomal 49, HR-DEV; (e) Rollei: RPX 25/400, Retro 400S, Superpan 200, Infrared 400, Ortho 25 Plus, RPX-D; (f) others: Leica Monopan 50, Ferrania P33/Orto, Silberra, Lucky SHD/Yingzhe, Lomography Berlin Kino, CineStill Df96, Bergger BER49, Shanghai GP3.

Prompt (substitute `<GROUP>`):

```text
Find official technical documents (PDF preferred) that contain black-and-white film
development times for: <GROUP>.
Allowed: the film or developer manufacturer's own website, or an authorized distributor's copy
(e.g. freestylephoto.com, macodirect.de, fotoimpex.de) when the manufacturer has none.
Forbidden, do not use or return: digitaltruth.com, darkroom-solutions.com, massivedevchart.com,
scribd.com, wikipedia.org, reddit.com, photrio.com, emulsive.org, or any blog/forum.
Use WebSearch and WebFetch. Do not guess URLs; only return URLs you saw in results or pages.
Return ONLY a JSON array, one object per document, in this exact shape:
{"id": "<brand>-<short-name>[-<yyyy-mm>]", "kind": "manufacturer", "publisher": "...",
 "title": "...", "doc_code": "... or omit", "edition": "... or omit", "url": "..."}
ids are lowercase kebab-case. Skip any document already listed in
/home/vardan/Work/drktimes/resources/devdata/sources.json (read it first). Under 40 entries.
```

- [ ] **Step 2: Review and add (coordinator)**

Check each returned URL's host against the forbidden list. Spot-open 2 URLs per group to confirm they are the real publisher's documents. Add accepted entries to `sources.json` and append them to the Task 5 queue.

- [ ] **Step 3: Validate and commit**

Run: `dart run tool/validate_devdata.dart`. Expected: `0 errors`.
```bash
git add resources/devdata/sources.json
git commit -m "data: add discovered manufacturer sources"
```

---

### Task 7: Catalog cleanup

**Files:**
- Modify: `resources/devdata/films.json`

These leads from research were not confirmed and were deliberately left out of `films.json`. Keep them out unless a primary source confirms them: "Rollei PAN 25/100/400" (not on Rollei's product page, probably an error in the list), "Vibe 100/400", "Rera Ortho 400", "Shanghai GPL 200", "SPUR DSX / UR", "Efke KB 400".

Already in `films.json` but flagged in `notes` for checking: `rollei-blackbird` (ISO/formats), `tasma-nk-2` / `fpp-tasma-nk-2` (ISO 100 vs 400), `adox-silvermax` (status), `jch-streetpan-400` (status), `lucky-yingzhe-100/400` (formats), `efke-ir-820` (ISO), `ultrafine-ct-duplicating` (sensitivity).

- [ ] **Step 1:** For each flagged film, find the manufacturer's product page (allowed hosts only). Fix the fields and remove the note when confirmed. If a film cannot be confirmed to exist, delete it.
- [ ] **Step 2:** Run `flutter test test/devdata/ && dart run tool/validate_devdata.dart`. Expected: pass, `0 errors`.
- [ ] **Step 3:** Commit: `git commit -am "data: resolve flagged catalog entries"`

---

## Out of scope (follow-ups)

- Loading the dataset in the Flutter UI (add `resources/devdata/` to `pubspec.yaml` assets; reuse `lib/devdata/models.dart`).
- Temperature-compensation and push/pull calculators (computed in the app, never stored).
- In-app contributor submissions with CC0 consent (`kind: contributor`).
- Asking Harman, Foma, Adox for written permission (`kind: permission`) to reduce any remaining doubt.
