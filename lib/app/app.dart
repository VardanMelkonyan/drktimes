import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import 'providers.dart';
import 'theme/theme.dart';

class DrkApp extends ConsumerWidget {
  const DrkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    return MaterialApp.router(
      title: 'drktimes',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: switch (settings.theme) {
        ThemeSetting.system => ThemeMode.system,
        ThemeSetting.dark => ThemeMode.dark,
        ThemeSetting.light => ThemeMode.light,
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
