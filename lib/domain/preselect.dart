import '../data/dataset/datasheet_time.dart';

enum PreselectBranch {
  lastUsed,
  datasheet,
  ownRecipe,
  receivedRecipe,
  community,
}

/// The slice of a recipe that preselection looks at.
class RecipeCandidate {
  const RecipeCandidate({
    required this.id,
    required this.own,
    required this.timeS,
    required this.version,
    required this.updatedAt,
    this.importedAt,
    this.hidden = false,
  });

  final String id;
  final bool own;
  final int timeS, version;
  final DateTime updatedAt;
  final DateTime? importedAt;
  final bool hidden;
}

/// A confirmed community time; only a last-resort preselection (FR-019b).
class CommunityCandidate {
  const CommunityCandidate({
    required this.sourceId,
    required this.timeS,
    required this.installs,
    required this.lastConfirmed,
  });

  final String sourceId;
  final int timeS, installs;
  final DateTime lastConfirmed;
}

Map<String, dynamic> communitySource(String sourceId) => {
  'kind': 'community',
  'source_id': sourceId,
};

class Preselection {
  const Preselection(this.branch, this.timeS, this.timeSource);

  final PreselectBranch branch;
  final int timeS;

  /// Ready to store as a session's `time_source`.
  final Map<String, dynamic> timeSource;
}

Map<String, dynamic> datasheetSource(DatasheetTime t) => {
  'kind': 'datasheet',
  'source_id': t.source.id,
  if (t.page != null) 'page': t.page,
};

Map<String, dynamic> recipeSource(RecipeCandidate r) => {
  'kind': 'recipe',
  'recipe_id': r.id,
  'recipe_version': r.version,
};

const _months = {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};

/// "October 2021" / "2021-10" / "2021" → a comparable date; null if unknown.
DateTime? parseEdition(String? s) {
  if (s == null) return null;
  final named = RegExp(r'^\s*([A-Za-z]+)\s+(\d{4})\s*$').firstMatch(s);
  if (named != null) {
    final m = _months[named.group(1)!.toLowerCase()];
    if (m != null) return DateTime.utc(int.parse(named.group(2)!), m);
  }
  final iso = RegExp(r'^\s*(\d{4})(?:-(\d{1,2}))?').firstMatch(s);
  if (iso != null) {
    return DateTime.utc(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2) ?? '1'),
    );
  }
  return null;
}

int _newer(DatasheetTime a, DatasheetTime b) {
  final ea = parseEdition(a.source.edition),
      eb = parseEdition(b.source.edition);
  if (ea != null || eb != null) {
    if (ea == null) return 1;
    if (eb == null) return -1;
    final c = eb.compareTo(ea);
    if (c != 0) return c;
  }
  final ra = DateTime.tryParse(a.source.retrieved ?? '');
  final rb = DateTime.tryParse(b.source.retrieved ?? '');
  if (ra == null && rb == null) return 0;
  if (ra == null) return 1;
  if (rb == null) return -1;
  return rb.compareTo(ra);
}

/// Which time a combination page starts on (FR-071). Returns null when there
/// is nothing to show.
///
/// [latestSessionSource] is the `time_source` of the most recent session for
/// this combination, if any.
Preselection? preselect({
  required Map<String, dynamic>? latestSessionSource,
  required List<DatasheetTime> datasheet,
  required List<RecipeCandidate> recipes,
  List<CommunityCandidate> community = const [],
}) {
  final visible = [
    for (final r in recipes)
      if (!r.hidden) r,
  ];

  // 1. what the last session used, if it is still there.
  if (latestSessionSource != null) {
    if (latestSessionSource['kind'] == 'datasheet') {
      for (final t in datasheet) {
        if (t.source.id == latestSessionSource['source_id'] &&
            (latestSessionSource['page'] == null ||
                t.page == latestSessionSource['page'])) {
          return Preselection(
            PreselectBranch.lastUsed,
            t.defaultRunTimeS,
            datasheetSource(t),
          );
        }
      }
    } else if (latestSessionSource['kind'] == 'recipe') {
      for (final r in visible) {
        if (r.id == latestSessionSource['recipe_id']) {
          return Preselection(
            PreselectBranch.lastUsed,
            r.timeS,
            recipeSource(r),
          );
        }
      }
    }
  }

  // 2. the primary datasheet time from the newest source.
  final primary = [
    for (final t in datasheet)
      if (t.isPrimary) t,
  ]..sort(_newer);
  if (primary.isNotEmpty) {
    final t = primary.first;
    return Preselection(
      PreselectBranch.datasheet,
      t.defaultRunTimeS,
      datasheetSource(t),
    );
  }

  // 3. my own most recently updated recipe.
  final own = [
    for (final r in visible)
      if (r.own) r,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  if (own.isNotEmpty) {
    return Preselection(
      PreselectBranch.ownRecipe,
      own.first.timeS,
      recipeSource(own.first),
    );
  }

  // 4. the received recipe imported most recently.
  final received =
      [
        for (final r in visible)
          if (!r.own) r,
      ]..sort(
        (a, b) => (b.importedAt ?? b.updatedAt).compareTo(
          a.importedAt ?? a.updatedAt,
        ),
      );
  if (received.isNotEmpty) {
    return Preselection(
      PreselectBranch.receivedRecipe,
      received.first.timeS,
      recipeSource(received.first),
    );
  }

  // 5. the community time with the most installs, newest on a tie.
  final backed =
      [
        for (final c in community)
          if (c.installs >= 2) c,
      ]..sort((a, b) {
        final c = b.installs.compareTo(a.installs);
        return c != 0 ? c : b.lastConfirmed.compareTo(a.lastConfirmed);
      });
  if (backed.isNotEmpty) {
    return Preselection(
      PreselectBranch.community,
      backed.first.timeS,
      communitySource(backed.first.sourceId),
    );
  }
  return null;
}
