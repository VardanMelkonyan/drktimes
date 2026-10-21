import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/dataset/picker_queries.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/combination_key.dart';
import '../../domain/format.dart';
import '../../domain/process.dart';
import '../../domain/recipe.dart';
import '../common/agitation_editor.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';
import '../process_editor/process_editor_screen.dart';
import 'recipe_editor_args.dart';

/// RecipeEditor.dc.html (FR-014, FR-019–FR-021).
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, required this.args});

  final RecipeEditorArgs args;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  late int _tempC = widget.args.key.tempC;
  late int _timeS = widget.args.devTimeS;
  late AgitationPattern _agitation = widget.args.agitation;
  late Process? _process = widget.args.process ?? widget.args.existing?.process;
  late Recipe? _existing = widget.args.existing;
  final _dilutionController = TextEditingController();
  final _isoController = TextEditingController();
  final _noteController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _dilutionController.text = widget.args.key.dilution;
    _isoController.text = '${widget.args.key.ei}';
  }

  @override
  void dispose() {
    _dilutionController.dispose();
    _isoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  CombinationKey? _buildKey() {
    final k = widget.args.key;
    try {
      return CombinationKey(
        film: k.film,
        developer: k.developer,
        dilution: _dilutionController.text,
        ei: int.parse(_isoController.text.trim()),
        tempC: _tempC,
      );
    } on FormatException {
      _error = 'ISO must be a number from 1 to 25600.';
    } on ArgumentError catch (e) {
      _error = switch (e.name) {
        'dilution' => 'Use 1+N, 1+A+B, stock or working.',
        'ei' => 'ISO must be from 1 to 25600.',
        'tempC' => 'Temperature must be from 10 to 45 °C.',
        _ => 'Check the fields.',
      };
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final key = _buildKey();
    if (key == null) {
      setState(() {});
      return;
    }
    if (_timeS < minDevTimeS || _timeS > maxDevTimeS) {
      setState(
        () => _error = 'Developer time must be between 0:30 and 120:00.',
      );
      return;
    }
    final problems = _agitation.validate();
    if (problems.isNotEmpty) {
      setState(() => _error = problems.first);
      return;
    }
    final recipes = ref.read(recipeRepositoryProvider);
    final author =
        (await ref.read(settingsRepositoryProvider).get()).authorName;
    if (_existing == null) {
      _existing = await recipes.create(
        key: key,
        devTimeS: _timeS,
        devAgitation: _agitation,
        origin: widget.args.origin,
        authorName: author,
        process: _process,
      );
    } else {
      _existing = await recipes.update(
        _existing!,
        key: key,
        devTimeS: _timeS,
        devAgitation: _agitation,
        process: _process,
        clearProcess: _process == null,
        authorName: author,
      );
    }
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) {
      if (context.canPop()) {
        context.pop(_existing);
      } else {
        context.go(comboPath(_existing!.key));
      }
    }
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    final author =
        (await ref.read(settingsRepositoryProvider).get()).authorName;
    // A note needs a saved recipe: save first when this one is new.
    if (_existing == null) {
      await _save();
      if (_existing == null) return;
    }
    await ref
        .read(noteRepositoryProvider)
        .add(recipeId: _existing!.id, authorName: author, text: text);
    _noteController.clear();
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) setState(() {});
  }

  String _originLine() {
    final o = widget.args.existing?.origin ?? widget.args.origin;
    return switch (o) {
      DatasheetOrigin() =>
        'Based on ${widget.args.baseLabel ?? 'a datasheet time'}',
      ScratchOrigin() => 'From scratch',
      CopyOfOrigin(:final authorName) =>
        'Edited copy of ${authorName.isEmpty ? 'unknown author' : authorName}\'s recipe',
      EstimateOrigin() =>
        widget.args.baseLabel ?? 'Estimated from a datasheet time',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final fahrenheit = settings.tempUnit == TempUnit.f;
    final queries = ref.watch(pickerQueriesProvider).value;
    final k = widget.args.key;
    final filmLabel = queries == null ? '' : _filmLabel(queries, k);
    final devLabel = queries == null ? '' : queries.developerLabel(k.developer);
    final box = queries?.boxIso(k.film);
    final ei = int.tryParse(_isoController.text.trim());
    final pp = (ei != null && box != null) ? pushPullLabel(ei, box) : null;
    final notes = _existing == null
        ? const <Note>[]
        : (ref.watch(_notesProvider(_existing!.id)).value ?? const <Note>[]);

    Widget kv(String label, Widget value) => Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.ln2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label.toUpperCase(), style: labelStyle(context)),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          children: [
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    key: const Key('editor-cancel'),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/develop'),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: p.fg,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    _existing == null ? 'NEW RECIPE' : 'YOUR RECIPE',
                    style: labelStyle(context, fg: true),
                  ),
                  SizedBox(
                    width: 96,
                    child: DrkButton(
                      key: const Key('editor-save'),
                      label: 'Save',
                      kind: DrkButtonKind.primary,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: p.ln2),
                borderRadius: BorderRadius.circular(DrkSpace.radius),
              ),
              child: Text(
                _originLine(),
                key: const Key('origin-line'),
                style: DrkType.sm.copyWith(color: p.mut),
              ),
            ),
            const SizedBox(height: 14),
            kv(
              'Film',
              Text(
                filmLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            kv(
              'Developer',
              Text(
                devLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            kv(
              'Dilution',
              SizedBox(
                width: 150,
                child: DrkField(
                  key: const Key('editor-dilution'),
                  controller: _dilutionController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            kv(
              'ISO',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pp != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        pp,
                        key: const Key('push-pull'),
                        style: DrkType.sm.copyWith(color: p.mut),
                      ),
                    ),
                  SizedBox(
                    width: 110,
                    child: DrkField(
                      key: const Key('editor-iso'),
                      controller: _isoController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('TEMPERATURE', style: labelStyle(context)),
            const SizedBox(height: 10),
            DrkStepper(
              key: const Key('editor-temp'),
              value: formatTemp(_tempC, fahrenheit: fahrenheit),
              onMinus: _tempC > 10 ? () => setState(() => _tempC--) : null,
              onPlus: _tempC < 45 ? () => setState(() => _tempC++) : null,
            ),
            const SizedBox(height: 20),
            Text('DEVELOPER TIME', style: labelStyle(context)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: p.ln2),
                borderRadius: BorderRadius.circular(DrkSpace.radius),
              ),
              child: Row(
                children: [
                  _TimeButton(
                    label: '−',
                    sub: '15 s',
                    keyName: 'time-minus',
                    onTap: _timeS > minDevTimeS
                        ? () => setState(
                            () => _timeS = (_timeS - 15).clamp(
                              minDevTimeS,
                              maxDevTimeS,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        formatTime(_timeS),
                        key: const Key('editor-time'),
                        style: DrkType.tl.copyWith(color: p.fg),
                      ),
                    ),
                  ),
                  _TimeButton(
                    label: '+',
                    sub: '15 s',
                    keyName: 'time-plus',
                    onTap: _timeS < maxDevTimeS
                        ? () => setState(
                            () => _timeS = (_timeS + 15).clamp(
                              minDevTimeS,
                              maxDevTimeS,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('DEVELOPER AGITATION', style: labelStyle(context)),
            const SizedBox(height: 10),
            AgitationEditor(
              value: _agitation,
              onChanged: (a) => setState(() => _agitation = a),
            ),
            const SizedBox(height: 20),
            Text('PROCESS', style: labelStyle(context)),
            const SizedBox(height: 10),
            Seg(
              labels: const ['Default', 'Custom'],
              selected: _process == null ? 0 : 1,
              onChanged: (i) async {
                if (i == 0) {
                  setState(() => _process = null);
                } else {
                  final Process base =
                      _process ??
                      (await ref.read(defaultProcessProvider.future));
                  if (!context.mounted) return;
                  final edited = await context.push<Process>(
                    '/process/edit',
                    extra: ProcessEditorArgs(
                      initial: base.copyWith(
                        id:
                            _process?.id ??
                            'custom-${DateTime.now().microsecondsSinceEpoch}',
                      ),
                      forRecipe: true,
                    ),
                  );
                  if (edited != null) setState(() => _process = edited);
                }
              },
            ),
            const SizedBox(height: 20),
            SectionLabel('Notes · log', bottom: 4),
            for (final n in notes)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.ln2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _date(n.createdAt).toUpperCase(),
                      style: labelStyle(context),
                    ),
                    const SizedBox(height: 6),
                    Text(n.text, style: DrkType.bd.copyWith(color: p.fg)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            DrkField(
              key: const Key('editor-note'),
              controller: _noteController,
              hint: 'What changed, how did it turn out?',
            ),
            const SizedBox(height: 10),
            DrkButton(
              key: const Key('editor-add-note'),
              label: 'Add note',
              kind: DrkButtonKind.outline,
              onPressed: _addNote,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                key: const Key('editor-error'),
                style: DrkType.bd.copyWith(
                  color: p.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  static String _filmLabel(PickerQueries q, CombinationKey k) {
    final film = k.film;
    if (film.kind == RefKind.catalog) {
      final f = q.catalog.film(film.id);
      return f == null ? film.id : '${f.brand} ${f.name}';
    }
    for (final f in q.userFilms) {
      if (f.id == film.id) return '${f.brand} ${f.name}';
    }
    return film.id;
  }

  static String _date(DateTime d) {
    const m = [
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
    final l = d.toLocal();
    return '${l.day} ${m[l.month - 1]} ${l.year}';
  }
}

final _notesProvider = FutureProvider.family<List<Note>, String>((
  ref,
  id,
) async {
  ref.watch(dataVersionProvider);
  return ref.watch(noteRepositoryProvider).forRecipe(id);
});

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.sub,
    required this.onTap,
    required this.keyName,
  });

  final String label, sub, keyName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                color: onTap == null ? p.dim : p.fg,
              ),
            ),
            Text(sub, style: TextStyle(fontSize: 10, color: p.mut)),
          ],
        ),
      ),
    );
  }
}
