import 'dart:convert';
import 'dart:io';

import 'package:drktimes/domain/exchange/codec.dart';
import 'package:drktimes/domain/exchange/document.dart';
import 'package:drktimes/domain/exchange/link.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'support.dart';

void main() {
  final schema = JsonSchema.create(
    jsonDecode(
      File('specs/001-film-develop-timer/contracts/exchange-format.schema.json')
          .readAsStringSync(),
    ) as Object,
  );

  test('a recipe document validates against the contract schema', () {
    final r = sampleRecipe();
    final doc = recipeDoc(r, [sampleNote(r.id)]);
    final json = ExchangeCodec.toJson(doc);
    final result = schema.validate(json);
    expect(result.isValid, isTrue, reason: '${result.errors}');
    expect(json['kind'], 'recipe');
    expect(json['format'], 'drktimes-exchange');
    expect(json['format_version'], '1.0');
    expect((json['recipes'] as List).single, isNot(contains('ownership')));
  });

  test('a recipe with its own process validates too', () {
    final r = sampleRecipe().copyWith(process: Process.defaults());
    final json = ExchangeCodec.toJson(recipeDoc(r));
    final result = schema.validate(json);
    expect(result.isValid, isTrue, reason: '${result.errors}');
  });

  test('a backup validates and carries ownership and hidden', () {
    final r = sampleRecipe(ownership: Ownership.received)
        .copyWith(hidden: true);
    final doc = ExchangeDocument(
      kind: ExchangeKind.backup,
      exportedAt: DateTime.utc(2026, 10, 21),
      recipes: [ExchangeRecipe(r, const [])],
      favourites: [sampleKey()],
      settings: const {'author_name': 'Me'},
    );
    final json = ExchangeCodec.toJson(doc);
    final result = schema.validate(json);
    expect(result.isValid, isTrue, reason: '${result.errors}');
    final back = ExchangeCodec.fromJson(json);
    expect(back.recipes.single.recipe.ownership, Ownership.received);
    expect(back.recipes.single.recipe.hidden, isTrue);
    expect(back.favourites.single, sampleKey());
    expect(back.settings, {'author_name': 'Me'});
  });

  test('round trip keeps the recipe, its notes and agitation', () {
    final r = sampleRecipe();
    final n = sampleNote(r.id);
    final back = ExchangeCodec.decodeString(
      ExchangeCodec.encodeString(recipeDoc(r, [n])),
    );
    final got = back.recipes.single;
    expect(got.recipe.id, r.id);
    expect(got.recipe.key, r.key);
    expect(got.recipe.devTimeS, 780);
    expect(got.recipe.devAgitation, r.devAgitation);
    expect(got.recipe.origin.toJson(), r.origin.toJson());
    expect(got.notes.single.text, n.text);
    expect(
      got.recipe.ownership,
      Ownership.received,
      reason: 'a shared recipe is always received on the other side',
    );
  });

  test('unknown fields are ignored', () {
    final json = ExchangeCodec.toJson(recipeDoc(sampleRecipe()));
    json['future_field'] = {'x': 1};
    (json['recipes'] as List).first['extra'] = true;
    expect(ExchangeCodec.fromJson(json).recipes, hasLength(1));
  });

  test('format_version 2.0 is rejected, 1.7 is accepted', () {
    final json = ExchangeCodec.toJson(recipeDoc(sampleRecipe()));
    json['format_version'] = '2.0';
    expect(
      () => ExchangeCodec.fromJson(json),
      throwsA(
        isA<ExchangeException>().having(
          (e) => e.error,
          'error',
          ExchangeError.unsupportedVersion,
        ),
      ),
    );
    json['format_version'] = '1.7';
    expect(ExchangeCodec.fromJson(json).recipes, hasLength(1));
  });

  test('wrong or missing format, and violations, are typed errors', () {
    expect(
      () => ExchangeCodec.decodeString('not json'),
      throwsA(
        isA<ExchangeException>().having(
          (e) => e.error,
          'e',
          ExchangeError.notJson,
        ),
      ),
    );
    expect(
      () => ExchangeCodec.decodeString('{"format":"other"}'),
      throwsA(
        isA<ExchangeException>().having(
          (e) => e.error,
          'e',
          ExchangeError.wrongFormat,
        ),
      ),
    );
    final json = ExchangeCodec.toJson(recipeDoc(sampleRecipe()));
    (json['recipes'] as List).first['dev_time_s'] = 5;
    expect(
      () => ExchangeCodec.fromJson(json),
      throwsA(
        isA<ExchangeException>().having(
          (e) => e.error,
          'e',
          ExchangeError.invalid,
        ),
      ),
    );
  });

  group('link', () {
    test('round trip is identical', () {
      final r = sampleRecipe();
      final doc = recipeDoc(r, [sampleNote(r.id)]);
      final link = LinkCodec.encode(doc, host: 'example.org');
      expect(link.url, startsWith('https://example.org/r#'));
      expect(link.url, isNot(contains('=')));
      expect(link.tooLongForLink, isFalse);
      final back = LinkCodec.decode(link.url);
      expect(ExchangeCodec.encodeString(back), ExchangeCodec.encodeString(doc));
    });

    test('payload alone also decodes', () {
      final doc = recipeDoc(sampleRecipe());
      final payload = LinkCodec.encodePayload(doc);
      expect(LinkCodec.decode(payload).recipes, hasLength(1));
    });

    test('a very long recipe reports tooLongForLink', () {
      final r = sampleRecipe();
      final notes = [
        for (var i = 0; i < 40; i++)
          sampleNote(
            r.id,
            text: List.generate(60, (j) => '${i * 997 + j * 31} ').join(),
          ),
      ];
      expect(LinkCodec.encode(recipeDoc(r, notes)).tooLongForLink, isTrue);
    });

    test('corrupt base64 or inflate input gives a typed error', () {
      for (final bad in [
        'https://x/r#@@@@',
        'https://x/r#AAAA',
        'https://x/r#',
      ]) {
        expect(
          () => LinkCodec.decode(bad),
          throwsA(isA<ExchangeException>()),
          reason: bad,
        );
      }
    });
  });
}
