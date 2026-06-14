// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LevelResult _$LevelResultFromJson(Map<String, dynamic> json) => _LevelResult(
  id: json['id'] as String,
  levelId: (json['levelId'] as num).toInt(),
  score: (json['score'] as num).toInt(),
  completedAt: (json['completedAt'] as num).toInt(),
  synced: json['synced'] as bool? ?? false,
);

Map<String, dynamic> _$LevelResultToJson(_LevelResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'levelId': instance.levelId,
      'score': instance.score,
      'completedAt': instance.completedAt,
      'synced': instance.synced,
    };
