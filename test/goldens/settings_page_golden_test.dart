// Golden renders for the settings screen (signed-in and signed-out).
//
// Regenerate after a UI tweak with:
//   C:\flutter\bin\flutter test test/goldens/settings_page_golden_test.dart --update-goldens
// The PNGs land next to this file. Settings are injected via a fixed-row
// `settingsProvider` override (the live Drift stream would deadlock under
// fake-async; that path is covered by the DAO/controller unit tests).
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/features/settings/presentation/pages/settings_page.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _row = GameSettingsRow(
  id: 0,
  soundEffects: true,
  music: true,
  notifications: true,
  haptics: true,
  tutorialSeen: false,
);

/// Deterministic, network-free Public profile switch (defaults to private).
class _StubPrivacy extends ProfilePrivacyController {
  @override
  Future<bool> build() async => false;
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._user);
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

void _useSurface(WidgetTester tester, Size logical, {double dpr = 2.0}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(AuthUser? user) => ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => Stream.value(_row)),
        authRepositoryProvider.overrideWithValue(_FakeAuth(user)),
        ambientEnabledProvider.overrideWithValue(false),
        // The Public profile switch reads `GET /me` on build. Stub it so the
        // golden is deterministic and the test stays network-free.
        profilePrivacyControllerProvider.overrideWith(_StubPrivacy.new),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SettingsPage(),
      ),
    );

void main() {
  testWidgets('settings page (signed in)', (tester) async {
    _useSurface(tester, const Size(390, 844));
    await tester.pumpWidget(_app(const AuthUser(uid: 'u1', email: 'a@b.com')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('settings_page.png'),
    );
  });

  testWidgets('settings page (signed out)', (tester) async {
    _useSurface(tester, const Size(390, 844));
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('settings_page_signed_out.png'),
    );
  });
}
