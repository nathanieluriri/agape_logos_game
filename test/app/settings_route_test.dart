import 'package:agape_logos_game/app/router/app_router.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Settings is driven from a fixed row via override so the navigated-to page
// renders from synchronous data (the live Drift stream would deadlock under
// fake-async; it is covered at the DAO/controller layers).
const _row = GameSettingsRow(
  id: 0,
  soundEffects: true,
  music: true,
  notifications: true,
  haptics: true,
);

class _FakeAuth implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream<AuthUser?>.value(const AuthUser(uid: 'u1'));
  @override
  AuthUser? get currentUser => const AuthUser(uid: 'u1');
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

void main() {
  testWidgets('tapping the gear navigates to settings', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => Stream.value(_row)),
        authRepositoryProvider.overrideWithValue(_FakeAuth()),
        ambientEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sound effects'), findsOneWidget);
  });
}
