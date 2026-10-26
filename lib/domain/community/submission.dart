import '../combination_key.dart';

const minSubmitTimeS = 30;
const maxSubmitTimeS = 10800;

/// What a device sends for one developed combination (FR-004): exactly these
/// fields. The contribution ID is added by the source at send time.
class Submission {
  const Submission({
    required this.filmId,
    required this.developerId,
    required this.dilution,
    required this.ei,
    required this.tempC,
    required this.timeS,
  });

  /// Null unless the key is catalog-only and the time is plausible (FR-009).
  static Submission? from(CombinationKey key, int timeS) {
    if (key.film.kind != RefKind.catalog ||
        key.developer.kind != RefKind.catalog ||
        timeS < minSubmitTimeS ||
        timeS > maxSubmitTimeS) {
      return null;
    }
    return Submission(
      filmId: key.film.id,
      developerId: key.developer.id,
      dilution: key.dilution,
      ei: key.ei,
      tempC: key.tempC,
      timeS: timeS,
    );
  }

  /// Rebuilds a submission from a queued `CombinationKey.canonical`
  /// (`catalog:film|catalog:dev|dilution|ei|temp`); null if it is not one.
  static Submission? fromCanonical(String canonical, int timeS) {
    final p = canonical.split('|');
    if (p.length != 5 ||
        !p[0].startsWith('catalog:') ||
        !p[1].startsWith('catalog:')) {
      return null;
    }
    final ei = int.tryParse(p[3]), temp = int.tryParse(p[4]);
    if (ei == null || temp == null) return null;
    return Submission(
      filmId: p[0].substring(8),
      developerId: p[1].substring(8),
      dilution: p[2],
      ei: ei,
      tempC: temp,
      timeS: timeS,
    );
  }

  final String filmId, developerId, dilution;
  final int ei, tempC, timeS;

  Map<String, dynamic> toJson() => {
    'film_id': filmId,
    'developer_id': developerId,
    'dilution': dilution,
    'ei': ei,
    'temp_c': tempC,
    'time_s': timeS,
  };
}
