import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/format.dart';
import '../../domain/process.dart';
import '../common/agitation_editor.dart';
import '../common/widgets.dart';

/// Opens the editor on a process of a recipe; popping returns the edited
/// [Process]. Without args the editor edits the default process.
class ProcessEditorArgs {
  const ProcessEditorArgs({required this.initial, this.forRecipe = true});

  final Process initial;
  final bool forRecipe;
}

/// ProcessEditor.dc.html (FR-029–FR-035, FR-042).
class ProcessEditorScreen extends ConsumerStatefulWidget {
  const ProcessEditorScreen({super.key, this.args});

  final ProcessEditorArgs? args;

  @override
  ConsumerState<ProcessEditorScreen> createState() =>
      _ProcessEditorScreenState();
}

class _ProcessEditorScreenState extends ConsumerState<ProcessEditorScreen> {
  Process? _process;
  String? _expanded;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      _process = widget.args!.initial;
    } else {
      ref.read(defaultProcessProvider.future).then((p) {
        if (mounted) setState(() => _process = p);
      });
    }
  }

  bool get _isDefault => widget.args == null;

  void _setSteps(List<Step> steps) =>
      setState(() => _process = _process!.copyWith(steps: steps));

  void _updateStep(String id, Step Function(Step) f) =>
      _setSteps([for (final s in _process!.steps) s.id == id ? f(s) : s]);

  String _summary(Step s) {
    if (s.kind == StepKind.developer) {
      return 'time and agitation from the recipe';
    }
    final wash = s.wash;
    final dur = wash is IlfordWash
        ? '${wash.fills.length} fills · ${wash.fills.join(', ')} inversions'
        : formatTime(wash is RunningWash ? wash.durationS : s.durationS);
    final agit = s.kind == StepKind.wash
        ? ''
        : ' · ${agitationName(s.agitation).toLowerCase()}';
    return '$dur$agit${s.enabled ? '' : ' · off'}';
  }

  Future<void> _done() async {
    final p = _process!;
    final problems = p.validate();
    if (problems.isNotEmpty) {
      setState(() => _error = problems.first);
      return;
    }
    if (_isDefault) {
      await ref.read(processRepositoryProvider).save(p);
      ref.invalidate(defaultProcessProvider);
      if (mounted) context.pop();
    } else {
      context.pop(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final process = _process;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    if (process == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pace = settings.inversionPaceS;

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
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('PROCESS', style: labelStyle(context, fg: true)),
                  SizedBox(
                    width: 96,
                    child: DrkButton(
                      key: const Key('process-done'),
                      label: 'Done',
                      kind: DrkButtonKind.primary,
                      onPressed: _done,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.fg, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDefault ? 'Default process' : 'Process for this recipe',
                    style: DrkType.ti.copyWith(color: p.fg),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isDefault
                        ? 'Used by every recipe that has no process of its own. Drag to reorder.'
                        : 'Used only by this recipe. Drag to reorder.',
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                ],
              ),
            ),
            ReorderableListView.builder(
              key: const Key('step-list'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: process.steps.length,
              onReorderItem: (from, to) {
                final steps = [...process.steps];
                steps.insert(to, steps.removeAt(from));
                _setSteps(steps);
              },
              itemBuilder: (context, i) {
                final s = process.steps[i];
                final open = _expanded == s.id;
                return Container(
                  key: Key('step-${s.id}'),
                  margin: EdgeInsets.symmetric(vertical: open ? 10 : 0),
                  padding: open
                      ? const EdgeInsets.fromLTRB(4, 4, 14, 16)
                      : EdgeInsets.zero,
                  decoration: open
                      ? BoxDecoration(
                          color: p.s1,
                          border: Border.all(color: p.fg, width: 2),
                          borderRadius: BorderRadius.circular(DrkSpace.radius),
                        )
                      : BoxDecoration(
                          border: Border(bottom: BorderSide(color: p.ln2)),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () =>
                            setState(() => _expanded = open ? null : s.id),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 64),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    semanticLabel: 'Reorder ${s.name}',
                                    color: p.mut,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: s.enabled ? p.fg : p.mut,
                                      ),
                                    ),
                                    Text(
                                      open ? 'editing' : _summary(s),
                                      style: DrkType.sm.copyWith(color: p.mut),
                                    ),
                                  ],
                                ),
                              ),
                              if (s.kind == StepKind.developer)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    'ALWAYS',
                                    style: labelStyle(context),
                                  ),
                                )
                              else
                                DrkSwitch(
                                  key: Key('switch-${s.kind.json}-${s.id}'),
                                  value: s.enabled,
                                  label: s.name,
                                  onChanged: (v) => _updateStep(
                                    s.id,
                                    (x) => x.copyWith(enabled: v),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (open)
                        _StepEditor(
                          step: s,
                          onChanged: (n) => _updateStep(s.id, (_) => n),
                          onRemove: s.kind == StepKind.custom
                              ? () {
                                  setState(() => _expanded = null);
                                  _setSteps([
                                    for (final x in process.steps)
                                      if (x.id != s.id) x,
                                  ]);
                                }
                              : null,
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DrkButton(
              key: const Key('add-step'),
              label: 'Add step',
              icon: Icons.add,
              onPressed: () {
                final id = const Uuid().v4();
                _setSteps([
                  ...process.steps,
                  Step(
                    id: id,
                    kind: StepKind.custom,
                    name: 'Custom step',
                    enabled: true,
                    durationS: 60,
                    agitation: const NoAgitation(),
                  ),
                ]);
                setState(() => _expanded = id);
              },
            ),
            const SizedBox(height: 22),
            SectionLabel('Inversion pace'),
            const SizedBox(height: 10),
            DrkStepper(
              key: const Key('pace-stepper'),
              value:
                  '1 every ${pace == pace.roundToDouble() ? pace.toStringAsFixed(0) : pace} s',
              minusLabel: 'Slower',
              plusLabel: 'Faster',
              onMinus: pace < 5
                  ? () => ref
                        .read(settingsRepositoryProvider)
                        .update(inversionPaceS: pace + .5)
                  : null,
              onPlus: pace > 1
                  ? () => ref
                        .read(settingsRepositoryProvider)
                        .update(inversionPaceS: pace - .5)
                  : null,
            ),
            const SizedBox(height: 22),
            SectionLabel('Between steps'),
            const SizedBox(height: 10),
            for (final (mode, title, text) in const [
              (
                TransitionMode.waitForMe,
                'Wait for me · default',
                'Each dump & pour waits until you press Next.',
              ),
              (
                TransitionMode.keepGoing,
                'Keep going',
                'The next step starts by itself after the dump & pour chime.',
              ),
            ])
              ListRow(
                key: Key('mode-${mode.json}'),
                selected: process.transitionMode == mode,
                boxed: true,
                padding: const EdgeInsets.all(14),
                onTap: () => setState(
                  () => _process = process.copyWith(transitionMode: mode),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(text, style: DrkType.sm.copyWith(color: p.mut)),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                key: const Key('process-error'),
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
}

class _StepEditor extends StatefulWidget {
  const _StepEditor({
    required this.step,
    required this.onChanged,
    this.onRemove,
  });

  final Step step;
  final ValueChanged<Step> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends State<_StepEditor> {
  late final _name = TextEditingController(text: widget.step.name);
  late final _how = TextEditingController(text: widget.step.howTo ?? '');
  late final _dilution = TextEditingController(
    text: widget.step.chemicalDilution ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _how.dispose();
    _dilution.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    final p = context.pal;
    final isDev = s.kind == StepKind.developer;
    final wash = s.wash;

    Widget block(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label.toUpperCase(), style: labelStyle(context)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(
            'Name',
            DrkField(
              key: const Key('step-name'),
              controller: _name,
              onChanged: (v) {
                if (v.isNotEmpty && v.length <= 40) {
                  widget.onChanged(s.copyWith(name: v));
                }
              },
            ),
          ),
          if (!isDev && s.kind == StepKind.wash)
            block(
              'Wash method',
              Seg(
                labels: const ['Ilford fill', 'Running'],
                selected: wash is RunningWash ? 1 : 0,
                onChanged: (i) => widget.onChanged(
                  s.copyWith(
                    wash: i == 0
                        ? const IlfordWash([5, 10, 20])
                        : const RunningWash(600),
                  ),
                ),
              ),
            ),
          if (s.kind == StepKind.wash && wash is IlfordWash)
            block(
              'Fills · inversions each',
              Column(
                children: [
                  for (final (i, n) in wash.fills.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Fill ${i + 1}',
                              style: DrkType.sm.copyWith(color: p.mut),
                            ),
                          ),
                          Expanded(
                            child: DrkStepper(
                              key: Key('fill-$i'),
                              value: '$n',
                              height: 44,
                              fontSize: 15,
                              minusLabel: 'Fill ${i + 1} fewer',
                              plusLabel: 'Fill ${i + 1} more',
                              onMinus: n > 1
                                  ? () => widget.onChanged(
                                      s.copyWith(
                                        wash: IlfordWash([
                                          for (final (j, f)
                                              in wash.fills.indexed)
                                            j == i ? n - 1 : f,
                                        ]),
                                      ),
                                    )
                                  : null,
                              onPlus: n < 50
                                  ? () => widget.onChanged(
                                      s.copyWith(
                                        wash: IlfordWash([
                                          for (final (j, f)
                                              in wash.fills.indexed)
                                            j == i ? n + 1 : f,
                                        ]),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (wash.fills.length < 6)
                        TextButton(
                          key: const Key('add-fill'),
                          onPressed: () => widget.onChanged(
                            s.copyWith(wash: IlfordWash([...wash.fills, 20])),
                          ),
                          child: const Text('ADD FILL'),
                        ),
                      if (wash.fills.length > 1)
                        TextButton(
                          key: const Key('remove-fill'),
                          onPressed: () => widget.onChanged(
                            s.copyWith(
                              wash: IlfordWash(
                                wash.fills.sublist(0, wash.fills.length - 1),
                              ),
                            ),
                          ),
                          child: const Text('REMOVE FILL'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (!isDev && !(s.kind == StepKind.wash && wash is IlfordWash))
            block(
              'Duration',
              DrkStepper(
                key: const Key('step-duration'),
                value: formatTime(
                  wash is RunningWash ? wash.durationS : s.durationS,
                ),
                minusLabel: '30 seconds shorter',
                plusLabel: '30 seconds longer',
                onMinus:
                    (wash is RunningWash ? wash.durationS : s.durationS) > 30
                    ? () => _setDuration(
                        s,
                        (wash is RunningWash ? wash.durationS : s.durationS) -
                            30,
                      )
                    : null,
                onPlus: () => _setDuration(
                  s,
                  (wash is RunningWash ? wash.durationS : s.durationS) + 30,
                ),
              ),
            ),
          if (!(s.kind == StepKind.wash))
            block(
              'Agitation',
              AgitationEditor(
                value: s.agitation,
                onChanged: (a) => widget.onChanged(s.copyWith(agitation: a)),
              ),
            ),
          if (!isDev && s.kind != StepKind.wash)
            block(
              'Chemical dilution · optional',
              DrkField(
                key: const Key('step-dilution'),
                controller: _dilution,
                hint: 'e.g. 1+4 to show pour amounts',
                onChanged: (v) =>
                    widget.onChanged(s.copyWith(chemicalDilution: v.trim())),
              ),
            ),
          block(
            'How-to · optional',
            DrkField(
              key: const Key('step-how'),
              controller: _how,
              hint: 'A reminder shown while this step runs',
              onChanged: (v) {
                if (v.length <= 1000) widget.onChanged(s.copyWith(howTo: v));
              },
            ),
          ),
          if (widget.onRemove != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('remove-step'),
                onPressed: widget.onRemove,
                child: Text('REMOVE STEP', style: TextStyle(color: p.mut)),
              ),
            ),
        ],
      ),
    );
  }

  void _setDuration(Step s, int seconds) {
    final wash = s.wash;
    if (wash is RunningWash) {
      widget.onChanged(s.copyWith(wash: RunningWash(seconds)));
    } else {
      widget.onChanged(s.copyWith(durationS: seconds));
    }
  }
}
