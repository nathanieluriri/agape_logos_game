import 'auth_user.dart';

/// Auth boundary. Implementations throw `AuthFailure` on action failures.
abstract interface class AuthRepository {
  /// Emits the current user (or null when signed out) and on every change.
  Stream<AuthUser?> authStateChanges();

  /// The currently cached user, or null when signed out.
  AuthUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  Future<void> registerWithEmail(String email, String password);

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
