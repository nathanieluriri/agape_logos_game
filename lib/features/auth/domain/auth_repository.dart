import 'auth_user.dart';

/// Auth boundary. Implementations throw `AuthFailure` on action failures.
abstract interface class AuthRepository {
  /// Emits the current user (or null when signed out) and on every change.
  Stream<AuthUser?> authStateChanges();

  /// The currently cached user, or null when signed out.
  AuthUser? get currentUser;

  /// The current user's Firebase ID token (auto-refreshed when expired), or
  /// null when signed out. Used by the network layer to authenticate sync
  /// requests without exposing Firebase types outside the auth feature.
  Future<String?> idToken();

  Future<void> signInWithEmail(String email, String password);

  Future<void> registerWithEmail(String email, String password);

  Future<void> signInWithGoogle();

  /// Signs in as an anonymous guest. The resulting user has a real uid that can
  /// later be linked to Google or email. Throws `AuthFailure` on failure.
  Future<void> signInAnonymously();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
