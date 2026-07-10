import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/account_page.dart';
import '../../features/dictionary/presentation/pages/dictionary_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/level_complete/presentation/pages/level_complete_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/store/presentation/pages/store_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/multiplayer/presentation/pages/matchmaking_page.dart';
import '../../features/multiplayer/presentation/pages/lobby_page.dart';
import '../../features/multiplayer/presentation/pages/match_page.dart';
import '../../features/multiplayer/presentation/pages/match_result_page.dart';
import '../../features/social/presentation/pages/friends_page.dart';
import '../../features/social/presentation/pages/match_history_page.dart';
import '../../features/social/presentation/pages/public_profile_page.dart';
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
    GoRoute(
      path: '/dictionary',
      pageBuilder: (context, state) =>
          pondRevealPage(const DictionaryPage(), state),
    ),
    GoRoute(
      path: '/multiplayer',
      pageBuilder: (context, state) =>
          pondRevealPage(const MatchmakingPage(), state),
    ),
    GoRoute(
      path: '/multiplayer/lobby/:id',
      pageBuilder: (context, state) => pondRevealPage(
        LobbyPage(matchId: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/multiplayer/match/:id',
      pageBuilder: (context, state) => pondRevealPage(
        MatchPage(matchId: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/multiplayer/result/:id',
      pageBuilder: (context, state) => pondRevealPage(
        MatchResultPage(matchId: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/friends',
      pageBuilder: (context, state) =>
          pondRevealPage(const FriendsPage(), state),
    ),
    // PLAN: /friends/search must be its OWN flat route (not a sub-route of
    // /friends) to match this router's flat style.
    GoRoute(
      path: '/friends/search',
      pageBuilder: (context, state) => pondRevealPage(
        const FriendsPage(initialTab: FriendsTab.find),
        state,
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) =>
          pondRevealPage(const MatchHistoryPage(), state),
    ),
    GoRoute(
      path: '/profile/:uid',
      pageBuilder: (context, state) => pondRevealPage(
        PublicProfilePage(uid: state.pathParameters['uid'] ?? ''),
        state,
      ),
    ),
  ],
);
