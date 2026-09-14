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
