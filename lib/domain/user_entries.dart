class UserFilm {
  const UserFilm({
    required this.id,
    required this.brand,
    required this.name,
    required this.boxIso,
    required this.createdAt,
    this.matchedCatalogId,
  });

  final String id, brand, name;
  final int boxIso;
  final String? matchedCatalogId;
  final DateTime createdAt;
}

class UserDeveloper {
  const UserDeveloper({
    required this.id,
    required this.brand,
    required this.name,
    required this.createdAt,
    this.matchedCatalogId,
  });

  final String id, brand, name;
  final String? matchedCatalogId;
  final DateTime createdAt;
}
