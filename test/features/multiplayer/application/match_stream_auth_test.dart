import 'dart:async';

import 'package:agape_logos_game/core/firebase/firestore_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_firestore.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {}

Match _lobby() => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.lobby,
      participants: const ['me'], playerOrder: const ['me'], createdBy: 'me',
      createdAt: 0, startedAt: 0, endsAt: 0, settings: MatchSettings.defaults(),
      players: {
        'me': const MatchPlayer(
          uid: 'me', displayName: 'me', avatarId: 'a', isGuest: false,
          ready: false, connected: true, score: 0, wordsFound: 0,
        ),
      },
      winner: null,
    );

/// Records every match-doc listener attach, so a test can assert we never open
/// one while unauthenticated (Firestore rules would reject it: permission-denied).
class _RecordingMatchFirestore extends MatchFirestore {
  _RecordingMatchFirestore()
      : super(_FakeFirestore(), answerKey: () async => null);

  final List<String> watched = <String>[];

  @override
  Stream<Match?> watchMatch(String matchId) {
    watched.add(matchId);
    return Stream<Match?>.value(_lobby());
  }
}

void main() {
  test('match stream waits for auth to restore before listening', () async {
    // Mirrors a web page refresh: Firebase restores the persisted user
    // asynchronously, so auth is *loading* (not signed out) for the first frames.
    final auth = StreamController<AuthUser?>();
    addTearDown(auth.close);
    final db = _RecordingMatchFirestore();

    final container = ProviderContainer(overrides: [
      firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
      matchFirestoreProvider.overrideWithValue(db),
      authStateProvider.overrideWith((ref) => auth.stream),
    ]);
    addTearDown(container.dispose);

    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    // While auth is still restoring we must NOT attach a listener: the rules
    // reject it and the stream would die permanently on permission-denied.
    expect(db.watched, isEmpty,
        reason: 'attached a match listener before auth restored');
    expect(container.read(matchStreamProvider('m1')).isLoading, isTrue);

    // Auth restores -> now the listener attaches and the match arrives.
    auth.add(const AuthUser(uid: 'me'));
    await container.pump();
    await Future<void>.delayed(Duration.zero);

    expect(db.watched, <String>['m1']);
    expect(container.read(matchStreamProvider('m1')).value?.code, 'ABCD');
  });
}
