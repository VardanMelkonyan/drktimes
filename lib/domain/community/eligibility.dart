import '../combination_key.dart';
import 'submission.dart';

/// What may be shared (FR-005, FR-006, FR-009): a completed session whose
/// time came from the user's own recipe, on a catalog film and developer,
/// with a plausible time. The time is the session's recorded `devTimeS`, not
/// the recipe's current one. [isOwnRecipe] answers for a recipe id.
Submission? eligibleSubmission({
  required String status,
  required Map<String, dynamic> timeSource,
  required int devTimeS,
  required CombinationKey? key,
  required bool Function(String recipeId) isOwnRecipe,
}) {
  if (status != 'completed' || key == null) return null;
  if (timeSource['kind'] != 'recipe') return null;
  final id = timeSource['recipe_id'];
  if (id is! String || !isOwnRecipe(id)) return null;
  return Submission.from(key, devTimeS);
}
