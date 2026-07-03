// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get uid; String get displayName; String get avatarId; String get locale; bool get soundEnabled; bool get musicEnabled; int get highestLevel; int get totalScore;@JsonKey(defaultValue: 0) int get coins; int get createdAt; int get updatedAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.soundEnabled, soundEnabled) || other.soundEnabled == soundEnabled)&&(identical(other.musicEnabled, musicEnabled) || other.musicEnabled == musicEnabled)&&(identical(other.highestLevel, highestLevel) || other.highestLevel == highestLevel)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName,avatarId,locale,soundEnabled,musicEnabled,highestLevel,totalScore,coins,createdAt,updatedAt);

@override
String toString() {
  return 'Profile(uid: $uid, displayName: $displayName, avatarId: $avatarId, locale: $locale, soundEnabled: $soundEnabled, musicEnabled: $musicEnabled, highestLevel: $highestLevel, totalScore: $totalScore, coins: $coins, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String displayName, String avatarId, String locale, bool soundEnabled, bool musicEnabled, int highestLevel, int totalScore,@JsonKey(defaultValue: 0) int coins, int createdAt, int updatedAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? avatarId = null,Object? locale = null,Object? soundEnabled = null,Object? musicEnabled = null,Object? highestLevel = null,Object? totalScore = null,Object? coins = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,soundEnabled: null == soundEnabled ? _self.soundEnabled : soundEnabled // ignore: cast_nullable_to_non_nullable
as bool,musicEnabled: null == musicEnabled ? _self.musicEnabled : musicEnabled // ignore: cast_nullable_to_non_nullable
as bool,highestLevel: null == highestLevel ? _self.highestLevel : highestLevel // ignore: cast_nullable_to_non_nullable
as int,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String displayName,  String avatarId,  String locale,  bool soundEnabled,  bool musicEnabled,  int highestLevel,  int totalScore, @JsonKey(defaultValue: 0)  int coins,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.uid,_that.displayName,_that.avatarId,_that.locale,_that.soundEnabled,_that.musicEnabled,_that.highestLevel,_that.totalScore,_that.coins,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String displayName,  String avatarId,  String locale,  bool soundEnabled,  bool musicEnabled,  int highestLevel,  int totalScore, @JsonKey(defaultValue: 0)  int coins,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.uid,_that.displayName,_that.avatarId,_that.locale,_that.soundEnabled,_that.musicEnabled,_that.highestLevel,_that.totalScore,_that.coins,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String displayName,  String avatarId,  String locale,  bool soundEnabled,  bool musicEnabled,  int highestLevel,  int totalScore, @JsonKey(defaultValue: 0)  int coins,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.uid,_that.displayName,_that.avatarId,_that.locale,_that.soundEnabled,_that.musicEnabled,_that.highestLevel,_that.totalScore,_that.coins,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile implements Profile {
  const _Profile({required this.uid, required this.displayName, required this.avatarId, required this.locale, required this.soundEnabled, required this.musicEnabled, required this.highestLevel, required this.totalScore, @JsonKey(defaultValue: 0) required this.coins, required this.createdAt, required this.updatedAt});
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String uid;
@override final  String displayName;
@override final  String avatarId;
@override final  String locale;
@override final  bool soundEnabled;
@override final  bool musicEnabled;
@override final  int highestLevel;
@override final  int totalScore;
@override@JsonKey(defaultValue: 0) final  int coins;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.soundEnabled, soundEnabled) || other.soundEnabled == soundEnabled)&&(identical(other.musicEnabled, musicEnabled) || other.musicEnabled == musicEnabled)&&(identical(other.highestLevel, highestLevel) || other.highestLevel == highestLevel)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName,avatarId,locale,soundEnabled,musicEnabled,highestLevel,totalScore,coins,createdAt,updatedAt);

@override
String toString() {
  return 'Profile(uid: $uid, displayName: $displayName, avatarId: $avatarId, locale: $locale, soundEnabled: $soundEnabled, musicEnabled: $musicEnabled, highestLevel: $highestLevel, totalScore: $totalScore, coins: $coins, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String displayName, String avatarId, String locale, bool soundEnabled, bool musicEnabled, int highestLevel, int totalScore,@JsonKey(defaultValue: 0) int coins, int createdAt, int updatedAt
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? avatarId = null,Object? locale = null,Object? soundEnabled = null,Object? musicEnabled = null,Object? highestLevel = null,Object? totalScore = null,Object? coins = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Profile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,soundEnabled: null == soundEnabled ? _self.soundEnabled : soundEnabled // ignore: cast_nullable_to_non_nullable
as bool,musicEnabled: null == musicEnabled ? _self.musicEnabled : musicEnabled // ignore: cast_nullable_to_non_nullable
as bool,highestLevel: null == highestLevel ? _self.highestLevel : highestLevel // ignore: cast_nullable_to_non_nullable
as int,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
