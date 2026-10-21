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
import '../common/widgets.dart';
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
            ListView(
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
                    decoration: BoxDecoration(border: Border.all(color: p.fg)),
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
                  Container(
                    key: Key('card-${t.tankSlot}'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.s1,
                      border: Border(
                        left: BorderSide(
                          color: context.drk.tankColor(t.tankSlot),
                          width: 6,
                        ),
                        top: BorderSide(
                          color: context.drk.tankColor(t.tankSlot),
                        ),
                        right: BorderSide(
                          color: context.drk.tankColor(t.tankSlot),
                        ),
                        bottom: BorderSide(
                          color: context.drk.tankColor(t.tankSlot),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(DrkSpace.radius),
                    ),
                    child: _TankView(
                      session: t,
                      now: now,
                      multi: sessions.length > 1,
                    ),
                  ),
                if (sessions.length < 3)
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
    final st = session.stateAt(now);
    final step = st.step;
    final steps = session.steps;
    final idx = st.stepIndex ?? 0;
    final nextStep = idx + 1 < steps.length ? steps[idx + 1] : null;
    final prefix = multi ? '${session.tankLabel} · ' : '';

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
    final nextLabel = multi ? 'Next · ${session.tankLabel}' : 'Next';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TankTag(slot: session.tankSlot, label: session.tankLabel),
            StateChip(state: st),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          headline(),
          key: const Key('headline'),
          style: DrkType.dp.copyWith(color: p.fg),
        ),
        const SizedBox(height: 12),
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
              style: DrkType.tx.copyWith(
                color: st.phase == SessionPhase.paused
                    ? p.mut
                    : multi
                    ? context.drk.tankColor(session.tankSlot)
                    : p.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (st.phase == SessionPhase.final10) _Pips(remaining: st.remaining!),
        if (st.phase == SessionPhase.rest && st.untilNextAgitation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Agitate in ${formatTime(st.untilNextAgitation!.inSeconds)}',
              style: DrkType.sm.copyWith(color: p.mut),
            ),
          ),
        if (nextStep != null && !isWait && st.phase != SessionPhase.ready)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Next · ${nextStep.name}',
              style: DrkType.bd.copyWith(color: p.mut),
            ),
          ),
        const SizedBox(height: 16),
        _Progress(
          steps: steps,
          current: idx,
          ready: st.phase == SessionPhase.ready,
        ),
        if (st.phase == SessionPhase.ready) _Amounts(session: session),
        if (step?.howTo != null && step!.howTo!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              step.howTo!,
              key: const Key('howto'),
              style: DrkType.bd.copyWith(color: p.mut),
            ),
          ),
        const SizedBox(height: 24),
        if (st.phase == SessionPhase.ready)
          DrkButton(
            key: const Key('begin'),
            label: 'Start',
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.xl,
            onPressed: () => c.begin(session),
          )
        else if (isWait)
          DrkButton(
            key: const Key('next'),
            label: nextLabel,
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.xl,
            onPressed: () => c.nextOn(session),
          ),
        if (running || st.phase == SessionPhase.paused) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (st.phase != SessionPhase.washFill &&
                  st.remaining != null) ...[
                Expanded(
                  child: DrkButton(
                    key: const Key('minus30'),
                    label: '−30 s',
                    onPressed: () => c.adjust(session, -30),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DrkButton(
                    key: const Key('plus30'),
                    label: '+30 s',
                    onPressed: () => c.adjust(session, 30),
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
                        onPressed: () => _confirm(
                          context,
                          'Pause?',
                          'The chemistry keeps working while paused.',
                          () => c.pause(session),
                        ),
                      ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        DrkButton(
          key: const Key('abort'),
          label: 'Abort',
          kind: DrkButtonKind.quiet,
          onPressed: () => _confirm(
            context,
            'Abort this run?',
            'The run is saved as aborted.',
            () => c.abort(session),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          for (var i = 0; i < 10; i++)
            Expanded(
              child: Container(
                height: 34,
                margin: EdgeInsets.only(right: i < 9 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < left ? p.fg : Colors.transparent,
                  border: Border.all(color: p.fg, width: 2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.steps,
    required this.current,
    required this.ready,
  });

  final List<Step> steps;
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
                  Container(
                    height: 6,
                    color: !ready && i <= current ? p.fg : p.ln2,
                  ),
                  const SizedBox(height: 6),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        '$dil · ${session.meta.volumeMl} ml → $text',
        key: const Key('amounts'),
        style: DrkType.bd.copyWith(color: p.fg),
      ),
    );
  }
}
