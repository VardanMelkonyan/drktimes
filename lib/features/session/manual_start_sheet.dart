import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/format.dart';
import '../../domain/session_meta.dart';
import '../common/widgets.dart';
import 'start_session.dart';

/// Start a session from a typed developer time, with an optional label.
Future<void> showManualStartSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.pal.s1,
      shape: const RoundedRectangleBorder(),
      builder: (_) => const _ManualStartSheet(),
    );

class _ManualStartSheet extends ConsumerStatefulWidget {
  const _ManualStartSheet();

  @override
  ConsumerState<_ManualStartSheet> createState() => _ManualStartSheetState();
}

class _ManualStartSheetState extends ConsumerState<_ManualStartSheet> {
  final _time = TextEditingController(text: '13:00');
  final _label = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _time.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final s = parseTime(_time.text);
    if (s == null || s < 30 || s > 7200) {
      setState(
        () => _error =
            'Enter a developer time between 0:30 and 120:00, like 13:00.',
      );
      return;
    }
    final label = _label.text.trim();
    final navigator = Navigator.of(context);
    final ok = await startAndOpen(
      context,
      ref,
      devTimeS: s,
      label: label.isEmpty ? null : label,
      meta: SessionMeta(
        timeSource: {'kind': 'manual', if (label.isNotEmpty) 'label': label},
      ),
    );
    if (ok && navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Start with a time',
            style: DrkType.dp.copyWith(color: context.pal.fg),
          ),
          const SizedBox(height: DrkSpace.s16),
          Text('DEVELOPER TIME (MM:SS)', style: labelStyle(context)),
          const SizedBox(height: 6),
          DrkField(
            key: const Key('manual-time'),
            controller: _time,
            keyboardType: TextInputType.datetime,
            autofocus: true,
          ),
          const SizedBox(height: DrkSpace.s12),
          DrkField(
            key: const Key('manual-label'),
            controller: _label,
            hint: 'Film / developer (optional)',
          ),
          if (_error != null) ...[
            const SizedBox(height: DrkSpace.s12),
            Text(_error!, style: DrkType.sm.copyWith(color: context.pal.fg)),
          ],
          const SizedBox(height: DrkSpace.s16),
          DrkButton(
            key: const Key('manual-start'),
            label: 'Start',
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.large,
            onPressed: _go,
          ),
        ],
      ),
    );
  }
}
