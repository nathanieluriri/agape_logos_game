import 'package:freezed_annotation/freezed_annotation.dart';

import 'match.dart';

part 'match_result.freezed.dart';

/// The tier of the server's winner algorithm (`computeWinner` in
/// `functions/src/services/match_scoring.ts`) that actually decided a finished
/// match. Absent (null, see [deriveMatchWinReason]) on a genuine draw.
enum MatchWinReason { wordsFound, speed, points }

/// Mirrors `computeWinner`'s precedence order EXACTLY so the derived reason
/// never contradicts the server-written `winner`: most `wordsFound` wins
/// outright; only when that's tied does the faster `lastWordAt` (earlier
/// timestamp) decide; only when that's also tied does higher `score` decide;
/// otherwise every tier agreed and it's a genuine draw.
///
/// [outcome] is the already-resolved `win` / `loss` / `draw` this player saw
/// (server `winner`, or the client's provisional score-only fallback while a
/// match is still finalizing). If the tier this function derives would name a
/// different side as the winner than [outcome] says, that means the inputs
/// disagree (most likely the provisional fallback), so this returns null
/// rather than showing a reason that contradicts the headline.
MatchWinReason? deriveMatchWinReason({
  required String outcome,
  required int myWordsFound,
  required int opponentWordsFound,
  required int myLastWordAt,
  required int opponentLastWordAt,
  required int myScore,
  required int opponentScore,
}) {
  final MatchWinReason tierReason;
  final bool tierFavorsMe;
  if (myWordsFound != opponentWordsFound) {
    tierReason = MatchWinReason.wordsFound;
    tierFavorsMe = myWordsFound > opponentWordsFound;
  } else if (myLastWordAt > 0 &&
      opponentLastWordAt > 0 &&
      myLastWordAt != opponentLastWordAt) {
    tierReason = MatchWinReason.speed;
    tierFavorsMe = myLastWordAt < opponentLastWordAt;
  } else if (myScore != opponentScore) {
    tierReason = MatchWinReason.points;
    tierFavorsMe = myScore > opponentScore;
  } else {
    return null; // Every tier tied: a genuine draw.
  }

  final bool agreesWithOutcome = switch (outcome) {
    'win' => tierFavorsMe,
    'loss' => !tierFavorsMe,
    _ => false, // outcome says 'draw' but a tier still differs: don't contradict it.
  };
  return agreesWithOutcome ? tierReason : null;
}

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
    @Default(0) int myWordsFound,
    @Default(0) int opponentWordsFound,
    @Default(0) int myLastWordAt,
    @Default(0) int opponentLastWordAt,
  }) = _MatchResult;

  const MatchResult._();

  bool get isWin => outcome == 'win';
  bool get isDraw => outcome == 'draw';
  bool get isLoss => outcome == 'loss';

  /// Why the winning side won, or null on a genuine draw (or when the
  /// derivation can't be trusted to agree with [outcome]). See
  /// [deriveMatchWinReason].
  MatchWinReason? get winReason => deriveMatchWinReason(
        outcome: outcome,
        myWordsFound: myWordsFound,
        opponentWordsFound: opponentWordsFound,
        myLastWordAt: myLastWordAt,
        opponentLastWordAt: opponentLastWordAt,
        myScore: myScore,
        opponentScore: opponentScore,
      );

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
      myWordsFound: me?.wordsFound ?? 0,
      opponentWordsFound: opp?.wordsFound ?? 0,
      myLastWordAt: me?.lastWordAt ?? 0,
      opponentLastWordAt: opp?.lastWordAt ?? 0,
    );
  }
}
