import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// The signed-in user's server profile, as returned by `GET /me`. Timestamps
/// are epoch millis. Mirrors the backend `ProfileResponseSchema`.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String uid,
    required String displayName,
    required String avatarId,
    required String locale,
    required bool soundEnabled,
    required bool musicEnabled,
    required int highestLevel,
    required int totalScore,
    // Defaulted so a response from an older backend without the field still
    // deserializes (the wallet just reads 0 until the next fetch).
    @JsonKey(defaultValue: 0) required int coins,
    required int createdAt,
    required int updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
