import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../devdata/models.dart';
import '../../devdata/validator.dart';

/// Optional dataset updates (FR-064, contracts/links-and-files.md §5). The only
/// two requests the app ever makes: the manifest, then the file it names.
/// Every failure keeps the current dataset, silently.
class DatasetUpdater {
  DatasetUpdater(
    this._client, {
    required this.manifestUrl,
    required this.appVersion,
  });

  final http.Client _client;
  final Uri manifestUrl;
  final String appVersion;

  /// Returns the new compiled dataset text when an update passes every check,
  /// else null. [currentVersion] is `YYYY.MM.DD-n`.
  Future<String?> check(String currentVersion) async {
    try {
      final m = jsonDecode(
        (await _client.get(manifestUrl)).body,
      ) as Map<String, dynamic>;
      if (m['format'] != 'drktimes-dataset-manifest') return null;
      if (_cmp(m['dataset_version'] as String, currentVersion) <= 0)
        return null;
      if (_cmp(appVersion, m['min_app_version'] as String) < 0) return null;
      final res = await _client.get(Uri.parse(m['url'] as String));
      if (res.statusCode != 200) return null;
      if (sha256.convert(res.bodyBytes).toString() != m['sha256']) return null;
      if (validate(
        _parse(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>),
      ).isNotEmpty) {
        return null;
      }
      return utf8.decode(res.bodyBytes);
    } on Object {
      return null;
    }
  }

  /// Writes [text] next to [target] and renames it over, so a crash never
  /// leaves a half-written dataset.
  static Future<void> swapIn(File target, String text) async {
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(target.path);
  }

  static Dataset _parse(Map<String, dynamic> j) => Dataset(
    films: [
      for (final f in j['films'] as List)
        Film.fromJson(f as Map<String, dynamic>),
    ],
    developers: [
      for (final d in j['developers'] as List)
        Developer.fromJson(d as Map<String, dynamic>),
    ],
    sources: [
      for (final s in j['sources'] as List)
        Source.fromJson(s as Map<String, dynamic>),
    ],
    times: [
      for (final g in j['times'] as List)
        for (final t in (g as Map<String, dynamic>)['times'] as List)
          DevTime.fromJson(t as Map<String, dynamic>, g['source_id'] as String),
    ],
  );

  /// Compares dotted/dashed numeric versions: `2026.10.21-2` vs `2026.10.21-1`.
  static int _cmp(String a, String b) {
    List<int> n(String v) =>
        v.split(RegExp(r'[.\-]')).map((x) => int.tryParse(x) ?? 0).toList();
    final x = n(a), y = n(b);
    for (var i = 0; i < x.length || i < y.length; i++) {
      final d = (i < x.length ? x[i] : 0).compareTo(i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }
}
