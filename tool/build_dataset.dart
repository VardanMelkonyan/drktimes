// Compiles resources/devdata into the app's bundled dataset asset.
//
//   dart run tool/build_dataset.dart
//
// Fails on any validator error. Writes assets/devdata.json and
// assets/devdata.meta.json.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drktimes/devdata/loader.dart';
import 'package:drktimes/devdata/validator.dart';

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'resources/devdata' : args.first);
  final errors = validate(loadDataset(dir));
  if (errors.isNotEmpty) {
    errors.forEach(stderr.writeln);
    stderr.writeln('${errors.length} validation errors; nothing written');
    exitCode = 1;
    return;
  }

  Object? read(String file) =>
      jsonDecode(File('${dir.path}/$file').readAsStringSync());
  List<Object?> list(String file, String key) =>
      (read(file) as Map<String, dynamic>)[key] as List<Object?>;

  final timeFiles = Directory('${dir.path}/times')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final times = [
    for (final f in timeFiles)
      {
        'source_id': (jsonDecode(f.readAsStringSync())
            as Map<String, dynamic>)['source_id'],
        'times': (jsonDecode(f.readAsStringSync())
            as Map<String, dynamic>)['times'],
      },
  ];

  final today = DateTime.now().toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final version = args.length > 1
      ? args[1]
      : '${today.year}.${two(today.month)}.${two(today.day)}-1';

  final body = jsonEncode({
    'schema_version': 1,
    'dataset_version': version,
    'films': list('films.json', 'films'),
    'developers': list('developers.json', 'developers'),
    'sources': list('sources.json', 'sources'),
    'times': times,
  });
  File('assets/devdata.json').writeAsStringSync(body);
  final bytes = utf8.encode(body);
  File('assets/devdata.meta.json').writeAsStringSync(jsonEncode({
    'dataset_version': version,
    'sha256': sha256.convert(bytes).toString(),
    'bytes': bytes.length,
  }));
  stdout.writeln('assets/devdata.json: $version, ${bytes.length} bytes');
}
