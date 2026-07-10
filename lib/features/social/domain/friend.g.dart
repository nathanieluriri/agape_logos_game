// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Friend _$FriendFromJson(Map<String, dynamic> json) => _Friend(
  uid: json['uid'] as String,
  handle: json['handle'] as String,
  displayName: json['displayName'] as String,
  avatarId: json['avatarId'] as String,
  since: (json['since'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FriendToJson(_Friend instance) => <String, dynamic>{
  'uid': instance.uid,
  'handle': instance.handle,
  'displayName': instance.displayName,
  'avatarId': instance.avatarId,
  'since': instance.since,
};
