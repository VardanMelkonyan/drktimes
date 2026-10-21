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
                    Text.rich(
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
                    IconButton(
                      key: const Key('settings-button'),
                      tooltip: 'Settings',
                      icon: const Icon(Icons.tune),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              _ModeTabs(print: print),
              const SizedBox(height: DrkSpace.s16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.print});

  final bool print;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget tab(String label, bool on, String route) => Padding(
      padding: const EdgeInsets.only(right: 28),
      child: InkWell(
        onTap: on ? null : () => context.go(route),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 3,
                color: on ? p.fg : Colors.transparent,
              ),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 14 * .14,
              color: on ? p.fg : p.mut,
            ),
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.ln2)),
      ),
      child: Row(
        children: [
          tab('Develop', !print, '/develop'),
          tab('Print', print, '/print'),
        ],
      ),
    );
  }
}
