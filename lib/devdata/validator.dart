import 'models.dart';

const processes = {'bw_negative', 'bw_reversal', 'c41'};
const spectrals = {
  'panchromatic',
  'orthochromatic',
  'superpanchromatic',
  'infrared',
  'blue_sensitive',
};
const statuses = {'current', 'discontinued', 'announced', 'unknown'};
const formatCodes = {'135', '120', '127', '110', '620', 'sheet'};
const rebrandBases = {'official', 'reported'};
const sourceKinds = {'manufacturer', 'own_test', 'contributor', 'permission'};
const methods = {
  'small_tank',
  'large_tank',
  'nitrogen_burst',
  'rotary',
  'tray',
  'stand',
  'other',
};
const blockedHosts = {
  'digitaltruth.com',
  'darkroom-solutions.com',
  'massivedevchart.com',
  'scribd.com',
  'wikipedia.org',
  'reddit.com',
  'photrio.com',
  'emulsive.org',
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
    check(
      spectrals.contains(f.spectral),
      '$w: unknown spectral "${f.spectral}"',
    );
    check(statuses.contains(f.status), '$w: unknown status "${f.status}"');
    for (final fmt in f.formats) {
      check(formatCodes.contains(fmt), '$w: unknown format "$fmt"');
    }
    final target = f.rebrandOf;
    if (target == null) {
      check(f.rebrandBasis == null, '$w: rebrand_basis without rebrand_of');
    } else {
      check(target != f.id, '$w: rebrand_of points to itself');
      check(
        films.containsKey(target),
        '$w: rebrand_of "$target" is not a known film',
      );
      check(
        films[target]?.rebrandOf == null,
        '$w: rebrand_of "$target" is itself a rebrand; point at the original',
      );
      check(
        rebrandBases.contains(f.rebrandBasis),
        '$w: rebrand_basis must be official or reported',
      );
    }
    final by = f.verifiedBy;
    if (by != null) {
      check(
        sources.containsKey(by),
        '$w: verified_by "$by" is not a known source',
      );
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
      check(
        !blockedHosts.any((b) => host == b || host.endsWith('.$b')),
        '$w: $host is a forbidden source (see resources/devdata/README.md)',
      );
    }
    if (s.kind == 'permission') {
      check(
        s.permissionRef != null,
        '$w: permission sources need permission_ref',
      );
    }
    if (s.kind == 'contributor') {
      check(s.contributor != null, '$w: contributor sources need contributor');
    }
    final r = s.retrieved;
    if (r != null) check(_date.hasMatch(r), '$w: retrieved must be YYYY-MM-DD');
    final h = s.sha256;
    if (h != null)
      check(_sha256.hasMatch(h), '$w: sha256 must be 64 hex chars');
  }

  final seen = <String>{};
  for (final t in d.times) {
    final w =
        'time in ${t.sourceId}.json (${t.filmId} / ${t.developerId} '
        '${t.dilution} EI ${t.ei} ${t.tempC}C ${t.method})';
    final film = films[t.filmId];
    check(film != null, '$w: unknown film_id');
    check(
      film?.rebrandOf == null,
      '$w: film is a rebrand of "${film?.rebrandOf}"; record times against the original',
    );
    check(developers.containsKey(t.developerId), '$w: unknown developer_id');
    final source = sources[t.sourceId];
    check(source != null, '$w: source_id is not in sources.json');
    if (source != null && source.kind == 'manufacturer') {
      check(
        source.retrieved != null && source.sha256 != null,
        '$w: source must have retrieved and sha256 (run tool/fetch_source.sh)',
      );
      check(t.page != null, '$w: manufacturer rows need a page');
    }
    check(
      _dilution.hasMatch(t.dilution),
      '$w: dilution must be stock, working, or like 1+1 / 1+31 / 1+1+100',
    );
    check(t.ei > 0, '$w: ei must be > 0');
    check(t.tempC >= 14 && t.tempC <= 40, '$w: temp_c out of range 14-40');
    check(
      t.timeS >= 30 && t.timeS <= 10800,
      '$w: time_s out of range 30-10800',
    );
    final max = t.timeMaxS;
    if (max != null) check(max >= t.timeS, '$w: time_max_s is below time_s');
    final page = t.page;
    if (page != null) check(page >= 1, '$w: page must be >= 1');
    check(methods.contains(t.method), '$w: unknown method "${t.method}"');
    check(
      seen.add(
        [
          t.sourceId,
          t.filmId,
          t.developerId,
          t.dilution,
          t.ei,
          t.tempC,
          t.method,
        ].join('|'),
      ),
      '$w: duplicate row',
    );
  }

  return errors;
}
