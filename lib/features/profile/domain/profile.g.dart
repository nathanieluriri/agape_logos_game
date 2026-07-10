// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String,
  avatarId: json['avatarId'] as String,
  locale: json['locale'] as String,
  soundEnabled: json['soundEnabled'] as bool,
  musicEnabled: json['musicEnabled'] as bool,
  highestLevel: (json['highestLevel'] as num).toInt(),
  totalScore: (json['totalScore'] as num).toInt(),
  coins: (json['coins'] as num?)?.toInt() ?? 0,
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
  handle: json['handle'] as String? ?? '',
  public: json['public'] as bool? ?? false,
  isGuest: json['isGuest'] as bool? ?? false,
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'uid': instance.uid,
  'displayName': instance.displayName,
  'avatarId': instance.avatarId,
  'locale': instance.locale,
  'soundEnabled': instance.soundEnabled,
  'musicEnabled': instance.musicEnabled,
  'highestLevel': instance.highestLevel,
  'totalScore': instance.totalScore,
  'coins': instance.coins,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'handle': instance.handle,
  'public': instance.public,
  'isGuest': instance.isGuest,
};
