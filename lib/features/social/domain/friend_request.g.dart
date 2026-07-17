// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    _FriendRequest(
      fromUid: json['fromUid'] as String,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String,
      avatarId: json['avatarId'] as String,
      at: (json['at'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FriendRequestToJson(_FriendRequest instance) =>
    <String, dynamic>{
      'fromUid': instance.fromUid,
      'handle': instance.handle,
      'displayName': instance.displayName,
      'avatarId': instance.avatarId,
      'at': instance.at,
    };
