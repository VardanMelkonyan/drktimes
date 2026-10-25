import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SC-009: community times never enter the datasheet dataset. No community
/// code reads or writes the dataset files, and the dataset code never
/// imports community code.
void main() {
  Iterable<File> dart(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

  test('community code does not touch the dataset files', () {
    final files = [
      ...dart('lib/data/community'),
      ...dart('lib/domain/community'),
      ...dart('lib/features/community_sources'),
    ];
    expect(files, isNotEmpty);
    for (final f in files) {
      final text = f.readAsStringSync();
      expect(text, isNot(contains('devdata')), reason: f.path);
    }
  });

  test('the dataset code does not depend on community code', () {
    for (final f in [...dart('lib/devdata'), ...dart('lib/data/dataset')]) {
      expect(
        f.readAsStringSync(),
        isNot(contains('community')),
        reason: f.path,
      );
    }
  });
}
