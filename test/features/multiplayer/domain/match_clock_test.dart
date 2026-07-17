import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:flutter_test/flutter_test.dart';

Match _match({
  required MatchStatus status,
  required int startedAt,
  required int endsAt,
}) =>
    Match(
      matchId: 'm1', code: 'ABCD', status: status,
      participants: const ['me', 'you'], playerOrder: const ['me', 'you'],
      createdBy: 'me', createdAt: 0, startedAt: startedAt, endsAt: endsAt,
      settings: MatchSettings.defaults(),
      players: {
        'me': const MatchPlayer(
          uid: 'me', displayName: 'me', avatarId: 'a', isGuest: false,
          ready: true, connected: true, score: 0, wordsFound: 0,
        ),
      },
      winner: null,
    );

void main() {
  // The deadlock: `start` parks the doc in countdown with startedAt a few seconds
  // out, and the server only flips it to active inside settleMatch, which runs on
  // a submit/powerup. Gating the board on status == active meant the board never
  // opened, so nobody could submit, so the status never advanced: stuck on
  // "Get ready..." forever.
  test('a countdown match is playable once startedAt has passed', () {
    final m = _match(status: MatchStatus.countdown, startedAt: 1000, endsAt: 9000);

    expect(m.countingDownAt(500), isTrue);
    expect(m.playableAt(500), isFalse);

    expect(m.countingDownAt(1000), isFalse);
    expect(m.playableAt(1000), isTrue, reason: 'board must open at startedAt');
    expect(m.playableAt(5000), isTrue);
  });

  test('an active match stops being playable at endsAt', () {
    final m = _match(status: MatchStatus.active, startedAt: 1000, endsAt: 9000);
    expect(m.playableAt(8999), isTrue);
    expect(m.playableAt(9000), isFalse);
  });

  test('the countdown counts whole seconds down to the start', () {
    final m = _match(status: MatchStatus.countdown, startedAt: 3000, endsAt: 9000);
    expect(m.countdownSecondsAt(0), 3);
    expect(m.countdownSecondsAt(2200), 1);
    expect(m.countdownSecondsAt(3000), 0);
    expect(m.countdownSecondsAt(4000), 0);
  });

  test('a lobby match is never playable', () {
    final m = _match(status: MatchStatus.lobby, startedAt: 0, endsAt: 0);
    expect(m.playableAt(5000), isFalse);
    expect(m.countingDownAt(5000), isFalse);
  });
}
