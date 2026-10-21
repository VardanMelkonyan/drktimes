import 'dart:convert';
import 'dart:io';

import 'package:drktimes/data/dataset/catalog.dart';
import 'package:drktimes/data/dataset/search_items.dart';
import 'package:drktimes/domain/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalise', () {
    test('lowercases, strips diacritics, spaces, hyphens, dots and +', () {
      expect(normaliseSearch('Tri-X'), 'trix');
      expect(normaliseSearch('HP5+'), 'hp5');
      expect(normaliseSearch('R09'), 'r09');
      expect(normaliseSearch('Delta 400'), 'delta400');
      expect(normaliseSearch('Adonal Café.'), 'adonalcafe');
      expect(normaliseSearch('Ørsted'), 'orsted');
    });
  });

  group('ranking', () {
    SearchItem item(
      String id,
      String brand,
      String name, {
      List<String> aliases = const [],
      bool current = true,
    }) => SearchItem(
      kind: SearchKind.film,
      id: id,
      brand: brand,
      name: name,
      aliases: aliases,
      current: current,
    );

    test('exact > prefix > word-prefix > substring', () {
      final index = SearchIndex([
        item('sub', 'A', 'Zxabc'),
        item('word', 'A', 'Foo abcd'),
        item('prefix', 'A', 'Abcde'),
        item('exact', 'A', 'Abc'),
      ]);
      expect(
        [for (final r in index.search('abc')) r.item.id],
        ['exact', 'prefix', 'word', 'sub'],
      );
    });

    test('ties: current before discontinued, then alphabetical', () {
      final index = SearchIndex([
        item('b', 'K', 'Alpha2', current: false),
        item('c', 'K', 'Alpha1'),
        item('a', 'K', 'Alpha3'),
      ]);
      expect(
        [for (final r in index.search('alpha')) r.item.id],
        ['c', 'a', 'b'],
      );
    });

    test('aliases match', () {
      final index = SearchIndex([
        item('x', 'Kodak', 'Tri-X 400', aliases: ['400TX']),
      ]);
      expect(index.search('400tx').single.item.id, 'x');
    });

    test('empty and unmatched queries give nothing', () {
      final index = SearchIndex([item('x', 'A', 'Name')]);
      expect(index.search(''), isEmpty);
      expect(index.search('zzz'), isEmpty);
    });

    test('synonyms rank below ordinary matches', () {
      final index = SearchIndex(
        [item('a', 'A', 'Foo ID-11'), item('b', 'B', 'D-76 Kit')],
        synonyms: const {
          'd76': ['id11'],
        },
      );
      final ids = [for (final r in index.search('d76')) r.item.id];
      expect(ids, ['b', 'a']);
    });
  });

  group('SC-012 against the real catalogue', () {
    final catalog = Catalog.fromJson(
      jsonDecode(File('assets/devdata.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final synonyms =
        (jsonDecode(
            File('assets/search_synonyms.json').readAsStringSync(),
          ) as Map<String, dynamic>).map(
            (k, v) =>
                MapEntry(k, v is List ? List<String>.from(v) : <String>[]),
          )
          ..remove('_comment');
    final index = SearchIndex(searchItemsFor(catalog), synonyms: synonyms);

    void top3(String query, String id, SearchKind kind) {
      final ids = [
        for (final r in index.search(query).take(3))
          '${r.item.kind.name}:${r.item.id}',
      ];
      expect(ids, contains('${kind.name}:$id'), reason: query);
    }

    test('trix', () => top3('trix', 'kodak-tri-x-400', SearchKind.film));
    test('hp5', () => top3('hp5', 'ilford-hp5-plus', SearchKind.film));
    test(
      'delta 400',
      () => top3('delta 400', 'ilford-delta-400', SearchKind.film),
    );
    test('R09', () => top3('R09', 'rodinal', SearchKind.developer));
    test('rodinal', () => top3('rodinal', 'rodinal', SearchKind.developer));
  });
}
