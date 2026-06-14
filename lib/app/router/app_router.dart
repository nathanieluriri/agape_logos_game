import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'transitions.dart';

/// App routes. Real screens land later as compositions of widgets; for now a
/// single animated placeholder proves the router + transitions wiring.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          fadeThroughPage(const _HomePlaceholder(), state),
    ),
  ],
);

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('agape_logos_game')));
  }
}
