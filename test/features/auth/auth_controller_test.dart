import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_failure.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

  final AuthFailure? failure;

  bool guestCalled = false;

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
  Future<void> signInAnonymously() async {
    guestCalled = true;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {
    if (failure != null) throw failure!;
  }

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

  test('signInWithGuest calls the repository and sets AsyncData on success', () async {
    final repo = _FakeAuthRepository();
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithGuest();

    expect(repo.guestCalled, isTrue);
    expect(c.read(authControllerProvider).hasError, isFalse);
  });

  test('signInWithGuest surfaces AuthFailure as AsyncError', () async {
    final c = containerWith(AuthFailure.unknown);
    await c.read(authControllerProvider.notifier).signInWithGuest();
    expect(c.read(authControllerProvider).error, AuthFailure.unknown);
  });

  test('deleteAccount clears local data on success', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.levelResultsDao.upsert(LevelResultsCompanion.insert(
        id: 'x', levelId: 1, score: 0, completedAt: 1));
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).deleteAccount();

    expect(c.read(authControllerProvider).hasError, isFalse);
    expect(await db.levelResultsDao.watchAll().first, isEmpty);
  });

  test('deleteAccount surfaces requiresRecentLogin and keeps data', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.levelResultsDao.upsert(LevelResultsCompanion.insert(
        id: 'x', levelId: 1, score: 0, completedAt: 1));
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(failure: AuthFailure.requiresRecentLogin)),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).deleteAccount();

    expect(c.read(authControllerProvider).error,
        AuthFailure.requiresRecentLogin);
    expect(await db.levelResultsDao.watchAll().first, isNotEmpty);
  });
}
