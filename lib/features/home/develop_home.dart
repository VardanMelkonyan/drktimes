import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../common/widgets.dart';
import '../picker/picker_state.dart';
import '../session/manual_start_sheet.dart';
import 'mode_shell.dart';
import 'search_tab.dart';

enum HomeTab { favourites, recent, search }

/// The Develop home: Favourites, Recent and Search (FR-004).
class DevelopHome extends ConsumerStatefulWidget {
  const DevelopHome({super.key});

  @override
  ConsumerState<DevelopHome> createState() => _DevelopHomeState();
}

class _DevelopHomeState extends ConsumerState<DevelopHome> {
  HomeTab _tab = HomeTab.favourites;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepositoryProvider).update(lastMode: AppMode.develop);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ModeShell(
      print: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Seg(
            labels: const ['Favourites', 'Recent', 'Search'],
            selected: _tab.index,
            onChanged: (i) => setState(() => _tab = HomeTab.values[i]),
          ),
          const SizedBox(height: DrkSpace.s16),
          Expanded(
            child: switch (_tab) {
              HomeTab.search => const SearchTab(),
              HomeTab.favourites => _Empty(
                key: const Key('empty-favourites'),
                title: 'No favourites yet',
                body: 'Star a film and developer combination and it lives here, one tap from Start.',
                foot: 'Recent · empty',
                footBody: 'Every run you finish or abort shows up in Recent, ready to run again.',
              ),
              HomeTab.recent => _Empty(
                key: const Key('empty-recent'),
                title: 'Nothing recent',
                body: 'Every run you finish or abort shows up here, ready to run again.',
              ),
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
          SizedBox(
            height: DrkSpace.s8,
            child: ColoredBox(color: p.bg),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    super.key,
    required this.title,
    required this.body,
    this.foot,
    this.footBody,
  });

  final String title, body;
  final String? foot, footBody;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: p.ln2, width: 2),
              borderRadius: BorderRadius.circular(DrkSpace.radius),
            ),
            child: Icon(Icons.star_border, color: p.mut),
          ),
          const SizedBox(height: 18),
          Text(title, style: DrkType.dp.copyWith(color: p.fg)),
          const SizedBox(height: 18),
          Text(body, style: DrkType.bd.copyWith(color: p.mut)),
          if (foot != null) ...[
            const SizedBox(height: 24),
            DashedLine(color: p.ln2),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                style: DrkType.sm.copyWith(color: p.mut),
                children: [
                  TextSpan(
                    text: foot!.toUpperCase(),
                    style: labelStyle(context, fg: true),
                  ),
                  TextSpan(text: '\n${footBody ?? ''}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
