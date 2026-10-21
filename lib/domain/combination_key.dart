enum RefKind { catalog, user }

class _Ref {
  const _Ref(this.kind, this.id);

  final RefKind kind;
  final String id;

  Map<String, dynamic> toJson() => {'kind': kind.name, 'id': id};

  @override
  bool operator ==(Object other) =>
      other is _Ref &&
      other.runtimeType == runtimeType &&
      other.kind == kind &&
      other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, kind, id);

  @override
  String toString() => '${kind.name}:$id';
}

class FilmRef extends _Ref {
  const FilmRef.catalog(String id) : super(RefKind.catalog, id);
  const FilmRef.user(String id) : super(RefKind.user, id);

  factory FilmRef.fromJson(Map<String, dynamic> json) => FilmRef._(json);

  FilmRef._(Map<String, dynamic> json)
    : super(
        RefKind.values.byName(json['kind'] as String),
        json['id'] as String,
      );
}

class DeveloperRef extends _Ref {
  const DeveloperRef.catalog(String id) : super(RefKind.catalog, id);
  const DeveloperRef.user(String id) : super(RefKind.user, id);

  factory DeveloperRef.fromJson(Map<String, dynamic> json) =>
      DeveloperRef._(json);

  DeveloperRef._(Map<String, dynamic> json)
    : super(
        RefKind.values.byName(json['kind'] as String),
        json['id'] as String,
      );
}

final _dilutionPattern = RegExp(
  r'^(stock|working|1(\+[0-9]+(\.[0-9]+)?){1,2})$',
);

/// `1:50`, `1/50`, `1 + 50` → `1+50`; `Stock` → `stock` (FR-016).
String normaliseDilution(String raw) {
  final s = raw.trim().toLowerCase();
  if (s == 'stock' || s == 'working') return s;
  return s.replaceAll(RegExp(r'\s*[:/+]\s*'), '+');
}

/// `round((F − 32) × 5/9)` (FR-073).
int fahrenheitToCelsius(num f) => ((f - 32) * 5 / 9).round();

class CombinationKey {
  CombinationKey({
    required this.film,
    required this.developer,
    required String dilution,
    required this.ei,
    required this.tempC,
  }) : dilution = normaliseDilution(dilution) {
    if (!_dilutionPattern.hasMatch(this.dilution)) {
      throw ArgumentError.value(dilution, 'dilution', 'not a valid dilution');
    }
    if (ei < 1 || ei > 25600) {
      throw ArgumentError.value(ei, 'ei', 'must be 1–25600');
    }
    if (tempC < 10 || tempC > 45) {
      throw ArgumentError.value(tempC, 'tempC', 'must be 10–45');
    }
  }

  factory CombinationKey.fromJson(Map<String, dynamic> json) => CombinationKey(
    film: FilmRef.fromJson(json['film'] as Map<String, dynamic>),
    developer: DeveloperRef.fromJson(json['developer'] as Map<String, dynamic>),
    dilution: json['dilution'] as String,
    ei: json['ei'] as int,
    tempC: json['temp_c'] as int,
  );

  final FilmRef film;
  final DeveloperRef developer;
  final String dilution;
  final int ei;
  final int tempC;

  /// `film|developer|dilution|ei|temp_c`; refs are written as `kind:id`.
  String get canonical => '$film|$developer|$dilution|$ei|$tempC';

  Map<String, dynamic> toJson() => {
    'film': film.toJson(),
    'developer': developer.toJson(),
    'dilution': dilution,
    'ei': ei,
    'temp_c': tempC,
  };

  @override
  bool operator ==(Object other) =>
      other is CombinationKey && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}
