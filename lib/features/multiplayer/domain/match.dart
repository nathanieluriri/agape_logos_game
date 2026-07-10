import 'package:freezed_annotation/freezed_annotation.dart';

import 'match_player.dart';
import 'match_settings.dart';

part 'match.freezed.dart';

enum MatchStatus { lobby, countdown, active, finished, cancelled }

MatchStatus matchStatusFromWire(String? raw) {
  switch (raw) {
    case 'countdown':
      return MatchStatus.countdown;
    case 'active':
      return MatchStatus.active;
    case 'finished':
      return MatchStatus.finished;
    case 'cancelled':
      return MatchStatus.cancelled;
    default:
      return MatchStatus.lobby;
  }
}

/// The shared, participant-scoped match document (contract 8.2). Read-only on
/// the client (rules forbid client writes); every change comes from a Cloud
/// Function via the Firestore listener.
@freezed
abstract class Match with _$Match {
  const factory Match({
    required String matchId,
    required String code,
    required MatchStatus status,
    required List<String> participants,
    required List<String> playerOrder,
    required String createdBy,
    required int createdAt,
    required int startedAt,
    required int endsAt,
    required MatchSettings settings,
    required Map<String, MatchPlayer> players,
    String? winner,
  }) = _Match;

  const Match._();

  MatchPlayer? playerFor(String uid) => players[uid];

  /// The other participant (v1 is 1v1, so the first player whose uid is not
  /// [uid]); null while the lobby is still waiting for an opponent.
  MatchPlayer? opponentOf(String uid) {
    for (final entry in players.entries) {
      if (entry.key != uid) return entry.value;
    }
    return null;
  }

  bool isCreator(String uid) => createdBy == uid;

  bool get hasOpponent => players.length >= 2;

  bool get bothReady =>
      players.length == 2 && players.values.every((p) => p.ready);
}
