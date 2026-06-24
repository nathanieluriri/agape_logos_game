import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/account_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../game/placeholder_game_page.dart';
import 'transitions.dart';

/// App routes. Auth screens are optional surfaces reachable from home; they
/// never gate play, so there is no redirect guard.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => fadeThroughPage(const HomePage(), state),
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
