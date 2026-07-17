import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_result.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid, {bool ready = false, int score = 0}) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'avatar_01', isGuest: false,
      ready: ready, connected: true, score: score, wordsFound: 0,
    );

Match _match({
  String winner = '',
  Map<String, MatchPlayer>? players,
}) =>
    Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.finished,
      participants: const ['a', 'b'], playerOrder: const ['a', 'b'],
      createdBy: 'a', createdAt: 0, startedAt: 0, endsAt: 0,
      settings: MatchSettings.defaults(),
      players: players ?? {'a': _p('a', score: 30), 'b': _p('b', score: 10)},
      winner: winner.isEmpty ? null : winner,
    );

void main() {
  test('settings wire form uses the difficulty enum name', () {
    expect(
      const MatchSettings(
        difficulty: MatchDifficulty.hard, durationSec: 90, rackSize: 7,
        theme: null,
      ).toWire(),
      {
        'difficulty': 'hard',
        'durationSec': 90,
        'rackSize': 7,
        'theme': null,
        'mode': 'live',
      },
    );
  });

  test('opponentOf returns the other player; bothReady needs two readies', () {
    final m = _match(players: {'a': _p('a', ready: true), 'b': _p('b')});
    expect(m.opponentOf('a')?.uid, 'b');
    expect(m.bothReady, isFalse);
  });

  test('event kind round-trips through the wire strings', () {
    expect(matchEventKindFromWire('word_steal'), MatchEventKind.wordSteal);
    expect(matchEventKindToWire(MatchEventKind.fogBank), 'fog_bank');
    expect(matchEventKindFromWire('nope'), MatchEventKind.unknown);
  });

  test('result: server winner wins; null winner falls back to scores', () {
    expect(MatchResult.fromFinishedMatch(_match(winner: 'b'), 'a').isLoss, isTrue);
    expect(MatchResult.fromFinishedMatch(_match(winner: 'draw'), 'a').isDraw, isTrue);
    expect(MatchResult.fromFinishedMatch(_match(), 'a').isWin, isTrue); // 30 > 10
  });
}
