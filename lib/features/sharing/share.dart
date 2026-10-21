import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/exchange/codec.dart';
import '../../domain/exchange/link.dart';
import '../common/widgets.dart';

/// File name for a shared recipe (contracts §2).
String recipeFileName(
  String film,
  String dev,
  String dilution,
  int ei,
  int tempC,
) =>
    '${'$film-$dev-$dilution-ISO$ei-${tempC}C'.replaceAll(RegExp(r'[^A-Za-z0-9+._-]+'), '-')}.drktimes';

/// Share one of the user's own recipes as a link or a file (FR-053–FR-055).
Future<void> shareRecipe(
  BuildContext context,
  WidgetRef ref,
  String recipeId,
) async {
  final settings = ref.read(settingsRepositoryProvider);
  if ((await settings.get()).authorName.isEmpty) {
    if (!context.mounted) return;
    final name = await _askAuthor(context);
    if (name == null || name.isEmpty) return;
    await settings.update(authorName: name);
  }
  final doc = await ref.read(backupServiceProvider).recipeDocument(recipeId);
  final link = LinkCodec.encode(doc);
  final r = doc.recipes.single.recipe;
  final name = recipeFileName(
    r.key.film.id,
    r.key.developer.id,
    r.key.dilution,
    r.key.ei,
    r.key.tempC,
  );
  final sharer = ref.read(sharerProvider);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.pal.s1,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share recipe', style: DrkType.dp.copyWith(color: ctx.pal.fg)),
          const SizedBox(height: 16),
          DrkButton(
            key: const Key('share-link'),
            label: 'Share link',
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.large,
            onPressed: link.tooLongForLink
                ? null
                : () {
                    sharer.shareText(link.url);
                    Navigator.pop(ctx);
                  },
          ),
          if (link.tooLongForLink)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Too long for a link. Share the file instead.',
                style: DrkType.sm.copyWith(color: ctx.pal.mut),
              ),
            ),
          const SizedBox(height: 10),
          DrkButton(
            key: const Key('share-file'),
            label: 'Share file',
            size: DrkButtonSize.large,
            onPressed: () {
              sharer.shareFile(
                name,
                utf8.encode(ExchangeCodec.encodeString(doc)),
              );
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

Future<String?> _askAuthor(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Your name'),
      content: DrkField(
        controller: c,
        hint: 'Shown on recipes you share',
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
