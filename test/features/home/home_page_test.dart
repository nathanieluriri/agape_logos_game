import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/home/presentation/pages/home_page.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/rewards/application/rewards_providers.dart';
import 'package:agape_logos_game/features/rewards/domain/reward_status.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);
  final AuthUser? _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(_user);
  @override
  AuthUser? get currentUser => _user;
  @override
  Future<void> signInWithEmail(String e, String p) async {}
  @override
  Future<void> registerWithEmail(String e, String p) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInAnonymously() async {}
  @override
  Future<void> sendPasswordReset(String e) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<String?> idToken() async => null;
}

/// Keeps the home reward pad from reaching the network in these tests: the pad
/// reads `GET /rewards`, so we stub the controller to a null (hidden) status.
class _StubRewards extends RewardStatusController {
  @override
  Future<RewardStatus?> build() async => null;
}

GoRouter _buildRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/game',
          builder: (_, __) => const Scaffold(body: Text('GAME PLACEHOLDER')),
        ),
      ],
    );

void main() {
  testWidgets('shows the Withdraw pad and no progress or bonus', (tester) async {
    const user = AuthUser(uid: 'u1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
          ambientEnabledProvider.overrideWithValue(false),
          rewardStatusControllerProvider.overrideWith(_StubRewards.new),
          currentUserProvider.overrideWithValue(user),
          // Backend-derived values stubbed so the widget test stays DB-free.
          coinsProvider.overrideWithValue(0),
          nextLevelProvider.overrideWithValue(26),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pump();

    expect(find.text('ZEN WORD'), findsOneWidget);
    expect(find.bySemanticsLabel('Withdraw'), findsOneWidget);
    expect(find.bySemanticsLabel('Bonus Gift'), findsNothing);
    expect(find.textContaining('Completed'), findsNothing);
  });

  testWidgets('Play navigates to the game when signed in', (tester) async {
    const user = AuthUser(uid: 'u1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
          ambientEnabledProvider.overrideWithValue(false),
          rewardStatusControllerProvider.overrideWith(_StubRewards.new),
          currentUserProvider.overrideWithValue(user),
          // Backend-derived values stubbed so the widget test stays DB-free.
          coinsProvider.overrideWithValue(0),
          nextLevelProvider.overrideWithValue(26),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Play Lv.26'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GAME PLACEHOLDER'), findsOneWidget);
  });

  testWidgets('Play opens the sign-in sheet when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
          ambientEnabledProvider.overrideWithValue(false),
          rewardStatusControllerProvider.overrideWith(_StubRewards.new),
          coinsProvider.overrideWithValue(0),
          nextLevelProvider.overrideWithValue(26),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Play Lv.26'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('GAME PLACEHOLDER'), findsNothing);
  });

  testWidgets('navigating to the game pauses the home ambient', (tester) async {
    const user = AuthUser(uid: 'u1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
          ambientEnabledProvider.overrideWithValue(false),
          rewardStatusControllerProvider.overrideWith(_StubRewards.new),
          currentUserProvider.overrideWithValue(user),
          // Backend-derived values stubbed so the widget test stays DB-free.
          coinsProvider.overrideWithValue(0),
          nextLevelProvider.overrideWithValue(26),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pump();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    expect(container.read(ambientPausedProvider), isFalse);

    await tester.tap(find.bySemanticsLabel('Play Lv.26'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(ambientPausedProvider), isTrue);
  });
}
