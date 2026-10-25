import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/community/community_feed.dart';
import '../../domain/community/submission.dart';
import 'community_source.dart';

const _timeout = Duration(seconds: 15);

/// A read-only feed served as a JSON file (spec 002, US4).
class StaticFeedSource implements CommunitySource {
  StaticFeedSource({
    required this.id,
    required this.name,
    required this.url,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  final String id, name;
  final String url;
  final http.Client _client;

  @override
  bool get canSubmit => false;

  @override
  Future<CommunityFeed> fetchFeed() async {
    final r = await _client.get(Uri.parse(url)).timeout(_timeout);
    if (r.statusCode != 200) throw http.ClientException('HTTP ${r.statusCode}');
    return CommunityFeed.parse(jsonDecode(utf8.decode(r.bodyBytes)));
  }

  @override
  Future<void> submit(Submission s, String contributionId) =>
      throw UnsupportedError('read-only source');
}
