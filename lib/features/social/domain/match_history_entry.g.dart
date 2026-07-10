// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchHistoryEntry _$MatchHistoryEntryFromJson(Map<String, dynamic> json) =>
    _MatchHistoryEntry(
      matchId: json['matchId'] as String,
      opponentUid: json['opponentUid'] as String,
      opponentName: json['opponentName'] as String,
      result: json['result'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      endedAt: (json['endedAt'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MatchHistoryEntryToJson(_MatchHistoryEntry instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'opponentUid': instance.opponentUid,
      'opponentName': instance.opponentName,
      'result': instance.result,
      'score': instance.score,
      'opponentScore': instance.opponentScore,
      'endedAt': instance.endedAt,
    };
