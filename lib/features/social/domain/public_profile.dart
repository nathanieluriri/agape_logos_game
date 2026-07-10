import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_profile.freezed.dart';
part 'public_profile.g.dart';

/// The minimal public projection returned by `GET /users/search` and, with
/// stats filled in, by `GET /users/:uid/public`. Never carries private fields.
/// Stats default to 0 so search results (which omit them) deserialize cleanly.
@freezed
abstract class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String uid,
    required String handle,
    required String displayName,
    required String avatarId,
    @Default(false) bool isGuest,
    @Default(0) int highestLevel,
    @Default(0) int totalScore,
  }) = _PublicProfile;

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);
}
