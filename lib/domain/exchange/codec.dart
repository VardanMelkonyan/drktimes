import 'dart:convert';

import '../combination_key.dart';
import '../process.dart';
import '../recipe.dart';
import '../user_entries.dart';
import 'document.dart';

enum ExchangeError {
  notJson,
  wrongFormat,
  unsupportedVersion,
  invalid,
  badEncoding,
}

class ExchangeException implements Exception {
  const ExchangeException(this.error, [this.message = '']);

  final ExchangeError error;
  final String message;

  @override
  String toString() => 'ExchangeException(${error.name}: $message)';
}

/// Encodes and decodes the exchange document
/// (contracts/exchange-format.schema.json). Readers ignore unknown fields and
/// reject a higher major `format_version`.
class ExchangeCodec {
  const ExchangeCodec._();

  static String encodeString(ExchangeDocument d) => jsonEncode(toJson(d));

  static ExchangeDocument decodeString(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException catch (e) {
      throw ExchangeException(ExchangeError.notJson, e.message);
    }
    if (json is! Map<String, dynamic>) {
      throw const ExchangeException(ExchangeError.notJson, 'not an object');
    }
    return fromJson(json);
  }

  // ----------------------------------------------------------------- encode

  static Map<String, dynamic> toJson(ExchangeDocument d) {
    final backup = d.kind == ExchangeKind.backup;
    return {
      'format': ExchangeDocument.format,
      'format_version': d.formatVersion,
      'kind': d.kind.name,
      'exported_at': d.exportedAt.toUtc().toIso8601String(),
      if (d.appVersion != null) 'app_version': d.appVersion,
      if (d.userFilms.isNotEmpty)
        'user_films': [
          for (final f in d.userFilms)
            {'id': f.id, 'brand': f.brand, 'name': f.name, 'box_iso': f.boxIso},
        ],
      if (d.userDevelopers.isNotEmpty)
        'user_developers': [
          for (final v in d.userDevelopers)
            {'id': v.id, 'brand': v.brand, 'name': v.name},
        ],
      'recipes': [for (final r in d.recipes) _recipe(r, backup)],
      if (backup && d.favourites.isNotEmpty)
        'favourites': [for (final k in d.favourites) k.toJson()],
      if (backup && d.sessions.isNotEmpty)
        'sessions': [for (final s in d.sessions) _session(s)],
      if (d.processes.isNotEmpty)
        'processes': [for (final p in d.processes) p.toJson()],
      if (backup && d.settings != null) 'settings': d.settings,
    };
  }

  static Map<String, dynamic> _recipe(ExchangeRecipe er, bool backup) {
    final r = er.recipe;
    return {
      'id': r.id,
      'version': r.version,
      'created_at': r.createdAt.toUtc().toIso8601String(),
      'updated_at': r.updatedAt.toUtc().toIso8601String(),
      'author_name': r.authorName,
      'origin': r.origin.toJson(),
      'key': r.key.toJson(),
      'dev_time_s': r.devTimeS,
      'dev_agitation': r.devAgitation.toJson(),
      if (r.process != null) 'process': r.process!.toJson(),
      'notes': [
        for (final n in er.notes)
          {
            'id': n.id,
            'author_name': n.authorName,
            'created_at': n.createdAt.toUtc().toIso8601String(),
            'text': n.text,
          },
      ],
      if (backup) 'ownership': r.ownership.name,
      if (backup) 'hidden': r.hidden,
    };
  }

  static Map<String, dynamic> _session(ExchangeSession s) => {
    'id': s.id,
    'tank_label': s.tankLabel,
    'key': s.key.toJson(),
    'time_source': s.timeSource,
    'dev_time_s': s.devTimeS,
    'format': s.format,
    'status': s.status,
    if (s.abortedAtStep != null) 'aborted_at_step': s.abortedAtStep,
    'started_at': s.startedAt.toUtc().toIso8601String(),
    if (s.finishedAt != null)
      'finished_at': s.finishedAt!.toUtc().toIso8601String(),
    if (s.stepDurationsS.isNotEmpty) 'step_durations_s': s.stepDurationsS,
  };

  // ----------------------------------------------------------------- decode

  static ExchangeDocument fromJson(Map<String, dynamic> j) {
    if (j['format'] != ExchangeDocument.format) {
      throw const ExchangeException(
        ExchangeError.wrongFormat,
        'not a drktimes document',
      );
    }
    final version = j['format_version'];
    if (version is! String || !RegExp(r'^\d+\.\d+$').hasMatch(version)) {
      throw const ExchangeException(
        ExchangeError.invalid,
        'format_version missing',
      );
    }
    if (int.parse(version.split('.').first) > 1) {
      throw ExchangeException(ExchangeError.unsupportedVersion, version);
    }
    return _guard(() {
      final kind = switch (j['kind']) {
        'recipe' => ExchangeKind.recipe,
        'backup' => ExchangeKind.backup,
        _ => throw const FormatException('kind must be recipe or backup'),
      };
      final recipes = [
        for (final r in _list(j['recipes'])) _readRecipe(_map(r), kind),
      ];
      if (kind == ExchangeKind.recipe && recipes.length != 1) {
        throw const FormatException('a recipe document has exactly one recipe');
      }
      return ExchangeDocument(
        kind: kind,
        formatVersion: version,
        exportedAt: _time(j['exported_at'], 'exported_at'),
        appVersion: j['app_version'] as String?,
        userFilms: [for (final f in _list(j['user_films'])) _readFilm(_map(f))],
        userDevelopers: [
          for (final d in _list(j['user_developers'])) _readDeveloper(_map(d)),
        ],
        recipes: recipes,
        favourites: kind == ExchangeKind.backup
            ? [
                for (final k in _list(j['favourites']))
                  CombinationKey.fromJson(_map(k)),
              ]
            : const [],
        sessions: kind == ExchangeKind.backup
            ? [for (final s in _list(j['sessions'])) _readSession(_map(s))]
            : const [],
        processes: [
          for (final p in _list(j['processes'])) _readProcess(_map(p)),
        ],
        settings: kind == ExchangeKind.backup && j['settings'] is Map
            ? Map<String, dynamic>.from(j['settings'] as Map)
            : null,
      );
    });
  }

