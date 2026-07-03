import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/account_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/level_complete/presentation/pages/level_complete_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/store/presentation/pages/store_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import 'transitions.dart';

/// App routes. Auth screens are optional surfaces reachable from home; they
/// never gate play, so there is no redirect guard.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => pondRevealPage(const HomePage(), state),
    ),
    GoRoute(
      path: '/sign-in',
      pageBuilder: (context, state) => pondRevealPage(const SignInPage(), state),
    ),
    GoRoute(
      path: '/account',
      pageBuilder: (context, state) => pondRevealPage(const AccountPage(), state),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) =>
          pondRevealPage(const GamePage(), state),
    ),
    GoRoute(
      path: '/level-complete',
      pageBuilder: (context, state) =>
          pondRevealPage(const LevelCompletePage(), state),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          pondRevealPage(const SettingsPage(), state),
    ),
    GoRoute(
      path: '/store',
      pageBuilder: (context, state) =>
          pondRevealPage(const StorePage(), state),
    ),
  ],
);
