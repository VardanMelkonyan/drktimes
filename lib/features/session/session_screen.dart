import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/amounts.dart';
import '../../domain/format.dart';
import '../../domain/process.dart';
import '../../domain/timeline/session_run.dart';
import '../../data/dataset/picker_queries.dart';
import '../common/widgets.dart';
import '../home/favourites_tab.dart' show filmTitle, keyLine;
import 'done_screen.dart';

/// All running tanks (FR-035–FR-050, FR-068–FR-070): the tank that needs
/// each as its own colour-coded card. With more than one tank running there
/// is no sound: the cards are the cue.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(sessionControllerProvider);
    final now = ref.watch(clockProvider).now();
    final p = context.pal;
    if (c.active.isEmpty) {
      if (c.finished.isNotEmpty) return DoneScreen(session: c.finished.first);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/develop');
      });
      return const Scaffold();
    }
    // Slot order, so a card never jumps while its tank is running.
    final sessions = c.active;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final multi = sessions.length > 1;
                final n = sessions.length;
                // Cards share the screen so two or three fit without scrolling.
                final cardH =
                    (box.maxHeight -
                        24 -
                        16 * n -
                        (c.backgroundCuesOff ? 80 : 0)) /
                    n;
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DrkSpace.s20,
                    vertical: 12,
                  ),
                  children: [
                    if (c.backgroundCuesOff)
                      Container(
                        key: const Key('bg-cues-off'),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.fg),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Background cues are off. Keep the screen on, or allow notifications in Settings.',
                                style: DrkType.sm.copyWith(color: p.fg),
                              ),
                            ),
                            TextButton(
                              onPressed: c.openNotificationSettings,
                              child: const Text('OPEN SETTINGS'),
                            ),
                          ],
                        ),
                      ),
                    for (final t in sessions)
                      if (!multi)
                        _TankView(session: t, now: now, multi: false)
                      else
                        Container(
                          key: Key('card-${t.tankSlot}'),
                          height: cardH,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: p.s1,
                            border: Border.all(
                              color: context.drk.tankColor(t.tankSlot),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              DrkSpace.radius,
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, inner) {
                              // Content is laid out at its natural height and
                              // spread over the card; if the card is shorter it
                              // is scaled down but still spans the full width.
                              final scale = math.min(
                                1.0,
                                inner.maxHeight / _compactHeight,
                              );
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: inner.maxWidth / scale,
                                  height: inner.maxHeight / scale,
                                  child: _TankView(
                                    session: t,
                                    now: now,
                                    multi: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    if (!multi)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: DrkButton(
                          key: const Key('add-tank'),
                          label: 'Back to home',
                          kind: DrkButtonKind.quiet,
                          onPressed: () => context.go('/develop'),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (c.showBackgroundNotice)
              _NoticeSheet(onOk: c.acknowledgeBackgroundNotice),
            if (c.active.any((s) => s.stateAt(now).undoAvailable))
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Container(
                  key: const Key('undo-toast'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: p.fg,
                    borderRadius: BorderRadius.circular(DrkSpace.radius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Next pressed',
                          style: TextStyle(color: p.inv),
                        ),
                      ),
                      TextButton(
                        key: const Key('undo'),
                        onPressed: c.undo,
                        child: Text(
                          'UNDO',
                          style: TextStyle(
                            color: p.inv,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticeSheet extends StatelessWidget {
  const _NoticeSheet({required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        key: const Key('bg-notice'),
        color: p.s1,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ticks need the screen on; cues still arrive as notifications.',
              style: DrkType.bd.copyWith(color: p.fg),
            ),
            const SizedBox(height: 12),
            DrkButton(
              label: 'OK',
              kind: DrkButtonKind.primary,
              onPressed: onOk,
            ),
          ],
        ),
      ),
    );
  }
}

SessionVisual visualOf(SessionPhase ph) => switch (ph) {
  SessionPhase.ready => SessionVisual.ready,
  SessionPhase.agitate => SessionVisual.agitate,
  SessionPhase.rest => SessionVisual.rest,
  SessionPhase.final10 => SessionVisual.final10,
  SessionPhase.dumpPour => SessionVisual.dumpPour,
  SessionPhase.washFill => SessionVisual.wash,
  SessionPhase.paused => SessionVisual.paused,
  SessionPhase.done || SessionPhase.aborted => SessionVisual.done,
};

String chipLabel(SessionState st) => switch (st.phase) {
  SessionPhase.ready => 'Ready',
  SessionPhase.agitate => 'Agitate',
  SessionPhase.rest => 'Rest',
  SessionPhase.final10 => '! Last 10 s',
  SessionPhase.dumpPour => 'Dump → pour',
  SessionPhase.washFill => 'Wash · fill ${st.fillIndex! + 1}/${st.fillCount}',
  SessionPhase.paused => 'Paused',
  SessionPhase.done => 'Done',
  SessionPhase.aborted => 'Aborted',
};

/// A state chip: one shape per state, so colour is never the only cue.
class StateChip extends StatelessWidget {
  const StateChip({super.key, required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = context.drk.chipShape(visualOf(state.phase));
    final filled = shape == ChipShape.filled;
    final deco = switch (shape) {
      ChipShape.filled => BoxDecoration(
        color: p.fg,
        borderRadius: BorderRadius.circular(3),
      ),
      ChipShape.hairline => BoxDecoration(
        border: Border.all(color: p.ln2),
        borderRadius: BorderRadius.circular(3),
      ),
      ChipShape.doubleRule => BoxDecoration(
        border: Border.all(color: p.fg, width: 3),
        borderRadius: BorderRadius.circular(3),
      ),
      ChipShape.hatched || ChipShape.striped => BoxDecoration(
        border: Border.all(
          color: p.fg,
          width: 4,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      _ => BoxDecoration(
        border: Border.all(color: p.fg),
        borderRadius: BorderRadius.circular(3),
      ),
    };
    final color = filled ? p.inv : (shape == ChipShape.hairline ? p.mut : p.fg);
    return Container(
      key: Key('chip-${state.phase.name}'),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: deco,
      child: Text(
        chipLabel(state).toUpperCase(),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          color: color,
        ),
      ),
    );
  }
}

/// "Kodak Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C": what is being developed.
String _what(SessionRun session, PickerQueries? q) {
  final key = session.meta.key;
  if (key == null) {
    return (session.meta.timeSource['label'] as String?) ?? session.tankLabel;
  }
  if (q == null) return session.tankLabel;
  // Lines may break only after a dot: spaces inside a part are non-breaking.
  final parts = [filmTitle(q, key), ...keyLine(q, key).split(' · ')];
  return parts.map((x) => x.replaceAll(' ', '\u00A0')).join('\u00A0· ');
}

/// The step's planned time as first set; adjustments and pauses never change it.
String _plannedTime(SessionRun session, Step s) {
  if (s.kind == StepKind.developer) return formatTime(session.devTimeS);
  final w = s.wash;
  if (w is IlfordWash) return '${w.fills.length}×';
  if (w is RunningWash) return formatTime(w.durationS);
  return formatTime(s.durationS);
}

/// How far each step's bar is filled.
List<double> _fractions(SessionRun session, SessionState st) {
  final n = session.steps.length;
  if (st.phase == SessionPhase.ready || st.stepIndex == null) {
    return List.filled(n, 0);
  }
  final idx = st.stepIndex!;
  var cur = 1.0;
  if (st.fillCount != null) {
    final done = st.phase == SessionPhase.dumpPour
        ? 1.0
        : (st.inversionsDone ?? 0) / (st.inversionsTarget ?? 1);
    cur = (st.fillIndex! + done) / st.fillCount!;
  } else if (st.remaining != null) {
    final adjust =
        session.runs.where((r) => r.stepIndex == idx).lastOrNull?.adjustMs ?? 0;
    final total = session.planFor(idx, adjust).durationMs ?? 1;
    cur = 1 - st.remaining!.inMilliseconds / total;
  }
  return [
    for (var i = 0; i < n; i++)
      i < idx ? 1.0 : (i == idx ? cur.clamp(0.0, 1.0) : 0.0),
  ];
}

/// Natural height of a compact (multi-tank) card's content.
const _compactHeight = 330.0;

class _TankView extends ConsumerWidget {
  const _TankView({
    required this.session,
    required this.now,
    required this.multi,
  });

  final SessionRun session;
  final DateTime now;
  final bool multi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final c = ref.read(sessionControllerProvider);
    final queries = ref.watch(pickerQueriesProvider).value;
    final st = session.stateAt(now);
    final step = st.step;
    final steps = session.steps;
    final idx = st.stepIndex ?? 0;
    final nextStep = idx + 1 < steps.length ? steps[idx + 1] : null;
    const prefix = '';

    String bigTime() {
      if (st.phase == SessionPhase.ready) return formatTime(session.devTimeS);
      if (st.phase == SessionPhase.dumpPour) {
        return '+${formatTime(st.waited?.inSeconds ?? 0)}';
      }
      if (st.inversionsTarget != null) {
        return '${st.inversionsDone}/${st.inversionsTarget}';
      }
      return formatTime(((st.remaining?.inMilliseconds ?? 0) + 999) ~/ 1000);
    }

    String headline() {
      switch (st.phase) {
        case SessionPhase.ready:
          return '${prefix}Pour ${steps.first.name}';
        case SessionPhase.dumpPour:
          if (st.fillIndex != null && st.fillIndex! + 1 < st.fillCount!) {
            return '${prefix}Dump water → refill';
          }
          return nextStep == null
              ? '${prefix}Dump ${step!.name}'
              : '${prefix}Dump ${step!.name} → pour ${nextStep.name}';
        default:
          return '$prefix${step?.name ?? ''}';
      }
    }

    // The numerals pulse once per inversion, in step with the metronome tick.
    final w = st.windowElapsed;
    final pulse = w == null || session.paceMs <= 0
        ? 1.0
        : 0.2 +
              0.8 *
                  (0.5 +
                      0.5 *
                          math.cos(
                            2 *
                                math.pi *
                                (w.inMilliseconds % session.paceMs) /
                                session.paceMs,
                          ));
    final isWait = st.phase == SessionPhase.dumpPour;
    final running =
        st.phase == SessionPhase.agitate ||
        st.phase == SessionPhase.rest ||
        st.phase == SessionPhase.final10 ||
        st.phase == SessionPhase.washFill;
    const nextLabel = 'Next';

    // Every element has a fixed slot, so nothing moves when the state changes.
    final bigColor = st.phase == SessionPhase.paused
        ? p.mut
        : multi
        ? context.drk.tankColor(session.tankSlot)
        : p.fg;
    final mainH = multi ? DrkSpace.targetSession : DrkSpace.targetNext;
    final gap = multi ? const SizedBox.shrink() : const SizedBox(height: 16);
    final showControls = running || st.phase == SessionPhase.paused;

    Widget main() {
      if (st.phase == SessionPhase.ready) {
        return DrkButton(
          key: const Key('begin'),
          label: 'Start',
          kind: DrkButtonKind.primary,
          size: multi ? DrkButtonSize.large : DrkButtonSize.xl,
          onPressed: () => c.begin(session),
        );
      }
      if (isWait) {
        return DrkButton(
          key: const Key('next'),
          label: nextLabel,
          kind: DrkButtonKind.primary,
          size: multi ? DrkButtonSize.large : DrkButtonSize.xl,
          onPressed: () => c.nextOn(session),
        );
      }
      return const SizedBox();
    }

    final controls = SizedBox(
      height: multi ? 44 : 48,
      child: Visibility(
        visible: showControls,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Row(
          children: [
            if (st.phase != SessionPhase.washFill) ...[
              Expanded(
                child: DrkButton(
                  key: const Key('minus30'),
                  label: '−30 s',
                  onPressed: showControls ? () => c.adjust(session, -30) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DrkButton(
                  key: const Key('plus30'),
                  label: '+30 s',
                  onPressed: showControls ? () => c.adjust(session, 30) : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: st.phase == SessionPhase.paused
                  ? DrkButton(
                      key: const Key('resume'),
                      label: 'Resume',
                      kind: DrkButtonKind.outline,
                      onPressed: () => c.resume(session),
                    )
                  : DrkButton(
                      key: const Key('pause'),
                      label: 'Pause',
                      onPressed: showControls
                          ? () => _confirm(
                              context,
                              'Pause?',
                              'The chemistry keeps working while paused.',
                              () => c.pause(session),
                            )
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
    final abortButton = DrkButton(
      key: const Key('abort'),
      label: 'Abort',
      kind: DrkButtonKind.quiet,
      onPressed: () => _confirm(
        context,
        'Abort this run?',
        'The run is saved as aborted.',
        () => c.abort(session),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: multi
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      children: [
        if (!multi) ...[
          Text(
            _what(session, queries),
            key: const Key('what'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: DrkType.bd.copyWith(color: p.mut),
          ),
          gap,
        ],
        SizedBox(
          height: 30,
          child: Row(
            children: [
              if (multi) ...[
                Flexible(
                  child: TankTag(
                    slot: session.tankSlot,
                    label: session.tankLabel,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Opacity(
                opacity: pulse,
                child: StateChip(state: st),
              ),
            ],
          ),
        ),
        gap,
        SizedBox(
          height: multi ? 32 : 64,
          child: Text(
            headline(),
            key: const Key('headline'),
            maxLines: multi ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: DrkType.dp.copyWith(color: p.fg),
          ),
        ),
        gap,
        Opacity(
          opacity: pulse,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              bigTime(),
              key: const Key('big-time'),
              maxLines: 1,
              softWrap: false,
              style: (multi ? DrkType.tl : DrkType.tx).copyWith(
                color: bigColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        gap,
        SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: st.phase == SessionPhase.final10
                ? _Pips(remaining: st.remaining!)
                : multi && st.phase == SessionPhase.ready
                ? _Amounts(session: session)
                : Text(
                    st.phase == SessionPhase.rest &&
                            st.untilNextAgitation != null
                        ? 'Agitate in ${formatTime(st.untilNextAgitation!.inSeconds)}'
                        : '',
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
          ),
        ),
        if (!multi) ...[
          gap,
          SizedBox(
            height: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                nextStep != null && !isWait && st.phase != SessionPhase.ready
                    ? 'Next · ${nextStep.name}'
                    : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DrkType.bd.copyWith(color: p.mut),
              ),
            ),
          ),
        ],
        gap,
        _Progress(
          steps: steps,
          times: [for (final x in steps) _plannedTime(session, x)],
          fractions: _fractions(session, st),
          current: idx,
          ready: st.phase == SessionPhase.ready,
        ),
        if (!multi) ...[
          gap,
          SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.topLeft,
              child: st.phase == SessionPhase.ready
                  ? _Amounts(session: session)
                  : multi
                  ? null
                  : Text(
                      step?.howTo ?? '',
                      key: const Key('howto'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DrkType.bd.copyWith(color: p.mut),
                    ),
            ),
          ),
        ],
        gap,
        SizedBox(height: mainH, child: main()),
        gap,
        if (multi)
          Row(
            children: [
              Expanded(child: controls),
              const SizedBox(width: 8),
              SizedBox(width: 92, height: 44, child: abortButton),
            ],
          )
        else ...[
          controls,
          gap,
          abortButton,
        ],
      ],
    );
  }
}

Future<void> _confirm(
  BuildContext context,
  String title,
  String body,
  VoidCallback ok,
) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(
        key: const Key('confirm-no'),
        onPressed: () => Navigator.pop(ctx),
        child: const Text('CANCEL'),
      ),
      TextButton(
        key: const Key('confirm-yes'),
        onPressed: () {
          Navigator.pop(ctx);
          ok();
        },
        child: const Text('YES'),
      ),
    ],
  ),
);

class _Pips extends StatelessWidget {
  const _Pips({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final left = ((remaining.inMilliseconds + 999) ~/ 1000).clamp(0, 10);
    return Row(
      children: [
        for (var i = 0; i < 10; i++)
          Expanded(
            child: Container(
              height: 24,
              margin: EdgeInsets.only(right: i < 9 ? 6 : 0),
              decoration: BoxDecoration(
                color: i < left ? p.fg : Colors.transparent,
                border: Border.all(color: p.fg, width: 2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

/// One bar per step: the planned time above it (never changes), the bar
/// filling as the step runs, the name below.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.steps,
    required this.times,
    required this.fractions,
    required this.current,
    required this.ready,
  });

  final List<Step> steps;
  final List<String> times;
  final List<double> fractions;
  final int current;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        for (final (i, s) in steps.indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    times[i],
                    key: Key('step-time-$i'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: DrkType.lbl.copyWith(
                      fontSize: 10,
                      letterSpacing: 0,
                      color: i == current && !ready ? p.fg : p.mut,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(height: 6, color: p.ln2),
                      FractionallySizedBox(
                        widthFactor: fractions[i].clamp(0.0, 1.0),
                        child: Container(
                          key: Key('step-bar-$i'),
                          height: 6,
                          color: p.fg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DrkType.lbl.copyWith(
                      fontSize: 9,
                      color: i == current && !ready ? p.fg : p.mut,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Amounts extends StatelessWidget {
  const _Amounts({required this.session});

  final SessionRun session;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final key = session.meta.key;
    final step = session.steps.first;
    final dil = step.kind == StepKind.developer
        ? key?.dilution
        : step.chemicalDilution;
    if (dil == null || dil.isEmpty) return const SizedBox();
    String text;
    try {
      text = amountsFor(dil, session.meta.volumeMl).describe();
    } on FormatException {
      return const SizedBox();
    }
    return Text(
      '$dil · ${session.meta.volumeMl} ml → $text',
      key: const Key('amounts'),
      style: DrkType.bd.copyWith(color: p.fg),
    );
  }
}
