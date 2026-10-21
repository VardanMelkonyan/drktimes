import '../../domain/search.dart';
import 'catalog.dart';

/// Search items for every film and developer in the catalogue.
List<SearchItem> searchItemsFor(Catalog catalog) => [
  for (final f in catalog.films)
    SearchItem(
      kind: SearchKind.film,
      id: f.id,
      brand: f.brand,
      name: f.name,
      aliases: f.aliases,
      current: f.status == 'current',
    ),
  for (final d in catalog.developers)
    SearchItem(
      kind: SearchKind.developer,
      id: d.id,
      brand: d.brand,
      name: d.name,
      aliases: d.aliases,
    ),
];
