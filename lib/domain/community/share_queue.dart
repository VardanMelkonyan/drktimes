/// One pending submission to one source (FR-003a). The payload is rebuilt
/// from [keyCanonical] and [timeS] at send time.
class QueueItem {
  const QueueItem({
    required this.id,
    required this.sourceId,
    required this.keyCanonical,
    required this.timeS,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id, sourceId, keyCanonical;
  final int timeS, attempts;
  final DateTime createdAt;

  String get dedupeKey => '$sourceId|$keyCanonical|$timeS';
}

/// The items of [incoming] not already in [existing] and not repeated within
/// [incoming]: a combination and time is queued once per source.
List<QueueItem> newItems(
  Iterable<QueueItem> existing,
  Iterable<QueueItem> incoming,
) {
  final seen = {for (final e in existing) e.dedupeKey};
  return [
    for (final i in incoming)
      if (seen.add(i.dedupeKey)) i,
  ];
}

/// Send order: fewest failed attempts first, then oldest, so one stuck item
/// never blocks the rest.
List<QueueItem> sendOrder(Iterable<QueueItem> items) =>
    [...items]..sort((a, b) {
      final c = a.attempts.compareTo(b.attempts);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
