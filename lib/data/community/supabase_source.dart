import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/community/community_feed.dart';
import '../../domain/community/submission.dart';
import 'community_source.dart';

const _timeout = Duration(seconds: 15);

/// The project source: two RPC calls over plain HTTP, no SDK. The key is the
/// public anon key, which can execute only `submit_time` and `community_feed`.
class SupabaseSource implements CommunitySource {
  SupabaseSource({
    required this.id,
    required this.name,
    required this.url,
    required this.publicKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  final String id, name;
  final String url, publicKey;
  final http.Client _client;

  @override
  bool get canSubmit => true;

  Uri _rpc(String fn) =>
      Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/rpc/$fn');

  Map<String, String> get _headers => {
    'apikey': publicKey,
    'Content-Type': 'application/json',
  };

  @override
  Future<CommunityFeed> fetchFeed() async {
    final r = await _client
        .post(_rpc('community_feed'), headers: _headers, body: '{}')
        .timeout(_timeout);
    if (r.statusCode != 200) throw http.ClientException('HTTP ${r.statusCode}');
    return CommunityFeed.parse(jsonDecode(utf8.decode(r.bodyBytes)));
  }

  /// 2xx is sent; a 4xx other than 408/429 means the server rejected the
  /// values for good ([SubmitInvalid]); anything else is retried later.
  @override
  Future<void> submit(Submission s, String contributionId) async {
    final r = await _client
        .post(
          _rpc('submit_time'),
          headers: _headers,
          body: jsonEncode({'contribution_id': contributionId, ...s.toJson()}),
        )
        .timeout(_timeout);
    final c = r.statusCode;
    if (c >= 200 && c < 300) return;
    if (c >= 400 && c < 500 && c != 408 && c != 429) {
      throw const SubmitInvalid();
    }
    throw http.ClientException('HTTP $c');
  }
}
