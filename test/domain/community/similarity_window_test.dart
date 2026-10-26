import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-020: the similarity window is defined once. The server's value and the
/// documented one must not drift apart.
void main() {
  test('schema.sql uses the documented 1.08 ratio, once', () {
    final sql = File('supabase/schema.sql').readAsStringSync();
    expect(RegExp(r'select 1\.08::numeric').allMatches(sql), hasLength(1));
    expect(RegExp(r'\b1\.08\b').allMatches(sql), hasLength(1));
    final doc = File('specs/002-community-times/contracts/supabase-source.md')
        .readAsStringSync();
    expect(doc, contains('1.08'));
  });
}
