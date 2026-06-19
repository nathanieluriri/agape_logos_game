import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/account_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../game/placeholder_game_page.dart';
import 'transitions.dart';

/// App routes. Auth screens are optional surfaces reachable from home; they
/// never gate play, so there is no redirect guard.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          fadeThroughPage(const _HomePlaceholder(), state),
    ),
    GoRoute(
      path: '/sign-in',
      pageBuilder: (context, state) => fadeThroughPage(const SignInPage(), state),
    ),
    GoRoute(
      path: '/account',
      pageBuilder: (context, state) => fadeThroughPage(const AccountPage(), state),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) =>
          fadeThroughPage(const PlaceholderGamePage(), state),
    ),
  ],
);

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/account'),
          ),
        ],
      ),
      body: const Center(child: Text('agape_logos_game')),
    );
  }
}
