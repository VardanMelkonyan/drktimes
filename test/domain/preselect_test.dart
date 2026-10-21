import 'package:drktimes/data/dataset/datasheet_time.dart';
import 'package:drktimes/devdata/models.dart';
import 'package:drktimes/domain/preselect.dart';
import 'package:flutter_test/flutter_test.dart';

Source src(String id, {String? edition, String? retrieved}) => Source(
  id: id,
  kind: 'manufacturer',
  publisher: 'P',
  title: 'T $id',
  edition: edition,
  retrieved: retrieved,
);

DatasheetTime ds(
  String sourceId,
  int timeS, {
  int? max,
  String method = 'small_tank',
  String? edition,
  String? retrieved,
  int page = 1,
}) => DatasheetTime(
  filmId: 'f',
  developerId: 'd',
  dilution: '1+50',
  ei: 400,
  tempC: 20,
  timeS: timeS,
  timeMaxS: max,
  method: method,
  page: page,
  source: src(sourceId, edition: edition, retrieved: retrieved),
);

RecipeCandidate recipe(
  String id,
  int timeS, {
  bool own = true,
  DateTime? updated,
  DateTime? imported,
  bool hidden = false,
  int version = 1,
}) => RecipeCandidate(
  id: id,
  own: own,
  timeS: timeS,
  version: version,
  updatedAt: updated ?? DateTime.utc(2026, 1, 1),
  importedAt: imported,
  hidden: hidden,
);

void main() {
  final older = ds('old', 540, edition: 'November 2018');
  final newer = ds('new', 570, edition: 'August 2019', page: 4);

  test('1. the latest session’s datasheet source', () {
    final p = preselect(
      latestSessionSource: {'kind': 'datasheet', 'source_id': 'old'},
      datasheet: [older, newer],
      recipes: const [],
    )!;
    expect(p.branch, PreselectBranch.lastUsed);
    expect(p.timeS, 540);
    expect(p.timeSource['source_id'], 'old');
  });

  test('1. an edited recipe resolves to its current version', () {
    final p = preselect(
      latestSessionSource: {
        'kind': 'recipe',
        'recipe_id': 'r1',
        'recipe_version': 1,
      },
      datasheet: [older],
      recipes: [recipe('r1', 600, version: 3)],
    )!;
    expect(p.branch, PreselectBranch.lastUsed);
    expect(p.timeS, 600);
    expect(p.timeSource['recipe_version'], 3);
  });

  test('1. falls through when the source is hidden or gone', () {
    final hidden = preselect(
      latestSessionSource: {'kind': 'recipe', 'recipe_id': 'r1'},
      datasheet: [older, newer],
      recipes: [recipe('r1', 600, hidden: true)],
    )!;
    expect(hidden.branch, PreselectBranch.datasheet);
    final gone = preselect(
      latestSessionSource: {'kind': 'datasheet', 'source_id': 'vanished'},
      datasheet: [older],
      recipes: const [],
    )!;
    expect(gone.branch, PreselectBranch.datasheet);
  });

  test('2. the primary datasheet time from the newest source', () {
    final p = preselect(
      latestSessionSource: null,
      datasheet: [older, newer],
      recipes: [recipe('r', 1)],
    )!;
    expect(p.branch, PreselectBranch.datasheet);
    expect(p.timeS, 570);
    expect(p.timeSource, {'kind': 'datasheet', 'source_id': 'new', 'page': 4});
  });

  test('2. a range uses the midpoint, and non-primary rows are ignored', () {
    final range = ds('r', 420, max: 480, edition: 'July 2020');
    final rotary = ds('x', 300, method: 'rotary', edition: 'July 2023');
    final p = preselect(
      latestSessionSource: null,
      datasheet: [range, rotary],
      recipes: [],
    )!;
    expect(p.timeS, 450);
    expect(p.timeSource['source_id'], 'r');
  });

  test('2. sources without an edition fall back to retrieval date', () {
    final a = ds('a', 500, retrieved: '2026-01-01');
    final b = ds('b', 510, retrieved: '2026-09-01');
    expect(
      preselect(
        latestSessionSource: null,
        datasheet: [a, b],
        recipes: [],
      )!.timeS,
      510,
    );
  });

  test('3. otherwise the own recipe updated most recently', () {
    final p = preselect(
      latestSessionSource: null,
      datasheet: [],
      recipes: [
        recipe('a', 500, updated: DateTime.utc(2026, 2, 1)),
        recipe('b', 520, updated: DateTime.utc(2026, 5, 1)),
        recipe('c', 999, own: false, imported: DateTime.utc(2026, 9, 1)),
      ],
    )!;
    expect(p.branch, PreselectBranch.ownRecipe);
    expect(p.timeS, 520);
    expect(p.timeSource['recipe_id'], 'b');
  });

  test('4. otherwise the received recipe imported most recently', () {
    final p = preselect(
      latestSessionSource: null,
      datasheet: [],
      recipes: [
        recipe('a', 500, own: false, imported: DateTime.utc(2026, 2, 1)),
        recipe('b', 520, own: false, imported: DateTime.utc(2026, 5, 1)),
        recipe(
          'c',
          1,
          own: false,
          imported: DateTime.utc(2026, 9, 1),
          hidden: true,
        ),
      ],
    )!;
    expect(p.branch, PreselectBranch.receivedRecipe);
    expect(p.timeS, 520);
  });

  test('nothing at all gives null', () {
    expect(
      preselect(latestSessionSource: null, datasheet: [], recipes: []),
      isNull,
    );
  });
}
