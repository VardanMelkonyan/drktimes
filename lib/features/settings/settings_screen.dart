import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/process.dart';
import '../common/widgets.dart';

const _themeOrder = [
  ThemeSetting.system,
  ThemeSetting.light,
  ThemeSetting.dark,
];

/// Settings.dc.html (FR-066). The Safelight theme in the artboard is not part
/// of Part 1 (analysis S1): themes are System, Light and Dark.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.showVolumeKeys});

  /// Override for tests; defaults to Android only (FR-043).
  final bool? showVolumeKeys;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _author = TextEditingController();
  bool _authorSeeded = false;

  @override
  void dispose() {
    _author.dispose();
    super.dispose();
  }

  Future<void> _setTransition(TransitionMode mode) async {
    final repo = ref.read(processRepositoryProvider);
    final s = await ref.read(settingsRepositoryProvider).get();
    final p = await repo.get(s.defaultProcessId);
    await repo.save(p.copyWith(transitionMode: mode));
    ref.invalidate(defaultProcessProvider);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = ref.watch(settingsProvider).value ?? const Settings();
    final repo = ref.read(settingsRepositoryProvider);
    final process = ref.watch(defaultProcessProvider).value;
    if (!_authorSeeded && ref.watch(settingsProvider).hasValue) {
      _author.text = s.authorName;
      _authorSeeded = true;
    }
    final showKeys = widget.showVolumeKeys ?? Platform.isAndroid;

    Widget section(String label, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(label),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );

    Widget volumeRow(String label, int ml, ValueChanged<int> set, String key) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: DrkStepper(
                  key: Key(key),
                  value: '$ml ml',
                  minusLabel: 'Less for $label',
                  plusLabel: 'More for $label',
                  onMinus: ml > 50 ? () => set(ml - 50) : null,
                  onPlus: ml < 2000 ? () => set(ml + 50) : null,
                ),
              ),
            ],
          ),
        );

    Widget kv(
      String title,
      Widget trailing, {
      String? sub,
      VoidCallback? onTap,
    }) => InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.ln2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (sub != null)
                    Text(sub, style: DrkType.sm.copyWith(color: p.mut)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );

    final pace = s.inversionPaceS;
    String paceText(double v) =>
        '1 every ${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()} s';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/develop'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('SETTINGS', style: labelStyle(context, fg: true)),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                border: Border.all(color: p.fg, width: 2),
                borderRadius: BorderRadius.circular(DrkSpace.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your data stays on this phone.',
                    style: DrkType.ti.copyWith(color: p.fg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No account, no sign-in, nothing tracked. Export a copy whenever you like.',
                    style: DrkType.sm.copyWith(color: p.mut),
                  ),
                ],
              ),
            ),
            section('You', [
              Text(
                'Author name · shown on recipes you share',
                style: DrkType.sm.copyWith(color: p.mut),
              ),
              DrkField(
                key: const Key('author-name'),
                controller: _author,
                onChanged: (v) => repo.update(authorName: v),
              ),
            ]),
            section('Tank volumes', [
              volumeRow(
                '35mm',
                s.volume35mmMl,
                (v) => repo.update(volume35mmMl: v),
                'vol-35',
              ),
              volumeRow(
                '120',
                s.volume120Ml,
                (v) => repo.update(volume120Ml: v),
                'vol-120',
              ),
            ]),
            section('Process', [
              kv(
                'Default process',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      process == null
                          ? ''
                          : '${process.steps.length} steps, ${process.enabledSteps.length} on',
                      style: DrkType.sm.copyWith(color: p.mut),
                    ),
                    Icon(Icons.chevron_right, color: p.mut),
                  ],
                ),
                onTap: () => context.push('/process/edit'),
              ),
              kv(
                'Inversion pace',
                SizedBox(
                  width: 190,
                  child: DrkStepper(
                    key: const Key('pace'),
                    value: paceText(pace),
                    height: 44,
                    fontSize: 13,
                    minusLabel: 'Slower',
                    plusLabel: 'Faster',
                    onMinus: pace < 5
                        ? () => repo.update(inversionPaceS: pace + .5)
                        : null,
                    onPlus: pace > 1
                        ? () => repo.update(inversionPaceS: pace - .5)
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Between steps',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Seg(
                      labels: const ['Wait for me', 'Keep going'],
                      selected:
                          process?.transitionMode == TransitionMode.keepGoing
                          ? 1
                          : 0,
                      onChanged: (i) => _setTransition(
                        i == 1
                            ? TransitionMode.keepGoing
                            : TransitionMode.waitForMe,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            section('Sound', [
              kv(
                'Sounds',
                DrkSwitch(
                  key: const Key('sound-switch'),
                  value: s.soundOn,
                  label: 'Sounds',
                  onChanged: (v) => repo.update(soundOn: v),
                ),
                sub: 'chimes, ticks, pips',
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volume',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      key: const Key('volume-slider'),
                      value: s.volume.clamp(0, 1),
                      activeColor: p.fg,
                      inactiveColor: p.ln2,
                      onChanged: (v) => repo.update(volume: v),
                    ),
                  ],
                ),
              ),
              if (showKeys)
                kv(
                  'Volume buttons as Next',
                  DrkSwitch(
                    key: const Key('volume-keys-switch'),
                    value: s.volumeKeyNext,
                    label: 'Volume buttons as Next',
                    onChanged: (v) => repo.update(volumeKeyNext: v),
                  ),
                  sub: 'Android, only while a step is waiting',
                ),
            ]),
            section('Units', [
              Seg(
                labels: const ['°C', '°F'],
                selected: s.tempUnit == TempUnit.f ? 1 : 0,
                onChanged: (i) =>
                    repo.update(tempUnit: i == 1 ? TempUnit.f : TempUnit.c),
              ),
            ]),
            section('Theme', [
              Seg(
                labels: const ['System', 'Light', 'Dark'],
                selected: _themeOrder.indexOf(s.theme),
                onChanged: (i) => repo.update(theme: _themeOrder[i]),
              ),
              const SizedBox(height: 6),
              Text(
                'Turn screen brightness down in the darkroom.',
                style: DrkType.sm.copyWith(color: p.mut),
              ),
            ]),
            Text(
              'drktimes · open source',
              style: DrkType.sm.copyWith(color: p.mut),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
