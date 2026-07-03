import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_failure.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/features/settings/presentation/pages/settings_page.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:agape_logos_game/shared/widgets/pond_pill_button.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// settingsProvider is overridden with fixed data so the page renders from
// synchronous data (the live Drift stream would deadlock under fake-async).
// The DB-clearing path of deletion is covered by the controller test (Task 4);
// here we assert the page's navigation outcomes.
const _row = GameSettingsRow(
  id: 0,
  soundEffects: true,
  music: true,
  notifications: true,
  haptics: true,
  tutorialSeen: false,
);

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.deleteFailure});
  final AuthFailure? deleteFailure;
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream<AuthUser?>.value(const AuthUser(uid: 'u1', email: 'a@b.com'));
  @override
  AuthUser? get currentUser => const AuthUser(uid: 'u1', email: 'a@b.com');
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
  Future<void> deleteAccount() async {
    if (deleteFailure != null) throw deleteFailure!;
  }
  @override
  Future<String?> idToken() async => null;
}

Widget _app(AppDatabase db, AuthRepository auth) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('HOME'))),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(
          path: '/sign-in',
          builder: (_, __) => const Scaffold(body: Text('SIGN IN'))),
    ],
  );
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => Stream.value(_row)),
      appDatabaseProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(auth),
      ambientEnabledProvider.overrideWithValue(false),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('confirming delete returns home', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(_app(db, _FakeAuth()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.tap(find.widgetWithText(PondPillButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('requiresRecentLogin routes to sign-in', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
        _app(db, _FakeAuth(deleteFailure: AuthFailure.requiresRecentLogin)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PondPillButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
