import 'package:firebase_auth/firebase_auth.dart';

/// Web Google sign-in: Firebase popup. google_sign_in has no interactive
/// authenticate() on web, so Firebase drives the OAuth popup directly.
Future<void> signInWithGoogleCredential(FirebaseAuth auth) async {
  await auth.signInWithPopup(GoogleAuthProvider());
}
