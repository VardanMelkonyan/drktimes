import 'package:drktimes/app/providers.dart';
import 'package:drktimes/app/theme/theme.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/features/process_editor/process_editor_screen.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

Future<TestEnv> open(
  WidgetTester tester, {
  ProcessEditorArgs? args,
  void Function(Process?)? onPop,
}) async {
  tester.view.physicalSize = const Size(900, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await TestEnv.create(tester);
  late GoRouter router;
  router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final r = await context.push<Process>('/edit', extra: args);
              onPop?.call(r);
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, state) =>
            ProcessEditorScreen(args: state.extra as ProcessEditorArgs?),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: MaterialApp.router(theme: darkTheme, routerConfig: router),
    ),
  );
  await tester.tap(find.text('open'));
  await env.settle(tester);
  return env;
}

Process initial() => Process.defaults().copyWith(id: 'mine');

Future<void> expand(WidgetTester tester, TestEnv env, String name) async {
  await tester.ensureVisible(find.text(name).first);
  await tester.tap(find.text(name).first);
  await env.settle(tester);
}

void main() {
  testWidgets('reordering moves a step', (tester) async {
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: initial()),
      onPop: (p) => popped = p,
    );
    final list = tester.widget<ReorderableListView>(
      find.byKey(const Key('step-list')),
    );
    list.onReorderItem!(2, 3); // stop bath after fixer
    await env.settle(tester);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    final kinds = [for (final s in popped!.steps) s.kind];
    expect(kinds.indexOf(StepKind.fix), lessThan(kinds.indexOf(StepKind.stop)));
    await env.dispose(tester);
  });

  testWidgets('a process with a second developer step is rejected', (
    tester,
  ) async {
    final p = initial();
    final bad = p.copyWith(
      steps: [
        ...p.steps,
        p.steps[1].copyWith(id: '00000000-0000-4000-8000-0000000000ee'),
      ],
    );
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: bad),
      onPop: (v) => popped = v,
    );
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    expect(
      find.text('a process needs exactly one developer step'),
      findsOneWidget,
    );
    expect(popped, isNull);
    await env.dispose(tester);
  });

  testWidgets('Ilford fills stay within 1–50 inversions', (tester) async {
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: initial()),
      onPop: (v) => popped = v,
    );
    await expand(tester, env, 'Wash');
    final plus = find.descendant(
      of: find.byKey(const Key('fill-2')),
      matching: find.text('+'),
    );
    for (var i = 0; i < 40; i++) {
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.pump();
    }
    await env.settle(tester);
    final minus0 = find.descendant(
      of: find.byKey(const Key('fill-0')),
      matching: find.text('−'),
    );
    for (var i = 0; i < 10; i++) {
      await tester.ensureVisible(minus0);
      await tester.tap(minus0);
      await tester.pump();
    }
    await env.settle(tester);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    final wash =
        popped!.steps.firstWhere((s) => s.kind == StepKind.wash).wash
            as IlfordWash;
    expect(wash.fills, [1, 10, 50]);
    await env.dispose(tester);
  });

  testWidgets('switching the wash to running water', (tester) async {
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: initial()),
      onPop: (v) => popped = v,
    );
    await expand(tester, env, 'Wash');
    final seg = find.text('RUNNING');
    await tester.ensureVisible(seg);
    await tester.tap(seg);
    await env.settle(tester);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    expect(
      popped!.steps.firstWhere((s) => s.kind == StepKind.wash).wash,
      const RunningWash(600),
    );
    await env.dispose(tester);
  });

  testWidgets('custom steps can be added and removed; developer cannot be', (
    tester,
  ) async {
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: initial()),
      onPop: (v) => popped = v,
    );
    await tester.ensureVisible(find.byKey(const Key('add-step')));
    await tester.tap(find.byKey(const Key('add-step')));
    await env.settle(tester);
    expect(find.byKey(const Key('remove-step')), findsOneWidget);
    await tester.tap(find.byKey(const Key('remove-step')));
    await env.settle(tester);
    expect(find.byKey(const Key('remove-step')), findsNothing);
    await expand(tester, env, 'Developer');
    expect(find.byKey(const Key('remove-step')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    expect(popped!.steps.where((s) => s.kind == StepKind.custom), isEmpty);
    await env.dispose(tester);
  });

  testWidgets('the default process saves its transition mode', (tester) async {
    final env = await open(tester);
    await tester.ensureVisible(find.byKey(const Key('mode-keep_going')));
    await tester.tap(find.byKey(const Key('mode-keep_going')));
    await env.settle(tester);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);
    final p = await tester.runAsync(
      () => c.read(processRepositoryProvider).get(Process.defaultId),
    );
    expect(p!.transitionMode, TransitionMode.keepGoing);
    await env.dispose(tester);
  });

  testWidgets('a step edit changes the duration', (tester) async {
    Process? popped;
    final env = await open(
      tester,
      args: ProcessEditorArgs(initial: initial()),
      onPop: (v) => popped = v,
    );
    await expand(tester, env, 'Fixer');
    final plus = find.descendant(
      of: find.byKey(const Key('step-duration')),
      matching: find.text('+'),
    );
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await env.settle(tester);
    await tester.ensureVisible(find.byKey(const Key('process-done')));
    await tester.tap(find.byKey(const Key('process-done')));
    await env.settle(tester);
    expect(
      popped!.steps.firstWhere((s) => s.kind == StepKind.fix).durationS,
      330,
    );
    await env.dispose(tester);
  });
}
