import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

/// Reactive auth state; null value means signed out.
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Convenience snapshot of the current user (null while loading or signed out).
final currentUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authStateProvider).asData?.value,
);

/// Drives auth actions and exposes loading/error to the UI. The error carried by
/// AsyncError is an `AuthFailure` (see FirebaseAuthRepository).
class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }

  Future<void> signInWithEmail(String email, String password) =>
      _run(() => ref.read(authRepositoryProvider).signInWithEmail(email, password));

  Future<void> registerWithEmail(String email, String password) =>
      _run(() => ref.read(authRepositoryProvider).registerWithEmail(email, password));

  Future<void> signInWithGoogle() =>
      _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<void> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<void> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
