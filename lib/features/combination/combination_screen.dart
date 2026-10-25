import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/combination_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/amounts.dart';
import '../../domain/combination_key.dart';
import '../../domain/format.dart';
import '../../domain/preselect.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';
import '../../domain/session_meta.dart';
import '../../domain/temperature.dart';
import '../common/widgets.dart';
import '../sharing/share.dart';
import '../session/start_session.dart';
import '../recipe_editor/recipe_editor_args.dart';
import '../picker/picker_state.dart';
import 'combo_empty_screen.dart';

/// Combination.dc.html: the time to use, Start, the list of times, chemistry,
/// a temperature estimate and notes.
class CombinationScreen extends ConsumerStatefulWidget {
  const CombinationScreen({super.key, required this.comboKey});

  final CombinationKey comboKey;

  @override
  ConsumerState<CombinationScreen> createState() => _CombinationScreenState();
}

class _CombinationScreenState extends ConsumerState<CombinationScreen> {
  int? _selected;
  late int _waterC = widget.comboKey.tempC;
  String? _tankLabel;

  @override
  void initState() {
    super.initState();
    // Silent: a stale community cache is refreshed in the background (FR-018).
    ref
        .read(communitySyncProvider)
        .refreshStale()
        .then((changed) {
          if (changed && mounted) {
            ref.read(dataVersionProvider.notifier).state++;
          }
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(combinationViewProvider(widget.comboKey));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (view) => view.isEmpty
          ? ComboEmptyScreen(view: view)
          : _Body(
              view: view,
              selected: _selected,
              waterC: _waterC,
              tankLabel: _tankLabel,
              onSelect: (i) => setState(() => _selected = i),
              onWater: (c) => setState(() => _waterC = c),
              onLabel: (l) => setState(() => _tankLabel = l),
            ),
    );
  }
}

/// Opens the recipe editor and follows the recipe if it moved to another
/// combination (a new temperature, say).
Future<void> openRecipeEditor(
  BuildContext context,
  WidgetRef ref,
  CombinationKey from,
  RecipeEditorArgs args,
) async {
  final saved = await context.push<Recipe>('/recipe/edit', extra: args);
  if (saved != null && saved.key != from && context.mounted) {
    context.pushReplacement(comboPath(saved.key));
  }
}

AgitationPattern defaultDeveloperAgitation(WidgetRef ref) {
  final p = ref.read(defaultProcessProvider).value;
  final dev = p?.steps.where((s) => s.kind == StepKind.developer).firstOrNull;
  return dev?.agitation ??
      const Intermittent(initialS: 60, everyS: 60, burstS: 10);
}

RecipeOrigin originOf(TimeRow row) {
  final d = row.datasheet;
  if (d != null) return DatasheetOrigin(d.source.id, page: d.page);
  if (row.community != null) return const ScratchOrigin();
  final r = row.recipe!;
  return r.isOwn ? r.origin : CopyOfOrigin(r.id, r.authorName);
}

String baseLabel(TimeRow row) {
  final d = row.datasheet;
  if (d != null) {
    return '${d.source.publisher}${d.source.docCode != null ? ' ${d.source.docCode}' : ''} datasheet · ${formatTime(row.timeS)}';
  }
  if (row.community != null) {
    return '${row.sourceName} community · ${formatTime(row.timeS)}';
  }
  final r = row.recipe!;
  return '${r.isOwn ? 'your recipe' : '${r.authorName.isEmpty ? 'unknown author' : r.authorName}\'s recipe'} · ${formatTime(row.timeS)}';
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.view,
    required this.selected,
    required this.waterC,
    required this.tankLabel,
    required this.onSelect,
    required this.onWater,
    required this.onLabel,
  });

  final CombinationView view;
  final int? selected;
  final int waterC;
  final String? tankLabel;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onWater;
  final ValueChanged<String?> onLabel;

  int _selectedIndex() {
    if (selected != null && selected! < view.rows.length) return selected!;
    final pre = view.preselectedRow;
    final i = pre == null ? 0 : view.rows.indexOf(pre);
    return i < 0 ? 0 : i;
  }

  static String _sourceLine(TimeRow row) {
    final d = row.datasheet;
    if (row.community != null) {
      return 'Community · ${row.sourceName} · ${row.community!.installs} installs';
    }
    if (d == null) {
      final r = row.recipe!;
      return r.isOwn
          ? 'Your recipe'
          : '${r.authorName.isEmpty ? 'unknown author' : r.authorName} · shared recipe';
    }
    final s = d.source;
    final parts = ['Datasheet', s.publisher];
    if (s.docCode != null) parts.add(s.docCode!);
    if (d.page != null) parts.add('p.${d.page}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final fahrenheit = settings.tempUnit == TempUnit.f;
    final i = _selectedIndex();
    final row = view.rows[i];
    final key = view.key;
    final format = settings.lastFormat.db;
    final volume = format == '120'
        ? settings.volume120Ml
        : settings.volume35mmMl;
    final amounts = amountsFor(key.dilution, volume);
    final usedLast =
        view.preselection?.branch == PreselectBranch.lastUsed &&
        identical(view.preselectedRow, row);

    final est = waterC == key.tempC
        ? null
        : estimateTimeS(row.timeS, fromC: key.tempC, toC: waterC);
    final slot = _nextSlot(ref);

    Future<void> start() => startAndOpen(
      context,
      ref,
      devTimeS: row.timeS,
      meta: SessionMeta(
        key: key,
        timeSource: row.timeSource,
        format: format,
        volumeMl: volume,
      ),
      recipeProcess: row.recipe?.process,
      agitation: row.recipe?.devAgitation,
      label: tankLabel ?? view.note,
    );

    Widget timeRow(int idx, TimeRow r) {
      final selected = idx == i;
      final notesCount = r.recipe == null
          ? 0
          : view.notes.where((n) => n.recipeId == r.recipe!.id).length;
      final title = switch (r.kind) {
        TimeRowKind.datasheet => 'Datasheet',
        TimeRowKind.community => 'Community',
        TimeRowKind.own => 'Your recipe',
        TimeRowKind.received =>
          r.recipe!.authorName.isEmpty
              ? 'unknown author'
              : r.recipe!.authorName,
      };
      final sub = switch (r.kind) {
        TimeRowKind.datasheet => [
          r.datasheet!.source.publisher,
          if (r.datasheet!.source.docCode != null) r.datasheet!.source.docCode!,
          if (r.datasheet!.page != null) 'p.${r.datasheet!.page}',
          if (!r.datasheet!.isPrimary) _methodLabel(r.datasheet!.method),
          if (usedLast && selected) 'used last time',
        ].join(' · '),
        TimeRowKind.community => [
          r.sourceName!,
          '${r.community!.installs} installs',
          if (usedLast && selected) 'used last time',
        ].join(' · '),
        TimeRowKind.own => [
          if (notesCount > 0)
            '$notesCount ${notesCount == 1 ? 'note' : 'notes'}',
        ].join(' · '),
        TimeRowKind.received => [
          'shared recipe',
          if (notesCount > 0)
            '$notesCount ${notesCount == 1 ? 'note' : 'notes'}',
        ].join(' · '),
      };
      final inherited = r.datasheet?.inheritedFromFilmId;
      final rangeText = r.isRange
          ? '${formatTime(r.datasheet!.timeS)}–${formatTime(r.datasheet!.timeMaxS!)} · using ${formatTime(r.timeS)}'
          : null;
      return ListRow(
        key: Key('time-row-$idx'),
        selected: selected,
        boxed: true,
        minHeight: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => onSelect(idx),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: selected ? p.fg : Colors.transparent,
                  border: Border.all(color: selected ? p.fg : p.mut, width: 2),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (sub.isNotEmpty)
                    Text(sub, style: DrkType.sm.copyWith(color: p.mut)),
                  if (rangeText != null)
                    Text(rangeText, style: DrkType.sm.copyWith(color: p.mut)),
                  if (inherited != null)
                    Text(
                      'Inherited from ${_filmName(inherited)}${r.datasheet!.rebrandBasis == 'reported' ? ' (rebrand reported, not confirmed)' : ''}',
                      style: DrkType.sm.copyWith(color: p.mut),
                    ),
                ],
              ),
            ),
            timeText(context, formatTime(r.timeS), size: 26),
          ],
        ),
      );
    }

    final summary = view.summary;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
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
                  Consumer(
                    builder: (context, ref, _) {
                      final starred =
                          ref.watch(isFavouriteProvider(key)).value ?? false;
                      return IconButton(
                        key: const Key('favourite'),
                        tooltip: starred ? 'Remove favourite' : 'Favourite',
                        isSelected: starred,
                        icon: Icon(starred ? Icons.star : Icons.star_border),
                        onPressed: () async {
                          await ref
                              .read(favouritesRepositoryProvider)
                              .toggle(key);
                          ref.read(dataVersionProvider.notifier).state++;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.fg, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.filmLabel, style: DrkType.ti.copyWith(color: p.fg)),
                  const SizedBox(height: 6),
                  Text(
                    '${view.developerLabel} ${key.dilution} · ISO ${key.ei} · ${formatTemp(key.tempC, fahrenheit: fahrenheit)}',
                    style: DrkType.bd.copyWith(color: p.mut),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TIME TO USE', style: labelStyle(context, fg: true)),
                if (usedLast) const DrkChip('Used last time', small: true),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formatTime(row.timeS),
              key: const Key('time-to-use'),
              style: DrkType.tx.copyWith(color: p.fg),
            ),
            const SizedBox(height: 10),
            Text(_sourceLine(row), style: DrkType.sm.copyWith(color: p.mut)),
            const SizedBox(height: 20),
            DrkButton(
              key: const Key('start'),
              label: 'Start',
              kind: DrkButtonKind.primary,
              size: DrkButtonSize.xl,
              onPressed: start,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Runs as', style: DrkType.sm.copyWith(color: p.mut)),
                const SizedBox(width: 8),
                TankTag(slot: slot, label: tankLabel ?? view.note),
                const SizedBox(width: 8),
                Text('·', style: DrkType.sm.copyWith(color: p.mut)),
                TextButton(
                  key: const Key('rename-tank'),
                  onPressed: () async {
                    final name = await _askName(
                      context,
                      tankLabel ?? 'Tank $slot',
                    );
                    if (name != null) onLabel(name.isEmpty ? null : name);
                  },
                  child: Text(
                    'RENAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 11 * .14,
                      color: p.mut,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionLabel(
              summary == null
                  ? '${view.rows.length} ${view.rows.length == 1 ? 'time' : 'times'}'
                  : '${summary.count} times · typically ${formatTime(summary.medianS)} (${formatTime(summary.minS)}–${formatTime(summary.maxS)})',
              bottom: 4,
            ),
            for (final (idx, r) in view.rows.indexed) ...[
              if (r.kind == TimeRowKind.community &&
                  (idx == 0 ||
                      view.rows[idx - 1].kind != TimeRowKind.community))
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SectionLabel('Community', bottom: 4),
                ),
              timeRow(idx, r),
            ],
            const SizedBox(height: 20),
            SectionLabel('Chemistry', bottom: 12),
            Seg(
              labels: [
                '35mm · ${settings.volume35mmMl} ml',
                '120 · ${settings.volume120Ml} ml',
              ],
              selected: format == '120' ? 1 : 0,
              onChanged: (v) => ref
                  .read(settingsRepositoryProvider)
                  .update(
                    lastFormat: v == 1 ? FilmFormat.mm120 : FilmFormat.mm35,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              key: const Key('chemistry'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.s1,
                border: Border.all(color: p.ln2),
                borderRadius: BorderRadius.circular(DrkSpace.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${view.developerLabel} ${key.dilution} · $volume ml',
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      for (final (n, ml) in amounts.solutionsMl.indexed)
                        _Amount(
                          value: _ml(ml),
                          label: amounts.solutionsMl.length > 1
                              ? 'ml part ${n == 0 ? 'A' : 'B'}'
                              : (key.dilution == 'stock' ||
                                    key.dilution == 'working')
                              ? 'ml ${key.dilution}'
                              : 'ml concentrate',
                        ),
                      if (amounts.waterMl > 0)
                        _Amount(value: _ml(amounts.waterMl), label: 'ml water'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel('Your water is another temperature?', bottom: 12),
            Row(
              children: [
                Expanded(
                  child: DrkStepper(
                    key: const Key('water-temp'),
                    value: formatTemp(waterC, fahrenheit: fahrenheit),
                    onMinus: waterC > 10 ? () => onWater(waterC - 1) : null,
                    onPlus: waterC < 45 ? () => onWater(waterC + 1) : null,
                  ),
                ),
                const SizedBox(width: 12),
                if (est != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      timeText(context, '≈ ${formatTime(est)}', size: 26),
                      Text('ESTIMATE', style: labelStyle(context)),
                    ],
                  ),
              ],
            ),
            if (est != null) ...[
              const SizedBox(height: 8),
              Text(
                temperatureEstimateCitation,
                key: const Key('estimate-citation'),
                style: DrkType.sm.copyWith(color: p.mut),
              ),
              TextButton(
                key: const Key('save-estimate'),
                onPressed: () => openRecipeEditor(
                  context,
                  ref,
                  key,
                  RecipeEditorArgs(
                    key: CombinationKey(
                      film: key.film,
                      developer: key.developer,
                      dilution: key.dilution,
                      ei: key.ei,
                      tempC: waterC,
                    ),
                    devTimeS: est,
                    agitation:
                        row.recipe?.devAgitation ??
                        defaultDeveloperAgitation(ref),
                    origin: EstimateOrigin(originOf(row)),
                    baseLabel:
                        'Estimated for ${formatTemp(waterC, fahrenheit: fahrenheit)} from ${baseLabel(row)} at ${formatTemp(key.tempC, fahrenheit: fahrenheit)}',
                  ),
                ),
                child: const Text('SAVE AS MY RECIPE'),
              ),
            ],
            if (view.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionLabel(
                'Notes · ${view.notes.length} · from every recipe',
                bottom: 4,
              ),
              for (final n in view.notes.reversed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.ln2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_noteHeader(n, view), style: labelStyle(context)),
                      const SizedBox(height: 6),
                      Text(n.text, style: DrkType.bd.copyWith(color: p.fg)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            DrkButton(
              key: const Key('customise'),
              label: row.recipe?.isOwn == true ? 'Edit recipe' : 'Customise',
              kind: DrkButtonKind.outline,
              size: DrkButtonSize.large,
              icon: Icons.tune,
              onPressed: () => openRecipeEditor(
                context,
                ref,
                key,
                RecipeEditorArgs(
                  key: key,
                  devTimeS: row.timeS,
                  agitation:
                      row.recipe?.devAgitation ??
                      defaultDeveloperAgitation(ref),
                  origin: originOf(row),
                  baseLabel: baseLabel(row),
                  existing: row.recipe,
                ),
              ),
            ),
            if (row.recipe?.isOwn == true) ...[
              const SizedBox(height: 10),
              DrkButton(
                key: const Key('share'),
                label: 'Share',
                size: DrkButtonSize.large,
                icon: Icons.ios_share,
                onPressed: () => shareRecipe(context, ref, row.recipe!.id),
              ),
            ],
            if (row.recipe != null && !row.recipe!.isOwn) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DrkButton(
                      key: const Key('hide-received'),
                      label: 'Hide',
                      onPressed: () async {
                        await ref
                            .read(recipeRepositoryProvider)
                            .setHidden(row.recipe!.id, true);
                        ref.read(dataVersionProvider.notifier).state++;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DrkButton(
                      key: const Key('remove-received'),
                      label: 'Remove',
                      onPressed: () async {
                        await ref
                            .read(recipeRepositoryProvider)
                            .delete(row.recipe!.id);
                        ref.read(dataVersionProvider.notifier).state++;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _filmName(String id) => id;

  static String _methodLabel(String m) => switch (m) {
    'rotary' => 'rotary',
    'large_tank' => 'large tank',
    'tray' => 'tray',
    'stand' => 'stand',
    _ => m,
  };

  static String _ml(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  int _nextSlot(WidgetRef ref) {
    final used = {
      for (final s in ref.watch(sessionControllerProvider).active) s.tankSlot,
    };
    for (var i = 1; i <= 3; i++) {
      if (!used.contains(i)) return i;
    }
    return 3;
  }

  String _noteHeader(Note n, CombinationView view) {
    final recipe = view.rows
        .map((r) => r.recipe)
        .whereType<Recipe>()
        .where((r) => r.id == n.recipeId)
        .firstOrNull;
    final own = recipe?.isOwn ?? false;
    final who = n.authorName.isEmpty
        ? (own ? 'You' : 'unknown author')
        : n.authorName;
    final d = n.createdAt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$who · ${d.day} ${months[d.month - 1]} ${d.year} · ${own ? 'your recipe' : 'shared recipe'}'
        .toUpperCase();
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      timeText(context, value, size: 30),
      const SizedBox(height: 6),
      Text(label.toUpperCase(), style: labelStyle(context)),
    ],
  );
}

Future<String?> _askName(BuildContext context, String current) {
  final controller = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: context.pal.s1,
      title: Text(
        'Name this tank',
        style: DrkType.ti.copyWith(color: context.pal.fg),
      ),
      content: DrkField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
