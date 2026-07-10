import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_history_entry.freezed.dart';
part 'match_history_entry.g.dart';

/// One row of `GET /me/matches` (or a public profile's recent matches).
/// `result` is "win" | "loss" | "draw"; `endedAt` is epoch millis.
@freezed
abstract class MatchHistoryEntry with _$MatchHistoryEntry {
  const factory MatchHistoryEntry({
    required String matchId,
    required String opponentUid,
    required String opponentName,
    required String result,
    @Default(0) int score,
    @Default(0) int opponentScore,
    @Default(0) int endedAt,
  }) = _MatchHistoryEntry;

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$MatchHistoryEntryFromJson(json);
}
