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
    // Social layer (plan 13). Defaulted so a response from an older backend and
    // the Drift-cached path (which does not store these) both deserialize; the
    // server response (`GET /me`) fills them in. `public` drives the settings
    // toggle; `handle` is the searchable @handle; `isGuest` flags anonymous.
    // PLAN: profileToCompanion / profileFromRow need NO change (the cached path
    // reports the defaults offline); this avoids a Drift schema migration. The
    // privacy toggle reads the authoritative `public` from a fresh GET /me.
    @Default('') String handle,
    @Default(false) bool public,
    @Default(false) bool isGuest,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
