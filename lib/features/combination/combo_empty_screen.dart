import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/combination_repository.dart';
import '../../domain/format.dart';
import '../../domain/recipe.dart';
import '../common/widgets.dart';
import '../recipe_editor/recipe_editor_args.dart';
import 'combination_screen.dart';

/// ComboEmpty.dc.html: no published time and no recipes for this combination.
class ComboEmptyScreen extends ConsumerWidget {
  const ComboEmptyScreen({super.key, required this.view});

  final CombinationView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final key = view.key;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/develop'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text('COMBINATION', style: labelStyle(context)),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.fg, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${view.filmLabel} · ${view.developerLabel}',
                      style: DrkType.ti.copyWith(color: p.fg),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${key.dilution} · ISO ${key.ei} · ${formatTemp(key.tempC)}',
                      style: DrkType.sm.copyWith(color: p.mut),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '--:--',
                      style: DrkType.tx.copyWith(
                        color: p.dim,
                        fontWeight: FontWeight.w300,
                      ),
                      semanticsLabel: 'No time',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No published time for this combination.',
                      key: const Key('no-published-time'),
                      style: DrkType.dp.copyWith(color: p.fg),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add the time you use and it becomes the time to use here. You can share it with others later.',
                      style: DrkType.bd.copyWith(color: p.mut),
                    ),
                  ],
                ),
              ),
              DrkButton(
                key: const Key('add-yours'),
                label: 'Add yours',
                kind: DrkButtonKind.primary,
                size: DrkButtonSize.large,
                icon: Icons.add,
                onPressed: () => openRecipeEditor(
                  context,
                  ref,
                  key,
                  RecipeEditorArgs(
                    key: key,
                    devTimeS: 600,
                    agitation: defaultDeveloperAgitation(ref),
                    origin: const ScratchOrigin(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DrkButton(
                key: const Key('pick-another'),
                label: 'Pick another developer',
                kind: DrkButtonKind.quiet,
                onPressed: () => context.go('/pick/developer'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
