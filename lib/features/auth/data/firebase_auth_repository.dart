import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'google/google_auth.dart';

/// AuthRepository backed by FirebaseAuth. Maps Firebase types to domain types
/// and FirebaseAuthException codes to AuthFailure.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<String?> idToken() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );

  @override
  Future<void> registerWithEmail(String email, String password) => _guard(
        () => _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );

  @override
  Future<void> signInWithGoogle() =>
      _guard(() => signInWithGoogleCredential(_auth));

  @override
  Future<void> signInAnonymously() =>
      _guard(() => _auth.signInAnonymously());

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() =>
      _guard(() async => _auth.currentUser?.delete());

  /// Awaits the first restored auth state, with a bounded timeout. Required in a
  /// fresh isolate where `currentUser` is null until Firebase finishes restoring
  /// the persisted user from disk. Returns the restored user, or null (signed
  /// out or timeout).
  Future<AuthUser?> awaitRestoredUser({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return authStateChanges().first.timeout(timeout, onTimeout: () => null);
  }

  AuthUser? _mapUser(User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          photoUrl: u.photoURL,
          isAnonymous: u.isAnonymous,
        );

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }
}
