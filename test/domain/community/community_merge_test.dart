import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/community/community_feed.dart';
import 'package:drktimes/domain/community/community_merge.dart';
import 'package:flutter_test/flutter_test.dart';

final key = CombinationKey(
  film: const FilmRef.catalog('f'),
  developer: const DeveloperRef.catalog('d'),
  dilution: 'stock',
  ei: 400,
  tempC: 20,
);

CommunityEntry e(String src, int t, int n, [int day = 1]) => CommunityEntry(
  key: key,
  timeS: t,
  installs: n,
  lastConfirmed: DateTime.utc(2026, 10, day),
  sourceId: src,
);

void main() {
  const order = [(id: 'a', name: 'Alpha'), (id: 'b', name: 'Beta')];

  test('grouped per source, never merged, in source order', () {
    final g = groupBySource([
      e('b', 500, 3),
      e('a', 600, 2),
      e('a', 610, 4),
    ], order);
    expect([for (final x in g) x.sourceName], ['Alpha', 'Beta']);
    expect([for (final x in g.first.entries) x.timeS], [610, 600]);
    expect(g.last.entries.single.installs, 3, reason: 'keeps its own count');
  });

  test('ties on installs go to the newest confirmation', () {
    final g = groupBySource([e('a', 500, 3, 1), e('a', 520, 3, 9)], order);
    expect([for (final x in g.single.entries) x.timeS], [520, 500]);
  });

  test('installs below 2 and unknown sources are never exposed', () {
    final g = groupBySource([
      e('a', 500, 1),
      e('zzz', 500, 5),
      e('a', 0, 0),
    ], order);
    expect(g, isEmpty);
  });
}
