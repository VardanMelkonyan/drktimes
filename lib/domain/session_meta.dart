import 'combination_key.dart';

/// What a session was started from: the combination (absent for a manually
/// typed time), where the time came from, the film format and tank volume.
class SessionMeta {
  const SessionMeta({
    this.key,
    this.timeSource = const {'kind': 'manual'},
    this.format = '35mm',
    this.volumeMl = 300,
  });

  factory SessionMeta.fromJson(Map<String, dynamic> j) => SessionMeta(
    key: j['key'] == null
        ? null
        : CombinationKey.fromJson(j['key'] as Map<String, dynamic>),
    timeSource: Map<String, dynamic>.from(
      j['time_source'] as Map? ?? const {'kind': 'manual'},
    ),
    format: j['format'] as String? ?? '35mm',
    volumeMl: j['volume_ml'] as int? ?? 300,
  );

  final CombinationKey? key;

  /// `{kind: datasheet, source_id, page?}`, `{kind: recipe, recipe_id,
  /// recipe_version}` or `{kind: manual, label?}`.
  final Map<String, dynamic> timeSource;
  final String format;
  final int volumeMl;

  Map<String, dynamic> toJson() => {
    if (key != null) 'key': key!.toJson(),
    'time_source': timeSource,
    'format': format,
    'volume_ml': volumeMl,
  };
}
