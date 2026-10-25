/// The project's community source (spec 002, T013). Supplied at build time:
/// `--dart-define=COMMUNITY_URL=...` and `--dart-define=COMMUNITY_KEY=...`
/// (the project URL and its anon key). Both are public by design. Until
/// they are set the default source is absent and the app is purely
/// standalone: no network request is ever made.
const kDefaultSourceId = 'drktimes-community';
const kDefaultSourceName = 'drktimes community';
const kDefaultSourceUrl = String.fromEnvironment('COMMUNITY_URL');
const kDefaultSourceKey = String.fromEnvironment('COMMUNITY_KEY');

bool get hasDefaultSource =>
    kDefaultSourceUrl.isNotEmpty && kDefaultSourceKey.isNotEmpty;
