import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

/// App bar with the `drktimes` wordmark and settings button, plus the
/// Develop | Print mode tabs (HomeFavourites.dc.html header).
class ModeShell extends StatelessWidget {
  const ModeShell({super.key, required this.print, required this.child});

  /// True when Print is the selected mode.
  final bool print;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onLongPress: kDebugMode
                          ? () => context.push('/spike')
                          : null,
                      child: Text.rich(
                        TextSpan(
                          text: 'drktimes',
                          children: [
                            WidgetSpan(
                              child: Container(
                                width: 10,
                                height: 16,
                                margin: const EdgeInsets.only(left: 2),
                                color: p.fg,
                              ),
                            ),
                          ],
                        ),
                        style: DrkType.bd.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.54,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('settings-button'),
                      tooltip: 'Settings',
                      icon: const Icon(Icons.tune),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DrkSpace.s16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
