import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_failure.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

  final AuthFailure? failure;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> registerWithEmail(String email, String password) async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<String?> idToken() async => null;
}

void main() {
  ProviderContainer containerWith(AuthFailure? failure) {
    final c = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(_FakeAuthRepository(failure: failure)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('signInWithEmail sets AsyncData on success', () async {
    final c = containerWith(null);
    await c.read(authControllerProvider.notifier)
        .signInWithEmail('a@b.com', 'secret');
    expect(c.read(authControllerProvider).hasError, isFalse);
  });

  test('signInWithEmail surfaces AuthFailure as AsyncError', () async {
    final c = containerWith(AuthFailure.wrongPassword);
    await c.read(authControllerProvider.notifier)
        .signInWithEmail('a@b.com', 'bad');
    final state = c.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, AuthFailure.wrongPassword);
  });
}
