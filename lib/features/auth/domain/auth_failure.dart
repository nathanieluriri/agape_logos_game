/// Domain-level auth error, mapped from `FirebaseAuthException.code` so the UI
/// never depends on Firebase types directly.
enum AuthFailure {
  wrongPassword,
  userNotFound,
  emailInUse,
  weakPassword,
  invalidEmail,
  offline,
  requiresRecentLogin,
  unknown;

  static AuthFailure fromCode(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.wrongPassword;
      case 'user-not-found':
        return AuthFailure.userNotFound;
      case 'email-already-in-use':
        return AuthFailure.emailInUse;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'network-request-failed':
        return AuthFailure.offline;
      case 'requires-recent-login':
        return AuthFailure.requiresRecentLogin;
      default:
        return AuthFailure.unknown;
    }
  }

  String get message {
    switch (this) {
      case AuthFailure.wrongPassword:
        return 'Incorrect email or password.';
      case AuthFailure.userNotFound:
        return 'No account found for that email.';
      case AuthFailure.emailInUse:
        return 'That email is already registered.';
      case AuthFailure.weakPassword:
        return 'Please choose a stronger password.';
      case AuthFailure.invalidEmail:
        return 'That email address looks invalid.';
      case AuthFailure.offline:
        return "You're offline. Connect and try again.";
      case AuthFailure.requiresRecentLogin:
        return 'Please sign in again to confirm this change.';
      case AuthFailure.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
