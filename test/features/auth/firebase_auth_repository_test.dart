import 'dart:async';

import 'package:agape_logos_game/features/auth/data/firebase_auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_failure.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

void main() {
  late _MockFirebaseAuth auth;
  late FirebaseAuthRepository repo;

  setUp(() {
    auth = _MockFirebaseAuth();
    repo = FirebaseAuthRepository(auth: auth);
  });

  test('signInWithEmail maps FirebaseAuthException to AuthFailure', () async {
    when(() => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    expect(
      () => repo.signInWithEmail('a@b.com', 'secret'),
      throwsA(AuthFailure.wrongPassword),
    );
  });

  test('signInWithEmail succeeds when Firebase succeeds', () async {
    when(() => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _MockUserCredential());

    await repo.signInWithEmail('a@b.com', 'secret');
  });

  test('authStateChanges maps User to AuthUser', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => user.displayName).thenReturn('Ada');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<User?>.value(user));

    final emitted = await repo.authStateChanges().first;
    expect(
      emitted,
      const AuthUser(uid: 'u1', email: 'a@b.com', displayName: 'Ada'),
    );
  });

  test('authStateChanges maps null to null (signed out)', () async {
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<User?>.value(null));

    expect(await repo.authStateChanges().first, isNull);
  });

  test('idToken returns the current user token when signed in', () async {
    final user = _MockUser();
    when(() => user.getIdToken()).thenAnswer((_) async => 'tok123');
    when(() => auth.currentUser).thenReturn(user);

    expect(await repo.idToken(), 'tok123');
  });

  test('idToken returns null when signed out', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await repo.idToken(), isNull);
  });

  test('awaitRestoredUser returns the restored user on first emission', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn(null);
    when(() => user.displayName).thenReturn(null);
    when(() => user.photoURL).thenReturn(null);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<User?>.value(user));

    final restored = await repo.awaitRestoredUser();

    expect(restored?.uid, 'u1');
  });

  test('awaitRestoredUser returns null when first emission is signed out', () async {
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<User?>.value(null));

    expect(await repo.awaitRestoredUser(), isNull);
  });

  test('awaitRestoredUser returns null when no state arrives before the timeout',
      () async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);
    when(() => auth.authStateChanges()).thenAnswer((_) => controller.stream);

    final restored = await repo.awaitRestoredUser(
      timeout: const Duration(milliseconds: 50),
    );

    expect(restored, isNull);
  });

  test('signInAnonymously maps FirebaseAuthException to AuthFailure', () {
    when(() => auth.signInAnonymously())
        .thenThrow(FirebaseAuthException(code: 'operation-not-allowed'));
    expect(() => repo.signInAnonymously(), throwsA(AuthFailure.unknown));
  });
}
