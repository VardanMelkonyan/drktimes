import 'combination_key.dart';
import 'process.dart';

enum Ownership { own, received }

/// Where a recipe came from (data-model.md "Recipe").
sealed class RecipeOrigin {
  const RecipeOrigin();

  factory RecipeOrigin.fromJson(Map<String, dynamic> j) {
    switch (j['kind'] as String) {
      case 'datasheet':
        return DatasheetOrigin(
          j['source_id'] as String,
          page: j['page'] as int?,
        );
      case 'scratch':
        return const ScratchOrigin();
      case 'copy_of':
        return CopyOfOrigin(
          j['recipe_id'] as String,
          j['author_name'] as String? ?? '',
        );
      case 'temperature_estimate':
        return EstimateOrigin(
          RecipeOrigin.fromJson(j['base'] as Map<String, dynamic>),
        );
    }
    throw FormatException('unknown origin ${j['kind']}');
  }

  Map<String, dynamic> toJson();
}

class DatasheetOrigin extends RecipeOrigin {
  const DatasheetOrigin(this.sourceId, {this.page});

  final String sourceId;
  final int? page;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'datasheet',
    'source_id': sourceId,
    if (page != null) 'page': page,
  };
}

class ScratchOrigin extends RecipeOrigin {
  const ScratchOrigin();

  @override
  Map<String, dynamic> toJson() => {'kind': 'scratch'};
}

class CopyOfOrigin extends RecipeOrigin {
  const CopyOfOrigin(this.recipeId, this.authorName);

  final String recipeId, authorName;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'copy_of',
    'recipe_id': recipeId,
    'author_name': authorName,
  };
}

class EstimateOrigin extends RecipeOrigin {
  const EstimateOrigin(this.base);

  final RecipeOrigin base;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'temperature_estimate',
    'base': base.toJson(),
  };
}

class Recipe {
  const Recipe({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.ownership,
    required this.origin,
    required this.key,
    required this.devTimeS,
    required this.devAgitation,
    this.process,
    this.hidden = false,
    this.importedAt,
  });

  final String id;
  final int version;
  final DateTime createdAt, updatedAt;
  final String authorName;
  final Ownership ownership;
  final RecipeOrigin origin;
  final CombinationKey key;
  final int devTimeS;
  final AgitationPattern devAgitation;

  /// Overrides the default process when set.
  final Process? process;

  /// Received recipes only (FR-059).
  final bool hidden;

  /// When a received recipe was imported.
  final DateTime? importedAt;

  bool get isOwn => ownership == Ownership.own;

  Recipe copyWith({
    String? id,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    Ownership? ownership,
    RecipeOrigin? origin,
    CombinationKey? key,
    int? devTimeS,
    AgitationPattern? devAgitation,
    Process? process,
    bool clearProcess = false,
    bool? hidden,
    DateTime? importedAt,
  }) => Recipe(
    id: id ?? this.id,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    authorName: authorName ?? this.authorName,
    ownership: ownership ?? this.ownership,
    origin: origin ?? this.origin,
    key: key ?? this.key,
    devTimeS: devTimeS ?? this.devTimeS,
    devAgitation: devAgitation ?? this.devAgitation,
    process: clearProcess ? null : (process ?? this.process),
    hidden: hidden ?? this.hidden,
    importedAt: importedAt ?? this.importedAt,
  );
}

class Note {
  const Note({
    required this.id,
    required this.recipeId,
    required this.authorName,
    required this.createdAt,
    required this.text,
  });

  final String id, recipeId, authorName, text;
  final DateTime createdAt;
}

const minDevTimeS = 30;
const maxDevTimeS = 7200;
const maxNoteLength = 4000;
