import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drktimes/data/dataset/dataset_updater.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final body = File('assets/devdata.json').readAsStringSync();
  String manifest({
    String version = '2099.01.01-1',
    String? sha,
    String min = '0.1.0',
  }) => jsonEncode({
    'format': 'drktimes-dataset-manifest',
    'format_version': '1.0',
    'dataset_version': version,
    'url': 'https://h/d.json',
    'sha256': sha ?? sha256.convert(utf8.encode(body)).toString(),
    'bytes': body.length,
    'min_app_version': min,
  });

  DatasetUpdater updater(String m, String data) => DatasetUpdater(
    MockClient(
      (r) async => r.url.path == '/m.json'
          ? http.Response(m, 200)
          : http.Response.bytes(utf8.encode(data), 200),
    ),
    manifestUrl: Uri.parse('https://h/m.json'),
    appVersion: '0.1.0',
  );

  test('a newer, valid, matching dataset is accepted', () async {
    expect(await updater(manifest(), body).check('2026.10.21-1'), body);
  });

  test('older or equal version is ignored', () async {
    expect(
      await updater(
        manifest(version: '2026.10.21-1'),
        body,
      ).check('2026.10.21-1'),
      isNull,
    );
  });

  test('bad sha is rejected', () async {
    expect(
      await updater(manifest(sha: 'abc'), body).check('2026.10.21-1'),
      isNull,
    );
  });

  test('a dataset that fails the validator is rejected', () async {
    final j = jsonDecode(body) as Map<String, dynamic>;
    (j['times'] as List).first['times'][0]['film_id'] = 'no-such-film';
    final bad = jsonEncode(j);
    final m = manifest(sha: sha256.convert(utf8.encode(bad)).toString());
    expect(await updater(m, bad).check('2026.10.21-1'), isNull);
  });

  test(
    'a too-new min_app_version is skipped; network errors are silent',
    () async {
      expect(
        await updater(manifest(min: '9.0.0'), body).check('2026.10.21-1'),
        isNull,
      );
      final failing = DatasetUpdater(
        MockClient((_) async => throw const SocketException('x')),
        manifestUrl: Uri.parse('https://h/m.json'),
        appVersion: '0.1.0',
      );
      expect(await failing.check('2026.10.21-1'), isNull);
    },
  );
}
