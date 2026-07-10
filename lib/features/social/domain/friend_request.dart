import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request.freezed.dart';
part 'friend_request.g.dart';

/// An incoming pending friend request, mirroring
/// `users/{uid}/friendRequests/{fromUid}`. `at` is epoch millis.
@freezed
abstract class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    required String fromUid,
    required String handle,
    required String displayName,
    required String avatarId,
    @Default(0) int at,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);
}
