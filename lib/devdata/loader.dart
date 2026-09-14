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
