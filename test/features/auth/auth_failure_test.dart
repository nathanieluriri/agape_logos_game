import 'package:agape_logos_game/features/auth/domain/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromCode maps known Firebase codes', () {
    expect(AuthFailure.fromCode('wrong-password'), AuthFailure.wrongPassword);
    expect(AuthFailure.fromCode('invalid-credential'), AuthFailure.wrongPassword);
    expect(AuthFailure.fromCode('user-not-found'), AuthFailure.userNotFound);
    expect(AuthFailure.fromCode('email-already-in-use'), AuthFailure.emailInUse);
    expect(AuthFailure.fromCode('weak-password'), AuthFailure.weakPassword);
    expect(AuthFailure.fromCode('invalid-email'), AuthFailure.invalidEmail);
    expect(AuthFailure.fromCode('network-request-failed'), AuthFailure.offline);
  });

  test('fromCode falls back to unknown', () {
    expect(AuthFailure.fromCode('something-else'), AuthFailure.unknown);
  });

  test('fromCode maps requires-recent-login', () {
    expect(AuthFailure.fromCode('requires-recent-login'),
        AuthFailure.requiresRecentLogin);
  });

  test('every failure has a non-empty message', () {
    for (final f in AuthFailure.values) {
      expect(f.message, isNotEmpty);
    }
  });
}
