import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/combination/combination_screen.dart';
import '../features/home/develop_home.dart';
import '../features/picker/pick_developer_screen.dart';
import '../features/picker/pick_dilution_screen.dart';
import '../features/picker/pick_film_screen.dart';
import '../features/picker/pick_iso_screen.dart';
import '../features/picker/picker_state.dart';
import '../domain/exchange/document.dart';
import '../features/print/print_placeholder_screen.dart';
import '../features/sharing/import_screen.dart';
import '../features/process_editor/process_editor_screen.dart';
import '../features/recipe_editor/recipe_editor_args.dart';
import '../features/recipe_editor/recipe_editor_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/session/spike_screen.dart';

Widget _placeholder(String name) => Scaffold(
  body: SafeArea(child: Center(child: Text(name))),
);

GoRouter buildRouter({String initialLocation = '/develop'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/develop', builder: (context, state) => const DevelopHome()),
    GoRoute(
      path: '/print',
      builder: (context, state) => const PrintPlaceholderScreen(),
    ),
    GoRoute(
      path: '/pick/film',
      builder: (context, state) => const PickFilmScreen(),
    ),
    GoRoute(
      path: '/pick/developer',
      builder: (context, state) => const PickDeveloperScreen(),
    ),
    GoRoute(
      path: '/pick/iso',
      builder: (context, state) => const PickIsoScreen(),
    ),
    GoRoute(
      path: '/pick/dilution',
      builder: (context, state) => const PickDilutionScreen(),
    ),
    GoRoute(
      path: '/combo/:key',
      builder: (context, state) => CombinationScreen(
        comboKey: comboKeyFromParam(state.pathParameters['key']!),
      ),
    ),
    GoRoute(
      path: '/recipe/edit',
      builder: (context, state) =>
          RecipeEditorScreen(args: state.extra! as RecipeEditorArgs),
    ),
    GoRoute(
      path: '/process/edit',
      builder: (context, state) =>
          ProcessEditorScreen(args: state.extra as ProcessEditorArgs?),
    ),
    GoRoute(
      path: '/session',
      builder: (context, state) => _placeholder('session'),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => ImportScreen(
        key: ValueKey(identityHashCode(state.extra)),
        doc: state.extra as ExchangeDocument?,
      ),
    ),
    GoRoute(
      path: '/backup/import',
      builder: (context, state) => ImportScreen(
        key: ValueKey(identityHashCode(state.extra)),
        doc: state.extra as ExchangeDocument?,
      ),
    ),
    if (kDebugMode)
      GoRoute(path: '/spike', builder: (context, state) => const SpikeScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
