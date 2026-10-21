import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/format.dart';
import '../../domain/recipe.dart';
import '../../domain/timeline/session_run.dart';
import '../common/widgets.dart';

/// SessionDone.dc.html (FR-049): a summary, then an optional note. The note
/// goes on the recipe the run used, or on a new own recipe made from its time.
class DoneScreen extends ConsumerStatefulWidget {
  const DoneScreen({super.key, required this.session});

  final SessionRun session;

  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen> {
  final _note = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _note.text.trim();
    final s = widget.session;
    final key = s.meta.key;
    if (text.isEmpty || key == null) return;
    final recipes = ref.read(recipeRepositoryProvider);
    final author =
        (await ref.read(settingsRepositoryProvider).get()).authorName;
    final src = s.meta.timeSource;
    Recipe? own;
    if (src['kind'] == 'recipe') {
      final r = await recipes.byId(src['recipe_id'] as String);
      if (r != null && r.isOwn) own = r;
    }
    own ??= await recipes.create(
      key: key,
      devTimeS: s.devTimeS,
      devAgitation: s.steps
          .firstWhere((x) => x.kind.json == 'developer')
          .agitation,
      origin: src['kind'] == 'datasheet'
          ? DatasheetOrigin(
              src['source_id'] as String,
              page: src['page'] as int?,
            )
          : const ScratchOrigin(),
      authorName: author,
    );
    await ref
        .read(noteRepositoryProvider)
        .add(recipeId: own.id, authorName: author, text: text);
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = widget.session;
    final aborted = s.status == SessionStatus.aborted;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DrkSpace.s20),
          children: [
            Row(
              children: [
                const DrkChip('Done'),
                const SizedBox(width: 10),
                TankTag(slot: s.tankSlot, label: s.tankLabel),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              aborted ? 'Run aborted.' : 'Done.',
              key: const Key('done-title'),
              style: DrkType.dp.copyWith(color: p.fg),
            ),
            const SizedBox(height: 12),
            Text(
              'Developer ${formatTime(s.devTimeS)}',
              style: DrkType.bd.copyWith(color: p.mut),
            ),
            for (final r in s.runs)
              Text(
                '${s.steps[r.stepIndex].name} · ${r.startedAt?.toLocal().toString().substring(11, 16) ?? ''}',
                style: DrkType.sm.copyWith(color: p.mut),
              ),
            const SizedBox(height: 20),
            if (s.meta.key != null && !_saved) ...[
              DrkField(
                key: const Key('done-note'),
                controller: _note,
                hint: 'Add a note',
              ),
              const SizedBox(height: 10),
              DrkButton(
                key: const Key('done-save-note'),
                label: 'Save note',
                kind: DrkButtonKind.outline,
                onPressed: _save,
              ),
            ],
            if (_saved)
              Text(
                'Note saved.',
                key: const Key('note-saved'),
                style: DrkType.bd.copyWith(color: p.fg),
              ),
            const SizedBox(height: 20),
            DrkButton(
              key: const Key('done-home'),
              label: 'Back to home',
              kind: DrkButtonKind.primary,
              size: DrkButtonSize.large,
              onPressed: () {
                ref.read(sessionControllerProvider).finished.remove(s);
                context.go('/develop');
              },
            ),
          ],
        ),
      ),
    );
  }
}
