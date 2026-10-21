import '../../devdata/models.dart';

/// A published time on a combination page, with its source (FR-010–FR-012).
class DatasheetTime {
  const DatasheetTime({
    required this.filmId,
    required this.developerId,
    required this.dilution,
    required this.ei,
    required this.tempC,
    required this.timeS,
    required this.method,
    required this.source,
    this.timeMaxS,
    this.page,
    this.agitationText,
    this.notes,
    this.inheritedFromFilmId,
    this.rebrandBasis,
  });

  /// A bare row for tests and previews.
  DatasheetTime.test({required this.timeS, required this.method, this.timeMaxS})
    : filmId = 'f',
      developerId = 'd',
      dilution = 'stock',
      ei = 100,
      tempC = 20,
      source = const Source(
        id: 's',
        kind: 'manufacturer',
        publisher: 'P',
        title: 'T',
      ),
      page = null,
      agitationText = null,
      notes = null,
      inheritedFromFilmId = null,
      rebrandBasis = null;

  final String filmId, developerId, dilution, method;
  final int ei, tempC, timeS;
  final int? timeMaxS, page;
  final Source source;
  final String? agitationText, notes;

  /// Set when the time is shown through a rebrand (FR-013).
  final String? inheritedFromFilmId;

  /// `official` or `reported`, set together with [inheritedFromFilmId].
  final String? rebrandBasis;

  /// Midpoint of a range, rounded to 15 s (FR-011).
  int get defaultRunTimeS =>
      timeMaxS == null ? timeS : ((timeS + timeMaxS!) / 2 / 15).round() * 15;

  bool get isPrimary => method == 'small_tank';
}
