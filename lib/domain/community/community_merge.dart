import 'community_feed.dart';

/// The entries of one source for one combination (FR-017): sources are
/// never merged into one another.
class CommunityGroup {
  const CommunityGroup(this.sourceId, this.sourceName, this.entries);

  final String sourceId, sourceName;
  final List<CommunityEntry> entries;
}

/// Groups [entries] per source, in [sourceOrder]; within a group the
/// best-backed time comes first, ties broken by newest confirmation. Entries
/// with fewer than two installs, or from a source not in [sourceOrder], are
/// never exposed (FR-019a).
List<CommunityGroup> groupBySource(
  Iterable<CommunityEntry> entries,
  List<({String id, String name})> sourceOrder,
) {
  final out = <CommunityGroup>[];
  for (final s in sourceOrder) {
    final mine = [
      for (final e in entries)
        if (e.sourceId == s.id && e.installs >= 2) e,
    ]..sort(compareBest);
    if (mine.isNotEmpty) out.add(CommunityGroup(s.id, s.name, mine));
  }
  return out;
}

/// Most installs first, then newest `lastConfirmed` (FR-019b).
int compareBest(CommunityEntry a, CommunityEntry b) {
  final c = b.installs.compareTo(a.installs);
  return c != 0 ? c : b.lastConfirmed.compareTo(a.lastConfirmed);
}
