import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../common/widgets.dart';

/// HomeEmpty.dc.html: a dashed icon box, a headline and a hint.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.foot,
    this.footBody,
    this.icon = Icons.star_border,
  });

  final String title, body;
  final String? foot, footBody;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
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
                child: Icon(icon, color: p.mut),
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
        ),
      ),
    );
  }
}

class NoFavourites extends StatelessWidget {
  const NoFavourites({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'No favourites yet',
    body: 'Star a film and developer combination and it lives here, one tap from Start.',
    foot: 'Recent · empty',
    footBody:
        'Every run you finish or abort shows up in Recent, ready to run again.',
  );
}

class NoRecent extends StatelessWidget {
  const NoRecent({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.history,
    title: 'Nothing recent',
    body: 'Every run you finish or abort shows up here, ready to run again.',
  );
}
