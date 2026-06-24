import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/home/presentation/pages/home_page.dart';
import 'package:agape_logos_game/features/home/presentation/widgets/home_background.dart';
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
  Future<String?> idToken() async => null;
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
          homeAmbientEnabledProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(user),
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
          homeAmbientEnabledProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(user),
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
          homeAmbientEnabledProvider.overrideWithValue(false),
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
          homeAmbientEnabledProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(user),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pump();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    expect(container.read(homeAmbientPausedProvider), isFalse);

    await tester.tap(find.bySemanticsLabel('Play Lv.26'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(homeAmbientPausedProvider), isTrue);
  });
}
