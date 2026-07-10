// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PublicProfile _$PublicProfileFromJson(Map<String, dynamic> json) =>
    _PublicProfile(
      uid: json['uid'] as String,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String,
      avatarId: json['avatarId'] as String,
      isGuest: json['isGuest'] as bool? ?? false,
      highestLevel: (json['highestLevel'] as num?)?.toInt() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PublicProfileToJson(_PublicProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'handle': instance.handle,
      'displayName': instance.displayName,
      'avatarId': instance.avatarId,
      'isGuest': instance.isGuest,
      'highestLevel': instance.highestLevel,
      'totalScore': instance.totalScore,
    };
