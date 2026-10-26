import 'dart:convert';
import 'dart:io';

import 'package:drktimes/domain/community/community_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

Map<String, dynamic> entry([Map<String, dynamic> over = const {}]) => {
  'film_id': 'tri-x',
  'developer_id': 'd76',
  'dilution': '1+1',
  'ei': 400,
  'temp_c': 20,
  'time_s': 540,
  'installs': 3,
  'last_confirmed': '2026-10-01T00:00:00Z',
  ...over,
};

Map<String, dynamic> feed(List<Map<String, dynamic>> entries) => {
  'format': 'drktimes-community-feed',
  'format_version': 1,
  'name': 'Test',
  'unknown': true,
  'entries': entries,
};

void main() {
  final schema = JsonSchema.create(
    jsonDecode(
      File('specs/002-community-times/contracts/community-feed.schema.json')
          .readAsStringSync(),
    ) as Object,
  );

  test('a valid feed passes the contract schema and parses', () {
    final doc = feed([entry()]);
    expect(schema.validate(doc).isValid, isTrue);
    final f = CommunityFeed.parse(doc);
    expect(f.name, 'Test');
    expect(f.entries.single.timeS, 540);
    expect(f.entries.single.installs, 3);
    expect(
      f.entries.single.key.canonical,
      'catalog:tri-x|catalog:d76|1+1|400|20',
    );
  });

  test('invalid entries are dropped', () {
    final bad = <Map<String, dynamic>>[
      entry({'dilution': 'banana'}),
      entry({'ei': 0}),
      entry({'ei': 25601}),
      entry({'temp_c': 9}),
      entry({'temp_c': 46}),
      entry({'time_s': 29}),
      entry({'time_s': 10801}),
      entry({'installs': 1}),
      entry({'film_id': 'Bad Id'}),
      entry({'ei': '400'}),
      entry({'dilution': '1:1'}),
    ];
    final f = CommunityFeed.parse(feed([...bad, entry()]));
    expect(f.entries, hasLength(1));
  });

  test('ids outside the supplied catalog are dropped', () {
    final doc = feed([
      entry(),
      entry({'film_id': 'unknown-film'}),
    ]);
    final f = CommunityFeed.parse(
      doc,
      filmIds: {'tri-x'},
      developerIds: {'d76'},
    );
    expect(f.entries, hasLength(1));
  });

  test('a document that is not a feed throws', () {
    expect(
      () => CommunityFeed.parse({'entries': <Object>[]}),
      throwsFormatException,
    );
    expect(() => CommunityFeed.parse('x'), throwsFormatException);
  });
}
