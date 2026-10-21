import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/process.dart';
import '../../domain/session_meta.dart';
import '../../domain/sessions.dart';

/// The process a session starts with: the recipe's own, else the settings'
/// default, with the developer step's agitation taken from the recipe when
/// there is one.
Future<Process> processFor(
  WidgetRef ref, {
  Process? recipeProcess,
  AgitationPattern? agitation,
}) async {
  final settings = await ref.read(settingsRepositoryProvider).get();
  var p =
      recipeProcess ??
      await ref.read(processRepositoryProvider).get(settings.defaultProcessId);
  if (agitation != null) {
    p = p.copyWith(
      steps: [
        for (final s in p.steps)
          s.kind == StepKind.developer ? s.copyWith(agitation: agitation) : s,
      ],
    );
  }
  return p;
}

/// Starts a session and opens it. Shows the tank-limit message instead when
/// three are already running (FR-068).
Future<bool> startAndOpen(
  BuildContext context,
  WidgetRef ref, {
  required int devTimeS,
  required SessionMeta meta,
  Process? recipeProcess,
  AgitationPattern? agitation,
  String? label,
}) async {
  final process = await processFor(
    ref,
    recipeProcess: recipeProcess,
    agitation: agitation,
  );
  try {
    await ref
        .read(sessionControllerProvider)
        .start(process: process, devTimeS: devTimeS, meta: meta, label: label);
  } on TankLimitReached catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    return false;
  }
  if (context.mounted) context.go('/session');
  return true;
}

/// Volume for [format] from the settings.
int volumeFor(Settings s, String format) =>
    format == '120' ? s.volume120Ml : s.volume35mmMl;
