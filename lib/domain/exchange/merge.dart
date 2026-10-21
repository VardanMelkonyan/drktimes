import '../combination_key.dart';
import '../process.dart';
import '../recipe.dart';
import '../search.dart';
import '../user_entries.dart';
import 'document.dart';

/// A catalogue film or developer, reduced to what matching needs.
class CatalogEntry {
  const CatalogEntry(this.id, this.brand, this.name);

  final String id, brand, name;
}

/// What the device already has, as plain values.
class LocalSnapshot {
  const LocalSnapshot({
    this.recipes = const {},
    this.noteIds = const {},
    this.userFilms = const [],
    this.userDevelopers = const [],
    this.catalogFilms = const [],
    this.catalogDevelopers = const [],
    this.sessionIds = const {},
    this.processIds = const {},
    this.favouriteKeys = const {},
  });

  final Map<String, Recipe> recipes;

  /// Note ids already stored, by recipe id.
  final Map<String, Set<String>> noteIds;
  final List<UserFilm> userFilms;
  final List<UserDeveloper> userDevelopers;
  final List<CatalogEntry> catalogFilms, catalogDevelopers;
  final Set<String> sessionIds, processIds;

  /// Canonical keys of the starred combinations.
  final Set<String> favouriteKeys;
}

/// A user-added film or developer in the incoming document that looks like
/// one we already know (FR-058). The user decides.
class MatchOffer {
  const MatchOffer({
    required this.isFilm,
    required this.incomingId,
    required this.incomingLabel,
    required this.candidateRef,
    required this.candidateLabel,
    required this.candidateIsCatalog,
  });

  final bool isFilm;
  final String incomingId, incomingLabel, candidateLabel;

  /// The id of the catalogue entry or existing user entry.
  final String candidateRef;
  final bool candidateIsCatalog;
}

class RecipeUpdate {
  const RecipeUpdate(this.incoming, this.newNotes);

  /// The incoming recipe (keys already remapped); applied over the local one
  /// keeping its ownership and hidden flag.
  final Recipe incoming;
  final List<Note> newNotes;
}

class MergePlan {
  const MergePlan({
    this.inserts = const [],
    this.updates = const [],
    this.upToDate = const [],
    this.userFilms = const [],
    this.userDevelopers = const [],
    this.favourites = const [],
    this.sessions = const [],
    this.processes = const [],
    this.settings,
  });

  final List<ExchangeRecipe> inserts;
  final List<RecipeUpdate> updates;
  final List<String> upToDate;
  final List<UserFilm> userFilms;
  final List<UserDeveloper> userDevelopers;
  final List<CombinationKey> favourites;
  final List<ExchangeSession> sessions;
  final List<Process> processes;
  final Map<String, dynamic>? settings;

  bool get changesAnything =>
      inserts.isNotEmpty ||
      updates.isNotEmpty ||
      userFilms.isNotEmpty ||
      userDevelopers.isNotEmpty ||
      favourites.isNotEmpty ||
      sessions.isNotEmpty ||
      processes.isNotEmpty ||
      settings != null;
}

String unknownAuthor = 'unknown author';

String _norm(String brand, String name) => normaliseSearch('$brand $name');

/// Which incoming user films / developers match a known one (FR-058).
List<MatchOffer> findMatchOffers(ExchangeDocument doc, LocalSnapshot local) {
  final offers = <MatchOffer>[];
  final localFilmIds = {for (final f in local.userFilms) f.id};
  final localDevIds = {for (final d in local.userDevelopers) d.id};
  for (final f in doc.userFilms) {
    if (localFilmIds.contains(f.id)) continue;
    final n = _norm(f.brand, f.name);
    final cat = local.catalogFilms
        .where((c) => _norm(c.brand, c.name) == n)
        .firstOrNull;
    final user = local.userFilms
        .where((u) => _norm(u.brand, u.name) == n)
        .firstOrNull;
    if (cat != null) {
      offers.add(
        MatchOffer(
          isFilm: true,
          incomingId: f.id,
          incomingLabel: '${f.brand} ${f.name}',
          candidateRef: cat.id,
          candidateLabel: '${cat.brand} ${cat.name}',
          candidateIsCatalog: true,
        ),
      );
    } else if (user != null) {
      offers.add(
        MatchOffer(
          isFilm: true,
          incomingId: f.id,
          incomingLabel: '${f.brand} ${f.name}',
          candidateRef: user.id,
          candidateLabel: '${user.brand} ${user.name}',
          candidateIsCatalog: false,
        ),
      );
    }
  }
  for (final d in doc.userDevelopers) {
    if (localDevIds.contains(d.id)) continue;
    final n = _norm(d.brand, d.name);
    final cat = local.catalogDevelopers
        .where((c) => _norm(c.brand, c.name) == n)
        .firstOrNull;
    final user = local.userDevelopers
        .where((u) => _norm(u.brand, u.name) == n)
        .firstOrNull;
    if (cat != null) {
      offers.add(
        MatchOffer(
          isFilm: false,
          incomingId: d.id,
          incomingLabel: '${d.brand} ${d.name}',
          candidateRef: cat.id,
          candidateLabel: '${cat.brand} ${cat.name}',
          candidateIsCatalog: true,
        ),
      );
    } else if (user != null) {
      offers.add(
        MatchOffer(
          isFilm: false,
          incomingId: d.id,
          incomingLabel: '${d.brand} ${d.name}',
          candidateRef: user.id,
          candidateLabel: '${user.brand} ${user.name}',
          candidateIsCatalog: false,
        ),
      );
    }
  }
  return offers;
}

