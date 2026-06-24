import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/auth/presentation/widgets/auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  bool guestCalled = false;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();
  @override
  AuthUser? get currentUser => null;
  @override
  Future<void> signInWithEmail(String e, String p) async {}
  @override
  Future<void> registerWithEmail(String e, String p) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInAnonymously() async => guestCalled = true;
  @override
  Future<void> sendPasswordReset(String e) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> idToken() async => null;
}

void main() {
  testWidgets('shows Google + guest, expands email, and guest calls the repo',
      (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: AuthSheetContent()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);

    // Before expanding: toggle label reads "Use email instead".
    expect(find.text('Use email instead'), findsOneWidget);
    expect(find.text('Hide email sign-in'), findsNothing);

    // Tap the toggle to expand the email section.
    await tester.tap(find.text('Use email instead'));
    await tester.pump(const Duration(milliseconds: 400));

    // After expanding: toggle label flips and FilledButton is visible.
    expect(find.text('Hide email sign-in'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pump();
    expect(repo.guestCalled, isTrue);
  });
}
