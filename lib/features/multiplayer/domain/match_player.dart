import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_player.freezed.dart';

/// One participant's live state inside the match doc (contract 8.2 `players`).
@freezed
abstract class MatchPlayer with _$MatchPlayer {
  const factory MatchPlayer({
    required String uid,
    required String displayName,
    required String avatarId,
    required bool isGuest,
    required bool ready,
    required bool connected,
    required int score,
    required int wordsFound,
    @Default(0) int endsAtBonusMs,
    @Default(0) int lastWordAt,
    @Default(0) int finishedAt,
    @Default(0) int lastSeen,
  }) = _MatchPlayer;
}
