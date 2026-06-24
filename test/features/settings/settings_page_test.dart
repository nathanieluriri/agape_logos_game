import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/features/settings/presentation/pages/settings_page.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixed settings row injected via a provider override so the page renders from
// synchronous data. The real Drift-backed stream is integration-tested at the
// DAO and controller layers (game_settings_dao_test, settings_controller_test);
// driving the widget off the live stream would deadlock under fake-async.
const _row = GameSettingsRow(
  id: 0,
  soundEffects: true,
  music: true,
  notifications: false, // distinct value, to prove the page binds it to its switch
  haptics: true,
);

class _FakeAuth implements AuthRepository {
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
  Future<void> deleteAccount() async {}
  @override
  Future<String?> idToken() async => null;
}

void main() {
  testWidgets('renders all sections and binds setting values to switches',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => Stream.value(_row)),
        authRepositoryProvider.overrideWithValue(_FakeAuth()),
        ambientEnabledProvider.overrideWithValue(false),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pump(); // emit the stream value
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Version 0.1.0'), findsOneWidget);

    // Switches render in order: Sound effects, Music, Notifications, Haptics.
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.length, 4);
    expect(switches[0].value, isTrue); // sound effects
    expect(switches[2].value, isFalse); // notifications (false in _row)
  });
}
