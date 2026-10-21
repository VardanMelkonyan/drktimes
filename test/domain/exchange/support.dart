import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/exchange/document.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

CombinationKey sampleKey({int ei = 400, int t = 20}) => CombinationKey(
  film: const FilmRef.catalog('kodak-tri-x-400'),
  developer: const DeveloperRef.catalog('rodinal'),
  dilution: '1+50',
  ei: ei,
  tempC: t,
);

Recipe sampleRecipe({
  String? id,
  int version = 1,
  DateTime? updatedAt,
  String author = 'Ani M.',
  Ownership ownership = Ownership.own,
  CombinationKey? key,
  int devTimeS = 780,
}) => Recipe(
  id: id ?? uuid.v4(),
  version: version,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 1),
  authorName: author,
  ownership: ownership,
  origin: const DatasheetOrigin('kodak-f4017-2021-10', page: 3),
  key: key ?? sampleKey(),
  devTimeS: devTimeS,
  devAgitation: const Intermittent(initialS: 60, everyS: 60, burstS: 10),
);

Note sampleNote(
  String recipeId, {
  String? id,
  String text = 'Dense highlights.',
}) => Note(
  id: id ?? uuid.v4(),
  recipeId: recipeId,
  authorName: 'Ani M.',
  createdAt: DateTime.utc(2026, 9, 3, 10),
  text: text,
);

ExchangeDocument recipeDoc(Recipe r, [List<Note> notes = const []]) =>
    ExchangeDocument(
      kind: ExchangeKind.recipe,
      exportedAt: DateTime.utc(2026, 10, 21),
      appVersion: '0.1.0',
      recipes: [ExchangeRecipe(r, notes)],
    );
