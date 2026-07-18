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

  group('deriveMatchWinReason mirrors computeWinner\'s tier order', () {
    test('won by words found: equal score, unequal words', () {
      final reason = deriveMatchWinReason(
        outcome: 'win',
        myWordsFound: 6,
        opponentWordsFound: 4,
        myLastWordAt: 0,
        opponentLastWordAt: 0,
        myScore: 20,
        opponentScore: 20,
      );
      expect(reason, MatchWinReason.wordsFound);
    });

    test('won by speed: equal words and score, faster time wins', () {
      final reason = deriveMatchWinReason(
        outcome: 'win',
        myWordsFound: 5,
        opponentWordsFound: 5,
        myLastWordAt: 1000,
        opponentLastWordAt: 2000,
        myScore: 20,
        opponentScore: 20,
      );
      expect(reason, MatchWinReason.speed);
    });

    test('won by points: words and time both tied, score decides', () {
      final reason = deriveMatchWinReason(
        outcome: 'win',
        myWordsFound: 5,
        opponentWordsFound: 5,
        myLastWordAt: 1500,
        opponentLastWordAt: 1500,
        myScore: 22,
        opponentScore: 18,
      );
      expect(reason, MatchWinReason.points);
    });

    test('genuine draw: every tier tied returns null', () {
      final reason = deriveMatchWinReason(
        outcome: 'draw',
        myWordsFound: 5,
        opponentWordsFound: 5,
        myLastWordAt: 1500,
        opponentLastWordAt: 1500,
        myScore: 20,
        opponentScore: 20,
      );
      expect(reason, isNull);
    });

    test('wordsFound decides outright even when a later tier would disagree', () {
      // wa != wb settles it in tier 1; the (tied) score never gets consulted.
      final reason = deriveMatchWinReason(
        outcome: 'loss',
        myWordsFound: 3,
        opponentWordsFound: 5,
        myLastWordAt: 500,
        opponentLastWordAt: 9000,
        myScore: 20,
        opponentScore: 20,
      );
      expect(reason, MatchWinReason.wordsFound);
    });

    test('a zero lastWordAt (never found a word) skips the speed tier', () {
      final reason = deriveMatchWinReason(
        outcome: 'win',
        myWordsFound: 5,
        opponentWordsFound: 5,
        myLastWordAt: 1200,
        opponentLastWordAt: 0,
        myScore: 25,
        opponentScore: 20,
      );
      expect(reason, MatchWinReason.points);
    });

    test('disagreement with outcome is never shown (defensive guard)', () {
      // Provisional score-only outcome says 'loss', but words favor me: the
      // derivation must not contradict the outcome the headline already shows.
      final reason = deriveMatchWinReason(
        outcome: 'loss',
        myWordsFound: 6,
        opponentWordsFound: 4,
        myLastWordAt: 0,
        opponentLastWordAt: 0,
        myScore: 10,
        opponentScore: 20,
      );
      expect(reason, isNull);
    });
  });
}
