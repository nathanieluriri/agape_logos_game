import 'package:agape_logos_game/features/multiplayer/data/match_mappers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matchFromSnapshot maps status, settings, and the players map', () {
    final m = matchFromSnapshot('m1', {
      'code': 'ABCD',
      'status': 'active',
      'participants': ['a', 'b'],
      'playerOrder': ['a', 'b'],
      'createdBy': 'a',
      'createdAt': 1,
      'startedAt': 2,
      'endsAt': 3,
      'settings': {'difficulty': 'hard', 'durationSec': 90, 'rackSize': 7, 'theme': null},
      'players': {
        'a': {'uid': 'a', 'displayName': 'Grace', 'score': 12, 'ready': true},
        'b': {'uid': 'b', 'displayName': 'Guest', 'isGuest': true},
      },
      'winner': null,
    });
    expect(m.status, MatchStatus.active);
    expect(m.settings.durationSec, 90);
    expect(m.playerFor('a')!.score, 12);
    expect(m.opponentOf('a')!.displayName, 'Guest');
    expect(m.opponentOf('a')!.isGuest, isTrue);
  });

  test('matchRackFromSnapshot parks the enc token; not decrypted yet', () {
    final rack = matchRackFromSnapshot('a', {
      'uid': 'a', 'letters': ['A', 'E', 'R', 'T'], 'letterKey': 'AERT',
      'rackSize': 4,
      'answers': [
        {'length': 4, 'enc': 'aVeryLongBase64Token=='},
      ],
      'answerCount': 1, 'foundWords': ['TEAR'],
    });
    expect(rack.answers.single.length, 4);
    expect(rack.decrypted, isFalse); // token length != 4
    expect(rack.foundWords, ['TEAR']);
  });

  test('matchEventFromSnapshot reads kind + typed payload getters', () {
    final freeze = matchEventFromSnapshot('e1', {
      'byUid': 'b', 'targetUid': 'a', 'kind': 'letter_freeze',
      'payload': {'letterIndex': 2}, 'expiresAt': 999, 'at': 1,
    });
    expect(freeze.kind, MatchEventKind.letterFreeze);
    expect(freeze.letterIndex, 2);
    final steal = matchEventFromSnapshot('e2', {
      'kind': 'word_steal', 'targetUid': 'a',
      'payload': {'word': 'RATE', 'points': 8}, 'expiresAt': 0, 'at': 2,
    });
    expect(steal.stolenWord, 'RATE');
    expect(steal.stolenPoints, 8);
  });
}
