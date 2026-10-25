import '../../domain/community/community_feed.dart';
import '../../domain/community/submission.dart';

/// A place community times are read from and, maybe, sent to (spec 002).
abstract class CommunitySource {
  String get id;
  String get name;

  /// Never throws for an unreachable or malformed source; callers keep the
  /// previous cache on [Exception].
  Future<CommunityFeed> fetchFeed();

  bool get canSubmit;

  /// Throws [SubmitInvalid] when the source rejects the values for good
  /// (drop the item); any other exception means retry later.
  Future<void> submit(Submission s, String contributionId);
}

class SubmitInvalid implements Exception {
  const SubmitInvalid();
}