  static T _guard<T>(T Function() read) {
    try {
      return read();
    } on ExchangeException {
      rethrow;
    } on FormatException catch (e) {
      throw ExchangeException(ExchangeError.invalid, e.message);
    } on ArgumentError catch (e) {
      throw ExchangeException(ExchangeError.invalid, '${e.message}');
    } on TypeError catch (e) {
      throw ExchangeException(ExchangeError.invalid, '$e');
    } on StateError catch (e) {
      throw ExchangeException(ExchangeError.invalid, e.message);
    }
  }

  static List<Object?> _list(Object? v) =>
      v == null ? const [] : v as List<Object?>;

  static Map<String, dynamic> _map(Object? v) =>
      Map<String, dynamic>.from(v as Map);

  static DateTime _time(Object? v, String field) {
    final t = v is String ? DateTime.tryParse(v) : null;
    if (t == null) throw FormatException('$field is not a date-time');
    return t.toUtc();
  }

  static String _text(
    Map<String, dynamic> m,
    String key, {
    required int min,
    required int max,
  }) {
    final v = m[key];
    if (v is! String || v.length < min || v.length > max) {
      throw FormatException('$key must be $min–$max characters');
    }
    return v;
  }

  static String _id(Map<String, dynamic> m) {
    final v = m['id'];
    if (v is! String || v.isEmpty) throw const FormatException('id missing');
    return v;
  }

  static UserFilm _readFilm(Map<String, dynamic> m) {
    final iso = m['box_iso'];
    if (iso is! int || iso < 1 || iso > 25600) {
      throw const FormatException('box_iso must be 1–25600');
    }
    return UserFilm(
      id: _id(m),
      brand: _text(m, 'brand', min: 1, max: 60),
      name: _text(m, 'name', min: 1, max: 80),
      boxIso: iso,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static UserDeveloper _readDeveloper(Map<String, dynamic> m) => UserDeveloper(
    id: _id(m),
    brand: _text(m, 'brand', min: 1, max: 60),
    name: _text(m, 'name', min: 1, max: 80),
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  static Process _readProcess(Map<String, dynamic> m) {
    final p = Process.fromJson(m);
    final problems = p.validate();
    if (problems.isNotEmpty) throw FormatException(problems.first);
    return p;
  }

  static ExchangeRecipe _readRecipe(Map<String, dynamic> m, ExchangeKind kind) {
    final id = _id(m);
    final version = m['version'];
    if (version is! int || version < 1) {
      throw const FormatException('version must be ≥ 1');
    }
    final devTime = m['dev_time_s'];
    if (devTime is! int || devTime < minDevTimeS || devTime > maxDevTimeS) {
      throw const FormatException('dev_time_s must be 30–7200');
    }
    final author = m['author_name'];
    if (author is! String || author.length > 60) {
      throw const FormatException('author_name must be a string of ≤ 60');
    }
    final ownership = kind == ExchangeKind.backup && m['ownership'] == 'own'
        ? Ownership.own
        : Ownership.received;
    final recipe = Recipe(
      id: id,
      version: version,
      createdAt: _time(m['created_at'], 'created_at'),
      updatedAt: _time(m['updated_at'], 'updated_at'),
      authorName: author,
      ownership: ownership,
      origin: RecipeOrigin.fromJson(_map(m['origin'])),
      key: CombinationKey.fromJson(_map(m['key'])),
      devTimeS: devTime,
      devAgitation: AgitationPattern.fromJson(_map(m['dev_agitation'])),
      process: m['process'] == null ? null : _readProcess(_map(m['process'])),
      hidden: kind == ExchangeKind.backup && m['hidden'] == true,
    );
    if (recipe.devAgitation.validate().isNotEmpty) {
      throw FormatException(recipe.devAgitation.validate().first);
    }
    final notes = [
      for (final n in _list(m['notes']))
        () {
          final nm = _map(n);
          return Note(
            id: _id(nm),
            recipeId: id,
            authorName: _text(nm, 'author_name', min: 0, max: 60),
            createdAt: _time(nm['created_at'], 'note created_at'),
            text: _text(nm, 'text', min: 1, max: maxNoteLength),
          );
        }(),
    ];
    return ExchangeRecipe(recipe, notes);
  }

  static ExchangeSession _readSession(Map<String, dynamic> m) {
    final status = m['status'];
    if (status != 'completed' && status != 'aborted') {
      throw const FormatException(
        'session status must be completed or aborted',
      );
    }
    final format = m['format'];
    if (format != '35mm' && format != '120') {
      throw const FormatException('session format must be 35mm or 120');
    }
    return ExchangeSession(
      id: _id(m),
      tankLabel: m['tank_label'] as String? ?? '',
      key: CombinationKey.fromJson(_map(m['key'])),
      timeSource: _map(m['time_source']),
      devTimeS: m['dev_time_s'] as int,
      format: format as String,
      status: status as String,
      startedAt: _time(m['started_at'], 'started_at'),
      abortedAtStep: m['aborted_at_step'] as int?,
      finishedAt: m['finished_at'] == null
          ? null
          : _time(m['finished_at'], 'finished_at'),
      stepDurationsS: [for (final d in _list(m['step_durations_s'])) d as int],
    );
  }
}
