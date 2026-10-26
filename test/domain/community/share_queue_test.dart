import 'package:drktimes/domain/community/share_queue.dart';
import 'package:flutter_test/flutter_test.dart';

QueueItem q(String id, String src, int t, {int attempts = 0, int sec = 0}) =>
    QueueItem(
      id: id,
      sourceId: src,
      keyCanonical: 'k',
      timeS: t,
      createdAt: DateTime.utc(2026, 1, 1, 0, 0, sec),
      attempts: attempts,
    );

void main() {
  test('items already queued or repeated in the batch are skipped', () {
    final fresh = newItems(
      [q('1', 'a', 500)],
      [q('2', 'a', 500), q('3', 'a', 510), q('4', 'a', 510), q('5', 'b', 500)],
    );
    expect([for (final i in fresh) i.id], ['3', '5']);
  });

  test('send order: fewest attempts first, then oldest', () {
    final o = sendOrder([
      q('old-failed', 'a', 1, attempts: 2, sec: 0),
      q('new', 'a', 2, sec: 9),
      q('old', 'a', 3, sec: 1),
    ]);
    expect([for (final i in o) i.id], ['old', 'new', 'old-failed']);
  });
}