bool _newer(Recipe incoming, Recipe local) {
  if (incoming.version != local.version) {
    return incoming.version > local.version;
  }
  return incoming.updatedAt.isAfter(local.updatedAt);
}

/// Builds the plan for importing [doc] (data-model "Import merge").
///
/// [accepted] holds the ids of the [MatchOffer]s the user accepted. An
/// accepted match rewrites every reference to the incoming user entry so it
/// points at the matched one, and the entry itself is not added.
/// [restoreSettings] only matters for backups.
MergePlan planImport(
  ExchangeDocument doc,
  LocalSnapshot local, {
  Set<String> accepted = const {},
  bool restoreSettings = false,
}) {
  final offers = {for (final o in findMatchOffers(doc, local)) o.incomingId: o};

  // incoming user entry id -> the ref to use instead.
  final filmRemap = <String, FilmRef>{};
  final devRemap = <String, DeveloperRef>{};
  for (final id in accepted) {
    final o = offers[id];
    if (o == null) continue;
    if (o.isFilm) {
      filmRemap[id] = o.candidateIsCatalog
          ? FilmRef.catalog(o.candidateRef)
          : FilmRef.user(o.candidateRef);
    } else {
      devRemap[id] = o.candidateIsCatalog
          ? DeveloperRef.catalog(o.candidateRef)
          : DeveloperRef.user(o.candidateRef);
    }
  }

  CombinationKey remap(CombinationKey k) {
    final f = k.film.kind == RefKind.user ? filmRemap[k.film.id] : null;
    final d = k.developer.kind == RefKind.user
        ? devRemap[k.developer.id]
        : null;
    if (f == null && d == null) return k;
    return CombinationKey(
      film: f ?? k.film,
      developer: d ?? k.developer,
      dilution: k.dilution,
      ei: k.ei,
      tempC: k.tempC,
    );
  }

  final isBackup = doc.kind == ExchangeKind.backup;
  final inserts = <ExchangeRecipe>[];
  final updates = <RecipeUpdate>[];
  final upToDate = <String>[];
  final seen = <String>{};

  for (final er in doc.recipes) {
    final r = er.recipe;
    if (!seen.add(r.id)) continue;
    final incoming = r.copyWith(
      key: remap(r.key),
      authorName: r.authorName.isEmpty && !isBackup
          ? unknownAuthor
          : r.authorName,
    );
    final existing = local.recipes[r.id];
    if (existing == null) {
      final ownership = isBackup ? r.ownership : Ownership.received;
      inserts.add(
        ExchangeRecipe(incoming.copyWith(ownership: ownership), er.notes),
      );
    } else if (_newer(r, existing)) {
      final have = local.noteIds[r.id] ?? const <String>{};
      updates.add(
        RecipeUpdate(incoming, [
          for (final n in er.notes)
            if (!have.contains(n.id)) n,
        ]),
      );
    } else {
      upToDate.add(r.id);
    }
  }

  final localFilmIds = {for (final f in local.userFilms) f.id};
  final localDevIds = {for (final d in local.userDevelopers) d.id};

  return MergePlan(
    inserts: inserts,
    updates: updates,
    upToDate: upToDate,
    userFilms: [
      for (final f in doc.userFilms)
        if (!localFilmIds.contains(f.id) && !filmRemap.containsKey(f.id)) f,
    ],
    userDevelopers: [
      for (final d in doc.userDevelopers)
        if (!localDevIds.contains(d.id) && !devRemap.containsKey(d.id)) d,
    ],
    favourites: [
      for (final k in doc.favourites)
        if (!local.favouriteKeys.contains(remap(k).canonical)) remap(k),
    ],
    sessions: [
      for (final s in doc.sessions)
        if (!local.sessionIds.contains(s.id)) s,
    ],
    processes: [
      for (final p in doc.processes)
        if (!local.processIds.contains(p.id)) p,
    ],
    settings: isBackup && restoreSettings ? doc.settings : null,
  );
}
