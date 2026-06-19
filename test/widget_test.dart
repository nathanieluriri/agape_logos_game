import 'package:agape_logos_game/app/app.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/home/presentation/widgets/home_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);
  @override
  AuthUser? get currentUser => null;
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

void main() {
  testWidgets('app boots to the home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          homeAmbientEnabledProvider.overrideWithValue(false),
        ],
        child: const AgapeApp(),
      ),
    );
    // Do NOT pumpAndSettle: the home runs continuous animations.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ZEN WORD'), findsOneWidget);
  });
}
