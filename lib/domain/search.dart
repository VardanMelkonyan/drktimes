enum SearchKind { film, developer }

/// Lower-case, strip diacritics, and drop spaces, hyphens, dots and `+`
/// (research R9): "Tri-X" → `trix`, "HP5+" → `hp5`.
String normaliseSearch(String input) {
  final b = StringBuffer();
  for (final r in input.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final folded = _diacritics[c] ?? c;
    for (final ch in folded.split('')) {
      if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
        b.write(ch);
      } else if (!RegExp(r'[\s\-.+_/·,]').hasMatch(ch) &&
          ch.codeUnitAt(0) > 127) {
        b.write(ch);
      }
    }
  }
  return b.toString();
}

const _diacritics = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ç': 'c',
  'č': 'c',
  'ć': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ń': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'š': 's',
  'ś': 's',
  'ž': 'z',
  'ź': 'z',
  'ß': 'ss',
};

class SearchItem {
  const SearchItem({
    required this.kind,
    required this.id,
    required this.brand,
    required this.name,
    this.aliases = const [],
    this.current = true,
    this.userAdded = false,
  });

  final SearchKind kind;
  final String id;
  final String brand, name;
  final List<String> aliases;

  /// Catalogue status: current sorts before discontinued.
  final bool current;
  final bool userAdded;

  String get display => '$brand $name';
}

class SearchResult {
  const SearchResult(this.item, this.tier);

  final SearchItem item;

  /// 0 exact, 1 prefix, 2 word prefix, 3 substring, 4 synonym.
  final int tier;
}

class _Variant {
  const _Variant(this.text, this.words);

  final String text;
  final List<String> words;
}

class _Indexed {
  _Indexed(this.item) {
    final names = [item.name, ...item.aliases];
    for (final n in names) {
      variants.add(_Variant(normaliseSearch(n), _words(n)));
      variants.add(
        _Variant(
          normaliseSearch('${item.brand} $n'),
          _words('${item.brand} $n'),
        ),
      );
    }
  }

  final SearchItem item;
  final variants = <_Variant>[];

  static List<String> _words(String s) => [
    for (final w in s.split(RegExp(r'[\s\-/]+')))
      if (normaliseSearch(w).isNotEmpty) normaliseSearch(w),
  ];
}

/// In-memory index over films and developers (catalogue plus user-added).
class SearchIndex {
  SearchIndex(
    Iterable<SearchItem> items, {
    this.synonyms = const <String, List<String>>{},
  }) : _items = [for (final i in items) _Indexed(i)];

  final List<_Indexed> _items;

  /// Normalised query → other normalised terms to find.
  final Map<String, List<String>> synonyms;

  List<SearchResult> search(String query) {
    final q = normaliseSearch(query);
    if (q.isEmpty) return const [];
    final extra = [
      for (final s in synonyms[q] ?? const <String>[]) normaliseSearch(s),
    ];
    final scored = <(SearchResult, double)>[];
    for (final it in _items) {
      var best = 99;
      var ratio = 0.0;
      for (final v in it.variants) {
        final t = _tier(v, q);
        if (t < best || (t == best && q.length / v.text.length > ratio)) {
          best = t;
          ratio = q.length / v.text.length;
        }
      }
      if (best == 99) {
        for (final e in extra) {
          for (final v in it.variants) {
            if (v.text.contains(e)) {
              best = 4;
              ratio = e.length / v.text.length;
            }
          }
        }
      }
      if (best != 99) scored.add((SearchResult(it.item, best), ratio));
    }
    scored.sort((a, b) {
      final t = a.$1.tier.compareTo(b.$1.tier);
      if (t != 0) return t;
      final r = b.$2.compareTo(a.$2);
      if (r != 0) return r;
      if (a.$1.item.current != b.$1.item.current) {
        return a.$1.item.current ? -1 : 1;
      }
      return a.$1.item.display.compareTo(b.$1.item.display);
    });
    return [for (final s in scored) s.$1];
  }

  int _tier(_Variant v, String q) {
    if (v.text == q) return 0;
    if (v.text.startsWith(q)) return 1;
    for (final w in v.words.skip(1)) {
      if (w.startsWith(q)) return 2;
    }
    if (v.text.contains(q)) return 3;
    return 99;
  }
}
