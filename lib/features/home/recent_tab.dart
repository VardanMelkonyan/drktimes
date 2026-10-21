import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/format.dart';
import '../../domain/timeline/session_run.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';
import 'empty_states.dart';
import 'favourites_tab.dart';

final recentSessionsProvider = FutureProvider<List<SessionRun>>((ref) {
  ref.watch(dataVersionProvider);
  ref.watch(sessionControllerProvider.select((c) => c.finished.length));
  return ref.watch(sessionRepositoryProvider).recent();
});

/// "Today 19:42", "Yesterday 21:10", "18 Oct 20:09".
String whenLabel(DateTime when, DateTime now) {
  final w = when.toLocal();
  final n = now.toLocal();
  final hm =
      '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  final day = DateTime(w.year, w.month, w.day);
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today $hm';
  if (diff == 1) return 'Yesterday $hm';
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
  return '${w.day} ${m[w.month - 1]} $hm';
}

/// HomeRecent.dc.html: finished and aborted runs, newest first (FR-052).
class RecentTab extends ConsumerWidget {
  const RecentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(recentSessionsProvider).value;
    final q = ref.watch(pickerQueriesProvider).value;
    final now = ref.watch(clockProvider).now();
    final p = context.pal;
    if (runs == null || q == null) return const SizedBox();
    if (runs.isEmpty) return const NoRecent(key: Key('empty-recent'));
    return ListView(
      children: [
        for (final r in runs)
          ListRow(
            key: Key('recent-${r.id}'),
            onTap: () async {
              final key = r.meta.key!;
              await ref
                  .read(settingsRepositoryProvider)
                  .update(
                    lastFormat: r.meta.format == '120'
                        ? FilmFormat.mm120
                        : FilmFormat.mm35,
                  );
              if (context.mounted) context.push(comboPath(key));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            whenLabel(
                              r.finishedAt ?? r.startedAt ?? now,
                              now,
                            ).toUpperCase(),
                            style: labelStyle(context),
                          ),
                          const SizedBox(width: 8),
                          TankTag(
                            slot: r.tankSlot,
                            label: r.tankLabel,
                            size: 9,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        filmTitle(q, r.meta.key!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${keyLine(q, r.meta.key!)} · ${formatTime(r.devTimeS)}',
                        style: DrkType.sm.copyWith(color: p.mut),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            r.status == SessionStatus.completed
                                ? Icons.check
                                : Icons.close,
                            size: 16,
                            color: p.fg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.status == SessionStatus.completed
                                ? 'Completed'
                                : 'Aborted at ${_stepName(r)}',
                            style: DrkType.sm.copyWith(
                              color: p.fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('RUN AGAIN', style: labelStyle(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _stepName(SessionRun r) {
    final i = r.abortedAtStep;
    if (i == null || i >= r.steps.length) return 'the start';
    return r.steps[i].name;
  }
}
