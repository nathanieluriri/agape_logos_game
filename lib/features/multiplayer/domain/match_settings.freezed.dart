// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchSettings {

 MatchDifficulty get difficulty; int get durationSec; int get rackSize; String? get theme; MatchMode get mode;
/// Create a copy of MatchSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchSettingsCopyWith<MatchSettings> get copyWith => _$MatchSettingsCopyWithImpl<MatchSettings>(this as MatchSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchSettings&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,difficulty,durationSec,rackSize,theme,mode);

@override
String toString() {
  return 'MatchSettings(difficulty: $difficulty, durationSec: $durationSec, rackSize: $rackSize, theme: $theme, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $MatchSettingsCopyWith<$Res>  {
  factory $MatchSettingsCopyWith(MatchSettings value, $Res Function(MatchSettings) _then) = _$MatchSettingsCopyWithImpl;
@useResult
$Res call({
 MatchDifficulty difficulty, int durationSec, int rackSize, String? theme, MatchMode mode
});




}
/// @nodoc
class _$MatchSettingsCopyWithImpl<$Res>
    implements $MatchSettingsCopyWith<$Res> {
  _$MatchSettingsCopyWithImpl(this._self, this._then);

  final MatchSettings _self;
  final $Res Function(MatchSettings) _then;

/// Create a copy of MatchSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? difficulty = null,Object? durationSec = null,Object? rackSize = null,Object? theme = freezed,Object? mode = null,}) {
  return _then(_self.copyWith(
difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as MatchDifficulty,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchSettings].
extension MatchSettingsPatterns on MatchSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchSettings value)  $default,){
final _that = this;
switch (_that) {
case _MatchSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchSettings value)?  $default,){
final _that = this;
switch (_that) {
case _MatchSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MatchDifficulty difficulty,  int durationSec,  int rackSize,  String? theme,  MatchMode mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchSettings() when $default != null:
return $default(_that.difficulty,_that.durationSec,_that.rackSize,_that.theme,_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MatchDifficulty difficulty,  int durationSec,  int rackSize,  String? theme,  MatchMode mode)  $default,) {final _that = this;
switch (_that) {
case _MatchSettings():
return $default(_that.difficulty,_that.durationSec,_that.rackSize,_that.theme,_that.mode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MatchDifficulty difficulty,  int durationSec,  int rackSize,  String? theme,  MatchMode mode)?  $default,) {final _that = this;
switch (_that) {
case _MatchSettings() when $default != null:
return $default(_that.difficulty,_that.durationSec,_that.rackSize,_that.theme,_that.mode);case _:
  return null;

}
}

}

/// @nodoc


class _MatchSettings extends MatchSettings {
  const _MatchSettings({required this.difficulty, required this.durationSec, required this.rackSize, this.theme, this.mode = MatchMode.live}): super._();
  

@override final  MatchDifficulty difficulty;
@override final  int durationSec;
@override final  int rackSize;
@override final  String? theme;
@override@JsonKey() final  MatchMode mode;

/// Create a copy of MatchSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchSettingsCopyWith<_MatchSettings> get copyWith => __$MatchSettingsCopyWithImpl<_MatchSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchSettings&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,difficulty,durationSec,rackSize,theme,mode);

@override
String toString() {
  return 'MatchSettings(difficulty: $difficulty, durationSec: $durationSec, rackSize: $rackSize, theme: $theme, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$MatchSettingsCopyWith<$Res> implements $MatchSettingsCopyWith<$Res> {
  factory _$MatchSettingsCopyWith(_MatchSettings value, $Res Function(_MatchSettings) _then) = __$MatchSettingsCopyWithImpl;
@override @useResult
$Res call({
 MatchDifficulty difficulty, int durationSec, int rackSize, String? theme, MatchMode mode
});




}
/// @nodoc
class __$MatchSettingsCopyWithImpl<$Res>
    implements _$MatchSettingsCopyWith<$Res> {
  __$MatchSettingsCopyWithImpl(this._self, this._then);

  final _MatchSettings _self;
  final $Res Function(_MatchSettings) _then;

/// Create a copy of MatchSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? difficulty = null,Object? durationSec = null,Object? rackSize = null,Object? theme = freezed,Object? mode = null,}) {
  return _then(_MatchSettings(
difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as MatchDifficulty,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MatchMode,
  ));
}


}

// dart format on
