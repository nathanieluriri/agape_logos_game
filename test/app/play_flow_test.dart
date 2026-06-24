// test/app/play_flow_test.dart
import 'package:agape_logos_game/app/play_flow.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
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
  Future<String?> idToken() async => null;
}

GoRouter _router(Widget home) => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: '/game',
        builder: (_, __) => const Scaffold(body: Text('GAME PLACEHOLDER')),
      ),
    ]);

void main() {
  testWidgets('signed-in play pauses ambient and opens the game',
      (tester) async {
    const user = AuthUser(uid: 'u1');
    late WidgetRef capturedRef;
    final home = Consumer(builder: (context, ref, _) {
      capturedRef = ref;
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => startPlayFlow(context, ref),
            child: const Text('play'),
          ),
        ),
      );
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
        currentUserProvider.overrideWithValue(user),
        ambientEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: _router(home)),
    ));
    await tester.pump();
    expect(capturedRef.read(ambientPausedProvider), isFalse);

    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GAME PLACEHOLDER'), findsOneWidget);
    expect(capturedRef.read(ambientPausedProvider), isTrue);

    // Pop back from the game; the ambient should resume.
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
    expect(capturedRef.read(ambientPausedProvider), isFalse);
  });

  testWidgets('signed-out play opens the sign-in sheet, not the game',
      (tester) async {
    final home = Consumer(builder: (context, ref, _) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => startPlayFlow(context, ref),
            child: const Text('play'),
          ),
        ),
      );
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
        ambientEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: _router(home)),
    ));
    await tester.pump();

    await tester.tap(find.text('play'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('GAME PLACEHOLDER'), findsNothing);
  });
}
