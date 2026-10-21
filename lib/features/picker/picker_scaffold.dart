import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../common/widgets.dart';

/// Frame shared by the four picker steps: header, title and a body that
/// scrolls, with an optional footer pinned to the bottom.
class PickerScaffold extends StatelessWidget {
  const PickerScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });

  final int step;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WizHeader(
                step: step,
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/develop'),
                onClose: () => context.go('/develop'),
              ),
              const SizedBox(height: DrkSpace.s16),
              if (subtitle != null)
                Text(subtitle!.toUpperCase(), style: labelStyle(context)),
              if (subtitle != null) const SizedBox(height: 4),
              Text(title, style: DrkType.dp.copyWith(color: context.pal.fg)),
              const SizedBox(height: DrkSpace.s16),
              Expanded(child: child),
              if (footer != null) ...[
                const SizedBox(height: DrkSpace.s12),
                footer!,
                const SizedBox(height: DrkSpace.s16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
