import '../../domain/combination_key.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';

/// What the recipe editor starts from.
class RecipeEditorArgs {
  const RecipeEditorArgs({
    required this.key,
    required this.devTimeS,
    required this.agitation,
    required this.origin,
    this.baseLabel,
    this.existing,
    this.process,
  });

  final CombinationKey key;
  final int devTimeS;
  final AgitationPattern agitation;
  final RecipeOrigin origin;

  /// "Rodinal (Adox) datasheet · 13:00"; shown as "Based on …".
  final String? baseLabel;

  /// Set when editing a recipe that already exists.
  final Recipe? existing;
  final Process? process;
}
