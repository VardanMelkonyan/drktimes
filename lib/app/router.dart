import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/mode_shell.dart';
import '../features/print/print_placeholder_screen.dart';

Widget _placeholder(String name) => Scaffold(
  body: SafeArea(child: Center(child: Text(name))),
);

final router = GoRouter(
  initialLocation: '/develop',
  routes: [
    GoRoute(
      path: '/develop',
      builder: (context, state) => const ModeShell(
        print: false,
        child: Center(child: Text('Develop', key: Key('develop-home'))),
      ),
    ),
    GoRoute(
      path: '/print',
      builder: (context, state) => const PrintPlaceholderScreen(),
    ),
    GoRoute(
      path: '/pick/film',
      builder: (context, state) => _placeholder('film'),
    ),
    GoRoute(
      path: '/pick/developer',
      builder: (context, state) => _placeholder('developer'),
    ),
    GoRoute(
      path: '/pick/iso',
      builder: (context, state) => _placeholder('iso'),
    ),
    GoRoute(
      path: '/pick/dilution',
      builder: (context, state) => _placeholder('dilution'),
    ),
    GoRoute(
      path: '/combo/:key',
      builder: (context, state) => _placeholder('combination'),
    ),
    GoRoute(
      path: '/recipe/edit',
      builder: (context, state) => _placeholder('recipe editor'),
    ),
    GoRoute(
      path: '/process/edit',
      builder: (context, state) => _placeholder('process editor'),
    ),
    GoRoute(
      path: '/session',
      builder: (context, state) => _placeholder('session'),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => _placeholder('import'),
    ),
    GoRoute(
      path: '/backup/import',
      builder: (context, state) => _placeholder('backup import'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => _placeholder('settings'),
    ),
  ],
);
