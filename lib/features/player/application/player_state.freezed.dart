// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerState {

 int get coins; int get currentLevel; int get progressDone; int get progressTotal; int get lastCompletedLevel;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.progressDone, progressDone) || other.progressDone == progressDone)&&(identical(other.progressTotal, progressTotal) || other.progressTotal == progressTotal)&&(identical(other.lastCompletedLevel, lastCompletedLevel) || other.lastCompletedLevel == lastCompletedLevel));
}


@override
int get hashCode => Object.hash(runtimeType,coins,currentLevel,progressDone,progressTotal,lastCompletedLevel);

@override
String toString() {
  return 'PlayerState(coins: $coins, currentLevel: $currentLevel, progressDone: $progressDone, progressTotal: $progressTotal, lastCompletedLevel: $lastCompletedLevel)';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 int coins, int currentLevel, int progressDone, int progressTotal, int lastCompletedLevel
});




}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coins = null,Object? currentLevel = null,Object? progressDone = null,Object? progressTotal = null,Object? lastCompletedLevel = null,}) {
  return _then(_self.copyWith(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as int,progressDone: null == progressDone ? _self.progressDone : progressDone // ignore: cast_nullable_to_non_nullable
as int,progressTotal: null == progressTotal ? _self.progressTotal : progressTotal // ignore: cast_nullable_to_non_nullable
as int,lastCompletedLevel: null == lastCompletedLevel ? _self.lastCompletedLevel : lastCompletedLevel // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int coins,  int currentLevel,  int progressDone,  int progressTotal,  int lastCompletedLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.coins,_that.currentLevel,_that.progressDone,_that.progressTotal,_that.lastCompletedLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int coins,  int currentLevel,  int progressDone,  int progressTotal,  int lastCompletedLevel)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.coins,_that.currentLevel,_that.progressDone,_that.progressTotal,_that.lastCompletedLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int coins,  int currentLevel,  int progressDone,  int progressTotal,  int lastCompletedLevel)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.coins,_that.currentLevel,_that.progressDone,_that.progressTotal,_that.lastCompletedLevel);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerState extends PlayerState {
  const _PlayerState({required this.coins, required this.currentLevel, required this.progressDone, required this.progressTotal, required this.lastCompletedLevel}): super._();
  

@override final  int coins;
@override final  int currentLevel;
@override final  int progressDone;
@override final  int progressTotal;
@override final  int lastCompletedLevel;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.coins, coins) || other.coins == coins)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.progressDone, progressDone) || other.progressDone == progressDone)&&(identical(other.progressTotal, progressTotal) || other.progressTotal == progressTotal)&&(identical(other.lastCompletedLevel, lastCompletedLevel) || other.lastCompletedLevel == lastCompletedLevel));
}


@override
int get hashCode => Object.hash(runtimeType,coins,currentLevel,progressDone,progressTotal,lastCompletedLevel);

@override
String toString() {
  return 'PlayerState(coins: $coins, currentLevel: $currentLevel, progressDone: $progressDone, progressTotal: $progressTotal, lastCompletedLevel: $lastCompletedLevel)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 int coins, int currentLevel, int progressDone, int progressTotal, int lastCompletedLevel
});




}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coins = null,Object? currentLevel = null,Object? progressDone = null,Object? progressTotal = null,Object? lastCompletedLevel = null,}) {
  return _then(_PlayerState(
coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as int,progressDone: null == progressDone ? _self.progressDone : progressDone // ignore: cast_nullable_to_non_nullable
as int,progressTotal: null == progressTotal ? _self.progressTotal : progressTotal // ignore: cast_nullable_to_non_nullable
as int,lastCompletedLevel: null == lastCompletedLevel ? _self.lastCompletedLevel : lastCompletedLevel // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
