import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../../devdata/models.dart';
import '../../domain/combination_key.dart';
import 'datasheet_time.dart';

/// In-memory index over the compiled dataset (assets/devdata.json).
class Catalog {
  Catalog._({
    required this.datasetVersion,
    required this.films,
    required this.developers,
    required this.sources,
    required List<DevTime> times,
  }) {
    for (final f in films) {
      _films[f.id] = f;
    }
    for (final d in developers) {
      _developers[d.id] = d;
    }
    for (final s in sources) {
      _sources[s.id] = s;
    }
    for (final t in times) {
      _byFilm.putIfAbsent(t.filmId, () => []).add(t);
    }
    for (final f in films) {
      final root = f.rebrandOf ?? f.id;
      _family.putIfAbsent(root, () => [root]);
      if (f.rebrandOf != null) _family[root]!.add(f.id);
    }
  }

  factory Catalog.fromJson(Map<String, dynamic> json) {
    final times = <DevTime>[];
    for (final group in json['times'] as List) {
      final g = group as Map<String, dynamic>;
      final sourceId = g['source_id'] as String;
      for (final row in g['times'] as List) {
        times.add(DevTime.fromJson(row as Map<String, dynamic>, sourceId));
      }
    }
    return Catalog._(
      datasetVersion: json['dataset_version'] as String? ?? '',
      films: [
        for (final f in json['films'] as List)
          Film.fromJson(f as Map<String, dynamic>),
      ],
      developers: [
        for (final d in json['developers'] as List)
          Developer.fromJson(d as Map<String, dynamic>),
      ],
      sources: [
        for (final s in json['sources'] as List)
          Source.fromJson(s as Map<String, dynamic>),
      ],
      times: times,
    );
  }

  static Future<Catalog> load(
    AssetBundle bundle, {
    String asset = 'assets/devdata.json',
  }) async {
    final text = await bundle.loadString(asset);
    return Catalog.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  final String datasetVersion;
  final List<Film> films;
  final List<Developer> developers;
  final List<Source> sources;

  final _films = <String, Film>{};
  final _developers = <String, Developer>{};
  final _sources = <String, Source>{};
  final _byFilm = <String, List<DevTime>>{};
  final _family = <String, List<String>>{};

  Film? film(String id) => _films[id];
  Developer? developer(String id) => _developers[id];
  Source? source(String id) => _sources[id];

  /// The original film plus every film that is a rebrand of it, original first.
  List<String> rebrandFamily(String filmId) {
    final root = _films[filmId]?.rebrandOf ?? filmId;
    return List.unmodifiable(_family[root] ?? [filmId]);
  }

  /// Datasheet times for a film and developer, optionally narrowed to a
  /// dilution / EI / temperature. A rebrand shows the original's rows, marked
  /// as inherited (FR-013).
  List<DatasheetTime> timesFor(
    String filmId,
    String developerId, {
    String? dilution,
    int? ei,
    int? tempC,
  }) {
    final film = _films[filmId];
    final rootId = film?.rebrandOf ?? filmId;
    final inherited = rootId != filmId;
    final out = <DatasheetTime>[];
    for (final t in _byFilm[rootId] ?? const <DevTime>[]) {
      if (t.developerId != developerId) continue;
      final d = normaliseDilution(t.dilution);
      final e = t.ei.round();
      final c = t.tempC.round();
      if (dilution != null && d != normaliseDilution(dilution)) continue;
      if (ei != null && e != ei) continue;
      if (tempC != null && c != tempC) continue;
      out.add(
        DatasheetTime(
          filmId: filmId,
          developerId: developerId,
          dilution: d,
          ei: e,
          tempC: c,
          timeS: t.timeS,
          timeMaxS: t.timeMaxS,
          method: t.method,
          source: _sources[t.sourceId]!,
          page: t.page,
          agitationText: t.agitation,
          notes: t.notes,
          inheritedFromFilmId: inherited ? rootId : null,
          rebrandBasis: inherited ? film!.rebrandBasis : null,
        ),
      );
    }
    return out;
  }

  /// Developer ids that have at least one datasheet time for this film
  /// (through its rebrand original if any).
  Set<String> developersWithTimesFor(String filmId) {
    final rootId = _films[filmId]?.rebrandOf ?? filmId;
    return {
      for (final t in _byFilm[rootId] ?? const <DevTime>[]) t.developerId,
    };
  }
}
