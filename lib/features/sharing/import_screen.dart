import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/import_service.dart';
import '../../domain/exchange/document.dart';
import '../../domain/exchange/merge.dart';
import '../../domain/format.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';

/// Preview and apply an imported recipe or backup (FR-056–FR-058, FR-061).
/// [doc] null means the input was not a valid drktimes document.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.doc});

  final ExchangeDocument? doc;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _restoreSettings = false;
  ImportResult? _result;
  MergePlan? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = widget.doc;
    if (doc == null) return;
    final svc = await ref.read(importServiceProvider.future);
    final plan = planImport(doc, await svc.snapshot());
    if (mounted) setState(() => _preview = plan);
  }

  Future<void> _import() async {
    final doc = widget.doc!;
    final svc = await ref.read(importServiceProvider.future);
    final accepted = <String>{};
    for (final o in await svc.offersFor(doc)) {
      if (!mounted) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Same ${o.isFilm ? 'film' : 'developer'}?'),
          content: Text(
            '"${o.incomingLabel}" looks like "${o.candidateLabel}". Use the one you have?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('KEEP SEPARATE'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('USE MINE'),
            ),
          ],
        ),
      );
      if (yes == true) accepted.add(o.incomingId);
    }
    final result = await svc.import(
      doc,
      accepted: accepted,
      restoreSettings: _restoreSettings,
    );
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final doc = widget.doc;
    final plan = _preview;
    final isBackup = doc?.kind == ExchangeKind.backup;
    final r = doc?.recipes.firstOrNull;

    Widget body;
    if (doc == null) {
      body = Text(
        "This link isn't a valid drktimes recipe.",
        key: const Key('import-invalid'),
        style: DrkType.dp.copyWith(color: p.fg),
      );
    } else if (_result != null) {
      final x = _result!;
      body = Text(
        x.nothingChanged
            ? 'Already up to date.'
            : x.updated > 0 && x.added == 0
            ? 'Updated.'
            : 'Imported.',
        key: const Key('import-done'),
        style: DrkType.dp.copyWith(color: p.fg),
      );
    } else if (isBackup) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import backup', style: DrkType.dp.copyWith(color: p.fg)),
          const SizedBox(height: 12),
          Text(
            '${doc.recipes.length} recipes · ${doc.favourites.length} favourites · ${doc.sessions.length} runs',
            style: DrkType.bd.copyWith(color: p.mut),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Restore settings too',
                  style: DrkType.bd.copyWith(color: p.fg),
                ),
              ),
              DrkSwitch(
                key: const Key('restore-settings'),
                value: _restoreSettings,
                onChanged: (v) => setState(() => _restoreSettings = v),
              ),
            ],
          ),
        ],
      );
    } else {
      final status = plan == null
          ? ''
          : plan.inserts.isNotEmpty
          ? 'New to you'
          : plan.updates.isNotEmpty
          ? 'Updated version'
          : 'Already up to date';
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrkChip(status),
          const SizedBox(height: 12),
          Text(
            "${r!.recipe.authorName.isEmpty ? 'unknown author' : r.recipe.authorName}'s recipe",
            style: DrkType.dp.copyWith(color: p.fg),
          ),
          const SizedBox(height: 16),
          Text(
            '${r.recipe.key.dilution} · ISO ${r.recipe.key.ei} · ${r.recipe.key.tempC} °C',
            style: DrkType.bd.copyWith(color: p.mut),
          ),
          const SizedBox(height: 8),
          Text(
            formatTime(r.recipe.devTimeS),
            style: DrkType.tl.copyWith(color: p.fg),
          ),
          const SizedBox(height: 8),
          Text(
            '${r.notes.length} ${r.notes.length == 1 ? 'note' : 'notes'}',
            style: DrkType.sm.copyWith(color: p.mut),
          ),
          for (final n in r.notes)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${n.authorName.isEmpty ? 'unknown author' : n.authorName}: ${n.text}',
                style: DrkType.sm.copyWith(color: p.fg),
              ),
            ),
        ],
      );
    }

    final upToDate = plan != null && !plan.changesAnything && !isBackup;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DrkSpace.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SingleChildScrollView(child: body)),
              if (doc != null && _result == null)
                DrkButton(
                  key: const Key('import-go'),
                  label: upToDate
                      ? 'Close'
                      : (plan?.updates.isNotEmpty ?? false)
                      ? 'Update'
                      : 'Import',
                  kind: DrkButtonKind.primary,
                  size: DrkButtonSize.large,
                  onPressed: upToDate ? () => context.go('/develop') : _import,
                ),
              const SizedBox(height: 8),
              DrkButton(
                key: const Key('import-close'),
                label: _result != null && r != null && !isBackup
                    ? 'Open combination'
                    : 'Not now',
                kind: DrkButtonKind.quiet,
                onPressed: () => _result != null && r != null && !isBackup
                    ? context.go(comboPath(r.recipe.key))
                    : context.go('/develop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
