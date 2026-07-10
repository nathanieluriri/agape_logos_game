import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchEvent _e(MatchEventKind kind, int expiresAt, {int? letterIndex}) => MatchEvent(
      id: 'x$kind$expiresAt', at: 1, byUid: 'b', targetUid: 'me', kind: kind,
      payload: {if (letterIndex != null) 'letterIndex': letterIndex},
      expiresAt: expiresAt,
    );

void main() {
  test('projects live freeze indices + fog expiry, drops lapsed events', () async {
    final future = DateTime.now().millisecondsSinceEpoch + 60000;
    final c = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
      matchEventsStreamProvider('m1').overrideWith((ref) => Stream.value([
            _e(MatchEventKind.letterFreeze, future, letterIndex: 2),
            _e(MatchEventKind.fogBank, future),
            _e(MatchEventKind.letterFreeze, 1, letterIndex: 3), // lapsed
          ])),
    ]);
    addTearDown(c.dispose);
    // A StreamProvider's `.future` only resolves while something is listening
    // (see test/features/puzzles/puzzle_providers_test.dart).
    final sub = c.listen(matchEventsStreamProvider('m1'), (_, __) {});
    await c.read(matchEventsStreamProvider('m1').future);
    sub.close();
    final fx = c.read(activeEffectsProvider('m1'));
    expect(fx.frozenLetters.keys, contains(2));
    expect(fx.frozenLetters.containsKey(3), isFalse);
    expect(fx.hasFog, isTrue);
  });
}
