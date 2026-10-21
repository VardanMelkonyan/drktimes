import '../combination_key.dart';
import '../process.dart';
import '../recipe.dart';
import '../user_entries.dart';

enum ExchangeKind { recipe, backup }

/// A recipe with the notes that travel with it.
class ExchangeRecipe {
  const ExchangeRecipe(this.recipe, this.notes);

  final Recipe recipe;
  final List<Note> notes;
}

/// A finished session as kept in a backup (schema "session").
class ExchangeSession {
  const ExchangeSession({
    required this.id,
    required this.tankLabel,
    required this.key,
    required this.timeSource,
    required this.devTimeS,
    required this.format,
    required this.status,
    required this.startedAt,
    this.abortedAtStep,
    this.finishedAt,
    this.stepDurationsS = const [],
  });

  final String id, tankLabel, format, status;
  final CombinationKey key;
  final Map<String, dynamic> timeSource;
  final int devTimeS;
  final DateTime startedAt;
  final int? abortedAtStep;
  final DateTime? finishedAt;
  final List<int> stepDurationsS;
}

class ExchangeDocument {
  const ExchangeDocument({
    required this.kind,
    required this.exportedAt,
    this.appVersion,
    this.userFilms = const [],
    this.userDevelopers = const [],
    this.recipes = const [],
    this.favourites = const [],
    this.sessions = const [],
    this.processes = const [],
    this.settings,
    this.formatVersion = currentFormatVersion,
  });

  static const format = 'drktimes-exchange';
  static const currentFormatVersion = '1.0';

  final ExchangeKind kind;
  final DateTime exportedAt;
  final String? appVersion;
  final String formatVersion;
  final List<UserFilm> userFilms;
  final List<UserDeveloper> userDevelopers;
  final List<ExchangeRecipe> recipes;
  final List<CombinationKey> favourites;
  final List<ExchangeSession> sessions;
  final List<Process> processes;
  final Map<String, dynamic>? settings;
}
