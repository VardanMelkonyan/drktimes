import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/timeline/session_run.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';
import '../session/manual_start_sheet.dart';
import 'favourites_tab.dart';
import 'mode_shell.dart';
import 'recent_tab.dart';
import 'search_tab.dart';

enum HomeTab { favourites, recent, search }

/// The Develop home: Favourites, Recent and Search (FR-004).
class DevelopHome extends ConsumerStatefulWidget {
  const DevelopHome({super.key, this.initialTab = HomeTab.favourites});

  final HomeTab initialTab;

  @override
  ConsumerState<DevelopHome> createState() => _DevelopHomeState();
}

class _DevelopHomeState extends ConsumerState<DevelopHome> {
  late HomeTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepositoryProvider).update(lastMode: AppMode.develop);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(sessionControllerProvider);
    final active = controller.active;
    return ModeShell(
      print: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active.isNotEmpty) ...[
            _ActiveBanner(sessions: active),
            const SizedBox(height: DrkSpace.s12),
          ],
          Seg(
            labels: const ['Favourites', 'Recent', 'Search'],
            selected: _tab.index,
            onChanged: (i) => setState(() => _tab = HomeTab.values[i]),
          ),
          const SizedBox(height: DrkSpace.s16),
          Expanded(
            child: switch (_tab) {
              HomeTab.search => const SearchTab(),
              HomeTab.favourites => const FavouritesTab(),
              HomeTab.recent => const RecentTab(),
            },
          ),
          DrkButton(
            key: const Key('find-combination'),
            label: 'Find a combination',
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.large,
            icon: Icons.search,
            onPressed: () {
              ref.read(pickerProvider.notifier).reset();
              context.push('/pick/film');
            },
          ),
          const SizedBox(height: 4),
          DrkButton(
            key: const Key('start-with-time'),
            label: 'Start with a time',
            kind: DrkButtonKind.quiet,
            onPressed: () => showManualStartSheet(context),
          ),
        ],
      ),
    );
  }
}

/// A tappable strip for each running tank, back to the session (FR-003).
class _ActiveBanner extends ConsumerWidget {
  const _ActiveBanner({required this.sessions});

  final List<SessionRun> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(clockProvider).now();
    return Column(
      children: [
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              key: Key('active-${s.tankSlot}'),
              onTap: () => context.go('/session'),
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: p.s1,
                  border: Border.all(color: p.fg, width: 2),
                  borderRadius: BorderRadius.circular(DrkSpace.radius),
                ),
                child: Row(
                  children: [
                    TankGlyphMark(
                      slot: s.tankSlot,
                      size: 12,
                      color: context.drk.tankColor(s.tankSlot),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'T${s.tankSlot}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final st = s.stateAt(now);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_phase(st.phase)} · ${st.step?.name ?? 'Ready'}',
                                style: DrkType.sm.copyWith(
                                  color: p.fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                s.tankLabel,
                                style: DrkType.sm.copyWith(color: p.mut),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Icon(Icons.chevron_right, color: p.fg),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _phase(SessionPhase p) => switch (p) {
    SessionPhase.ready => 'Ready',
    SessionPhase.agitate => 'Agitate',
    SessionPhase.rest => 'Running',
    SessionPhase.final10 => 'Last 10 s',
    SessionPhase.dumpPour => 'Dump & pour',
    SessionPhase.washFill => 'Wash',
    SessionPhase.paused => 'Paused',
    SessionPhase.done => 'Done',
    SessionPhase.aborted => 'Aborted',
  };
}
