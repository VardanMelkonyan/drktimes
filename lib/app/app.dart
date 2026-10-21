import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import '../domain/exchange/codec.dart';
import '../domain/exchange/document.dart';
import '../domain/exchange/link.dart';
import '../platform/intake.dart';
import 'providers.dart';
import 'theme/theme.dart';

class DrkApp extends ConsumerWidget {
  const DrkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      intakeProvider,
      (_, i) =>
          i?.payloads.listen((p) => routeIncoming(ref.read(routerProvider), p)),
    );
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

/// Decodes an incoming link or file and opens the matching import screen.
/// Anything invalid goes to the "not a valid recipe" screen (FR-056).
void routeIncoming(GoRouter router, IncomingPayload p) {
  ExchangeDocument? doc;
  try {
    doc = switch (p) {
      IncomingLink(:final uri) => LinkCodec.decode(uri.toString()),
      IncomingFile(:final bytes) => ExchangeCodec.decodeString(
        utf8.decode(bytes),
      ),
    };
  } on Object {
    doc = null;
  }
  router.go(
    doc?.kind == ExchangeKind.backup ? '/backup/import' : '/import',
    extra: doc,
  );
}
