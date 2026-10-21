import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/clock.dart';
import '../../domain/recipe.dart';
import '../db/database.dart';

class NoteRepository {
  NoteRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? (() => const Uuid().v4());

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  Future<Note> add({
    required String recipeId,
    required String authorName,
    required String text,
  }) async {
    if (text.isEmpty || text.length > maxNoteLength) {
      throw ArgumentError.value(
        text.length,
        'text',
        'a note is 1–$maxNoteLength characters',
      );
    }
    final n = Note(
      id: _newId(),
      recipeId: recipeId,
      authorName: authorName,
      createdAt: _clock.now(),
      text: text,
    );
    await _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            id: n.id,
            recipeId: n.recipeId,
            authorName: n.authorName,
            createdAt: n.createdAt,
            text_: n.text,
          ),
        );
    return n;
  }

  Future<List<Note>> forRecipe(String recipeId) async {
    final rows =
        await (_db.select(_db.notes)
              ..where((t) => t.recipeId.equals(recipeId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return [for (final r in rows) _map(r)];
  }

  /// The union of notes on several recipes, oldest first (FR-017).
  Future<List<Note>> forRecipes(Iterable<String> recipeIds) async {
    final rows =
        await (_db.select(_db.notes)
              ..where((t) => t.recipeId.isIn(recipeIds))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return [for (final r in rows) _map(r)];
  }

  Note _map(NoteRow r) => Note(
    id: r.id,
    recipeId: r.recipeId,
    authorName: r.authorName,
    createdAt: r.createdAt,
    text: r.text_,
  );
}
