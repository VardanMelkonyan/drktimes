import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/exchange/document.dart';
import 'package:drktimes/domain/exchange/merge.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:drktimes/domain/user_entries.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('an unknown id is inserted as received', () {
    final r = sampleRecipe();
    final plan = planImport(recipeDoc(r), const LocalSnapshot());
    expect(plan.inserts.single.recipe.id, r.id);
    expect(plan.inserts.single.recipe.ownership, Ownership.received);
    expect(plan.updates, isEmpty);
    expect(plan.changesAnything, isTrue);
  });

  test('an id matching an own recipe stays own and is not re-inserted', () {
    final mine = sampleRecipe(ownership: Ownership.own, version: 2);
    final plan = planImport(
      recipeDoc(mine.copyWith(version: 2)),
      LocalSnapshot(recipes: {mine.id: mine}),
    );
    expect(plan.inserts, isEmpty);
    expect(plan.upToDate, [mine.id]);
  });

  test('a higher version replaces the fields and unions notes by id', () {
    final local = sampleRecipe(version: 1, ownership: Ownership.received);
    final incoming = local.copyWith(
      version: 2,
      updatedAt: DateTime.utc(2026, 10, 1),
      devTimeS: 810,
    );
    final known = sampleNote(local.id, id: 'n1');
    final fresh = sampleNote(local.id, id: 'n2', text: 'new');
    final plan = planImport(
      recipeDoc(incoming, [known, fresh]),
      LocalSnapshot(
        recipes: {local.id: local},
        noteIds: {
          local.id: {'n1'},
        },
      ),
    );
    expect(plan.updates.single.incoming.devTimeS, 810);
    expect(plan.updates.single.newNotes.map((n) => n.id), ['n2']);
    expect(plan.upToDate, isEmpty);
  });

  test('same version but newer updated_at also wins', () {
    final local = sampleRecipe(ownership: Ownership.received);
    final incoming = local.copyWith(updatedAt: DateTime.utc(2026, 9, 2));
    final plan = planImport(
      recipeDoc(incoming),
      LocalSnapshot(recipes: {local.id: local}),
    );
    expect(plan.updates, hasLength(1));
  });

  test('equal or older says already up to date and changes nothing', () {
    final local = sampleRecipe(version: 3, ownership: Ownership.received);
    for (final incoming in [local, local.copyWith(version: 2)]) {
      final plan = planImport(
        recipeDoc(incoming),
        LocalSnapshot(recipes: {local.id: local}),
      );
      expect(plan.upToDate, [local.id]);
      expect(plan.changesAnything, isFalse);
    }
  });

  test('an empty author name becomes "unknown author"', () {
    final plan = planImport(
      recipeDoc(sampleRecipe(author: '')),
      const LocalSnapshot(),
    );
    expect(plan.inserts.single.recipe.authorName, 'unknown author');
  });

  group('matching user-added entries', () {
    UserFilm film(String id, String brand, String name) => UserFilm(
      id: id,
      brand: brand,
      name: name,
      boxIso: 100,
      createdAt: DateTime.utc(2026),
    );

    ExchangeDocument docWithUserFilm(String filmId, String brand, String name) {
      final key = CombinationKey(
        film: FilmRef.user(filmId),
        developer: const DeveloperRef.catalog('rodinal'),
        dilution: '1+50',
        ei: 100,
        tempC: 20,
      );
      return ExchangeDocument(
        kind: ExchangeKind.recipe,
        exportedAt: DateTime.utc(2026, 10, 21),
        userFilms: [film(filmId, brand, name)],
        recipes: [ExchangeRecipe(sampleRecipe(key: key), const [])],
      );
    }

    test('a catalogue match is offered on normalised brand+name', () {
      final doc = docWithUserFilm('u-1', 'KODAK', 'tri-x 400');
      final local = const LocalSnapshot(
        catalogFilms: [CatalogEntry('kodak-tri-x-400', 'Kodak', 'Tri-X 400')],
      );
      final offers = findMatchOffers(doc, local);
      expect(offers.single.candidateRef, 'kodak-tri-x-400');
      expect(offers.single.candidateIsCatalog, isTrue);
    });

    test('accepting rewrites the recipe key and skips the user entry', () {
      final doc = docWithUserFilm('u-1', 'Kodak', 'Tri-X 400');
      final local = const LocalSnapshot(
        catalogFilms: [CatalogEntry('kodak-tri-x-400', 'Kodak', 'Tri-X 400')],
      );
      final plan = planImport(doc, local, accepted: {'u-1'});
      expect(
        plan.inserts.single.recipe.key.film,
        const FilmRef.catalog('kodak-tri-x-400'),
      );
      expect(plan.userFilms, isEmpty);
    });

    test('declining keeps the user entry and the key', () {
      final doc = docWithUserFilm('u-1', 'Kodak', 'Tri-X 400');
      final local = const LocalSnapshot(
        catalogFilms: [CatalogEntry('kodak-tri-x-400', 'Kodak', 'Tri-X 400')],
      );
      final plan = planImport(doc, local);
      expect(plan.inserts.single.recipe.key.film, const FilmRef.user('u-1'));
      expect(plan.userFilms.single.id, 'u-1');
    });

    test('an existing user entry can be the match', () {
      final doc = docWithUserFilm('u-9', 'Shanghai', 'GP3');
      final local = LocalSnapshot(userFilms: [film('u-1', 'shanghai', 'gp 3')]);
      final offers = findMatchOffers(doc, local);
      expect(offers.single.candidateRef, 'u-1');
      expect(offers.single.candidateIsCatalog, isFalse);
      final plan = planImport(doc, local, accepted: {'u-9'});
      expect(plan.inserts.single.recipe.key.film, const FilmRef.user('u-1'));
    });

    test('no offer when the entry already exists locally by id', () {
      final doc = docWithUserFilm('u-1', 'Kodak', 'Tri-X 400');
      final local = LocalSnapshot(
        userFilms: [film('u-1', 'Kodak', 'Tri-X 400')],
        catalogFilms: const [
          CatalogEntry('kodak-tri-x-400', 'Kodak', 'Tri-X 400'),
        ],
      );
      expect(findMatchOffers(doc, local), isEmpty);
    });
  });

  group('backup', () {
    test('own recipes are restored as own, settings only when asked', () {
      final r = sampleRecipe(ownership: Ownership.own);
      final doc = ExchangeDocument(
        kind: ExchangeKind.backup,
        exportedAt: DateTime.utc(2026, 10, 21),
        recipes: [ExchangeRecipe(r, const [])],
        settings: const {'author_name': 'Me'},
      );
      var plan = planImport(doc, const LocalSnapshot());
      expect(plan.inserts.single.recipe.ownership, Ownership.own);
      expect(plan.settings, isNull);
      plan = planImport(doc, const LocalSnapshot(), restoreSettings: true);
      expect(plan.settings, {'author_name': 'Me'});
    });

    test('an older backup never overwrites newer local data', () {
      final local = sampleRecipe(version: 5, ownership: Ownership.own);
      final old = local.copyWith(version: 2, devTimeS: 1);
      final doc = ExchangeDocument(
        kind: ExchangeKind.backup,
        exportedAt: DateTime.utc(2026, 10, 21),
        recipes: [ExchangeRecipe(old, const [])],
      );
      final plan = planImport(doc, LocalSnapshot(recipes: {local.id: local}));
      expect(plan.updates, isEmpty);
      expect(plan.upToDate, [local.id]);
    });
  });
}
