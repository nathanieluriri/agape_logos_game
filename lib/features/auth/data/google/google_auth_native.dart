import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/auth_failure.dart';

bool _initialized = false;

/// Android Google sign-in via google_sign_in 7.x: run interactive auth, take the
/// Google ID token, and exchange it for a Firebase credential.
///
/// Requires the Android app's SHA-1/SHA-256 to be registered in the Firebase
/// console and a current google-services.json (so the ID token audience is the
/// project web client). A null idToken means that config is missing.
Future<void> signInWithGoogleCredential(FirebaseAuth auth) async {
  final GoogleSignIn signIn = GoogleSignIn.instance;
  if (!_initialized) {
    await signIn.initialize();
    _initialized = true;
  }

  final GoogleSignInAccount account;
  try {
    account = await signIn.authenticate();
  } on GoogleSignInException catch (e) {
    // User dismissed the picker: treat as a benign no-op, not an error.
    if (e.code == GoogleSignInExceptionCode.canceled) return;
    rethrow;
  }

  final String? idToken = account.authentication.idToken;
  if (idToken == null) throw AuthFailure.unknown;

  final OAuthCredential credential =
      GoogleAuthProvider.credential(idToken: idToken);
  await auth.signInWithCredential(credential);
}
