import '../combination_key.dart';
import 'submission.dart';

/// One confirmed community time (spec 002, FR-016, FR-019a).
class CommunityEntry {
  const CommunityEntry({
    required this.key,
    required this.timeS,
    required this.installs,
    required this.lastConfirmed,
    this.sourceId = '',
  });

  final CombinationKey key;
  final int timeS, installs;
  final DateTime lastConfirmed;
  final String sourceId;
}

class CommunityFeed {
  const CommunityFeed({required this.entries, this.name});

  final List<CommunityEntry> entries;

  /// The source's suggested name; the user's own name wins.
  final String? name;

  /// Parses a feed document per `contracts/community-feed.schema.json`.
  /// Entries that fail validation are dropped, not repaired; unknown fields
  /// are ignored. When [filmIds] / [developerIds] are given, entries naming
  /// an id outside them are dropped too. Throws [FormatException] when the
  /// document itself is not a feed.
  static CommunityFeed parse(
    Object? json, {
    Set<String>? filmIds,
    Set<String>? developerIds,
  }) {
    if (json is! Map ||
        json['format'] != 'drktimes-community-feed' ||
        json['format_version'] is! int ||
        (json['format_version'] as int) < 1 ||
        json['entries'] is! List) {
      throw const FormatException('not a drktimes community feed');
    }
    final name = json['name'];
    final out = <CommunityEntry>[];
    for (final e in json['entries'] as List) {
      final entry = _entry(e, filmIds, developerIds);
      if (entry != null) out.add(entry);
    }
    return CommunityFeed(
      entries: out,
      name: name is String && name.isNotEmpty && name.length <= 60
          ? name
          : null,
    );
  }

  static final _id = RegExp(r'^[a-z0-9][a-z0-9-]{0,79}$');

  static CommunityEntry? _entry(
    Object? e,
    Set<String>? films,
    Set<String>? devs,
  ) {
    if (e is! Map) return null;
    final film = e['film_id'], dev = e['developer_id'];
    final dilution = e['dilution'];
    final ei = e['ei'], temp = e['temp_c'], time = e['time_s'];
    final installs = e['installs'];
    if (film is! String ||
        dev is! String ||
        dilution is! String ||
        ei is! int ||
        temp is! int ||
        time is! int ||
        installs is! int) {
      return null;
    }
    if (!_id.hasMatch(film) ||
        !_id.hasMatch(dev) ||
        (films != null && !films.contains(film)) ||
        (devs != null && !devs.contains(dev)) ||
        time < minSubmitTimeS ||
        time > maxSubmitTimeS ||
        installs < 2) {
      return null;
    }
    final CombinationKey key;
    try {
      key = CombinationKey(
        film: FilmRef.catalog(film),
        developer: DeveloperRef.catalog(dev),
        dilution: dilution,
        ei: ei,
        tempC: temp,
      );
    } on ArgumentError {
      return null;
    }
    // CombinationKey normalises; the feed contract requires the normal form.
    if (key.dilution != dilution) return null;
    final at = e['last_confirmed'];
    return CommunityEntry(
      key: key,
      timeS: time,
      installs: installs,
      lastConfirmed:
          (at is String ? DateTime.tryParse(at) : null) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
