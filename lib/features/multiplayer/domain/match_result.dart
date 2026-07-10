import 'package:freezed_annotation/freezed_annotation.dart';

import 'match.dart';

part 'match_result.freezed.dart';

/// The finished-match outcome from the current player's point of view. Derived
/// from a finished [Match]; the server sets `winner` authoritatively.
@freezed
abstract class MatchResult with _$MatchResult {
  const factory MatchResult({
    required String matchId,
    required String outcome, // 'win' | 'loss' | 'draw'
    required int myScore,
    required int opponentScore,
    required String opponentName,
  }) = _MatchResult;

  const MatchResult._();

  bool get isWin => outcome == 'win';
  bool get isDraw => outcome == 'draw';
  bool get isLoss => outcome == 'loss';

  factory MatchResult.fromFinishedMatch(Match match, String myUid) {
    final me = match.playerFor(myUid);
    final opp = match.opponentOf(myUid);
    final myScore = me?.score ?? 0;
    final oppScore = opp?.score ?? 0;
    final String outcome;
    if (match.winner == 'draw') {
      outcome = 'draw';
    } else if (match.winner == myUid) {
      outcome = 'win';
    } else if (match.winner == null) {
      // Not finalized yet: fall back to a score comparison so the UI is never
      // blank. The server value supersedes this on the next listener tick.
      outcome = myScore == oppScore
          ? 'draw'
          : (myScore > oppScore ? 'win' : 'loss');
    } else {
      outcome = 'loss';
    }
    return MatchResult(
      matchId: match.matchId,
      outcome: outcome,
      myScore: myScore,
      opponentScore: oppScore,
      opponentName: opp?.displayName ?? 'Opponent',
    );
  }
}
