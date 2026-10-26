import 'package:drktimes/data/community/community_source.dart';
import 'package:drktimes/domain/community/community_feed.dart';
import 'package:drktimes/domain/community/submission.dart';

class FakeCommunitySource implements CommunitySource {
  FakeCommunitySource({
    this.id = 'src',
    this.name = 'Fake',
    this.canSubmit = true,
    this.feed = const CommunityFeed(entries: []),
  });

  @override
  final String id, name;
  @override
  final bool canSubmit;
  CommunityFeed feed;

  final submitted = <(Submission, String)>[];
  int fetches = 0;
  bool offline = false;
  bool rejects = false;
  bool malformed = false;

  @override
  Future<CommunityFeed> fetchFeed() async {
    fetches++;
    if (offline) throw Exception('offline');
    if (malformed) throw const FormatException('not a feed');
    return feed;
  }

  @override
  Future<void> submit(Submission s, String contributionId) async {
    if (offline) throw Exception('offline');
    if (rejects) throw const SubmitInvalid();
    submitted.add((s, contributionId));
  }
}
