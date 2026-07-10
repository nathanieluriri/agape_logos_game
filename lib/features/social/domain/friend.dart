import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';
part 'friend.g.dart';

/// An accepted friend, mirroring `users/{uid}/friends/{friendUid}` as returned
/// by `GET /friends`. `since` is epoch millis.
@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String uid,
    required String handle,
    required String displayName,
    required String avatarId,
    @Default(0) int since,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}
