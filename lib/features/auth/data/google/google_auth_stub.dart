import 'package:firebase_auth/firebase_auth.dart';

/// Fallback for unsupported platforms (never reached on Android/web).
Future<void> signInWithGoogleCredential(FirebaseAuth auth) async {
  throw UnsupportedError('Google sign-in is not supported on this platform.');
}
