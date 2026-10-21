import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../home/mode_shell.dart';

/// PrintPlaceholder.dc.html (FR-001).
class PrintPlaceholderScreen extends StatelessWidget {
  const PrintPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const red = DrkPalette.red;
    return ModeShell(
      print: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRINT MODE', style: DrkType.lbl.copyWith(color: p.mut)),
                const SizedBox(height: DrkSpace.s20),
                Text(
                  'Coming\nlater.',
                  style: DrkType.dp.copyWith(
                    fontSize: 44,
                    height: 46 / 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.76,
                  ),
                ),
                const SizedBox(height: DrkSpace.s20),
                Text(
                  'Timing for the enlarger, made for the darkroom itself. It '
                  'will run on a safelight-safe screen that uses the red '
                  'channel only.',
                  style: DrkType.bd.copyWith(color: p.mut),
                ),
                const SizedBox(height: DrkSpace.s20),
                Container(
                  padding: const EdgeInsets.all(DrkSpace.s20),
                  decoration: BoxDecoration(
                    color: red.bg,
                    border: Border.all(color: p.ln2),
                    borderRadius: BorderRadius.circular(DrkSpace.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PREVIEW · SAFELIGHT RED',
                            style: DrkType.lbl.copyWith(color: red.mut),
                          ),
                          Text(
                            'G = B = 0',
                            style: DrkType.lbl.copyWith(color: red.mut),
                          ),
                        ],
                      ),
                      const SizedBox(height: DrkSpace.s12),
                      Text(
                        '0:12',
                        style: DrkType.tl.copyWith(
                          color: red.fg,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(DrkSpace.targetSession),
              foregroundColor: p.fg,
              side: BorderSide(color: p.fg, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DrkSpace.radius),
              ),
            ),
            onPressed: () => context.go('/develop'),
            child: Text(
              'BACK TO DEVELOP',
              style: DrkType.bd.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 16 * .14,
              ),
            ),
          ),
          const SizedBox(height: DrkSpace.s16),
        ],
      ),
    );
  }
}
