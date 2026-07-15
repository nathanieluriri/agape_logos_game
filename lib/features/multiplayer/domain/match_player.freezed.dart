// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchPlayer {

 String get uid; String get displayName; String get avatarId; bool get isGuest; bool get ready; bool get connected; int get score; int get wordsFound; int get endsAtBonusMs; int get lastWordAt; int get finishedAt;
/// Create a copy of MatchPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPlayerCopyWith<MatchPlayer> get copyWith => _$MatchPlayerCopyWithImpl<MatchPlayer>(this as MatchPlayer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPlayer&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.score, score) || other.score == score)&&(identical(other.wordsFound, wordsFound) || other.wordsFound == wordsFound)&&(identical(other.endsAtBonusMs, endsAtBonusMs) || other.endsAtBonusMs == endsAtBonusMs)&&(identical(other.lastWordAt, lastWordAt) || other.lastWordAt == lastWordAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,uid,displayName,avatarId,isGuest,ready,connected,score,wordsFound,endsAtBonusMs,lastWordAt,finishedAt);

@override
String toString() {
  return 'MatchPlayer(uid: $uid, displayName: $displayName, avatarId: $avatarId, isGuest: $isGuest, ready: $ready, connected: $connected, score: $score, wordsFound: $wordsFound, endsAtBonusMs: $endsAtBonusMs, lastWordAt: $lastWordAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class $MatchPlayerCopyWith<$Res>  {
  factory $MatchPlayerCopyWith(MatchPlayer value, $Res Function(MatchPlayer) _then) = _$MatchPlayerCopyWithImpl;
@useResult
$Res call({
 String uid, String displayName, String avatarId, bool isGuest, bool ready, bool connected, int score, int wordsFound, int endsAtBonusMs, int lastWordAt, int finishedAt
});




}
/// @nodoc
class _$MatchPlayerCopyWithImpl<$Res>
    implements $MatchPlayerCopyWith<$Res> {
  _$MatchPlayerCopyWithImpl(this._self, this._then);

  final MatchPlayer _self;
  final $Res Function(MatchPlayer) _then;

/// Create a copy of MatchPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? avatarId = null,Object? isGuest = null,Object? ready = null,Object? connected = null,Object? score = null,Object? wordsFound = null,Object? endsAtBonusMs = null,Object? lastWordAt = null,Object? finishedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,wordsFound: null == wordsFound ? _self.wordsFound : wordsFound // ignore: cast_nullable_to_non_nullable
as int,endsAtBonusMs: null == endsAtBonusMs ? _self.endsAtBonusMs : endsAtBonusMs // ignore: cast_nullable_to_non_nullable
as int,lastWordAt: null == lastWordAt ? _self.lastWordAt : lastWordAt // ignore: cast_nullable_to_non_nullable
as int,finishedAt: null == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchPlayer].
extension MatchPlayerPatterns on MatchPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchPlayer value)  $default,){
final _that = this;
switch (_that) {
case _MatchPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _MatchPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String displayName,  String avatarId,  bool isGuest,  bool ready,  bool connected,  int score,  int wordsFound,  int endsAtBonusMs,  int lastWordAt,  int finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchPlayer() when $default != null:
return $default(_that.uid,_that.displayName,_that.avatarId,_that.isGuest,_that.ready,_that.connected,_that.score,_that.wordsFound,_that.endsAtBonusMs,_that.lastWordAt,_that.finishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String displayName,  String avatarId,  bool isGuest,  bool ready,  bool connected,  int score,  int wordsFound,  int endsAtBonusMs,  int lastWordAt,  int finishedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchPlayer():
return $default(_that.uid,_that.displayName,_that.avatarId,_that.isGuest,_that.ready,_that.connected,_that.score,_that.wordsFound,_that.endsAtBonusMs,_that.lastWordAt,_that.finishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String displayName,  String avatarId,  bool isGuest,  bool ready,  bool connected,  int score,  int wordsFound,  int endsAtBonusMs,  int lastWordAt,  int finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchPlayer() when $default != null:
return $default(_that.uid,_that.displayName,_that.avatarId,_that.isGuest,_that.ready,_that.connected,_that.score,_that.wordsFound,_that.endsAtBonusMs,_that.lastWordAt,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MatchPlayer implements MatchPlayer {
  const _MatchPlayer({required this.uid, required this.displayName, required this.avatarId, required this.isGuest, required this.ready, required this.connected, required this.score, required this.wordsFound, this.endsAtBonusMs = 0, this.lastWordAt = 0, this.finishedAt = 0});
  

@override final  String uid;
@override final  String displayName;
@override final  String avatarId;
@override final  bool isGuest;
@override final  bool ready;
@override final  bool connected;
@override final  int score;
@override final  int wordsFound;
@override@JsonKey() final  int endsAtBonusMs;
@override@JsonKey() final  int lastWordAt;
@override@JsonKey() final  int finishedAt;

/// Create a copy of MatchPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchPlayerCopyWith<_MatchPlayer> get copyWith => __$MatchPlayerCopyWithImpl<_MatchPlayer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchPlayer&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.score, score) || other.score == score)&&(identical(other.wordsFound, wordsFound) || other.wordsFound == wordsFound)&&(identical(other.endsAtBonusMs, endsAtBonusMs) || other.endsAtBonusMs == endsAtBonusMs)&&(identical(other.lastWordAt, lastWordAt) || other.lastWordAt == lastWordAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,uid,displayName,avatarId,isGuest,ready,connected,score,wordsFound,endsAtBonusMs,lastWordAt,finishedAt);

@override
String toString() {
  return 'MatchPlayer(uid: $uid, displayName: $displayName, avatarId: $avatarId, isGuest: $isGuest, ready: $ready, connected: $connected, score: $score, wordsFound: $wordsFound, endsAtBonusMs: $endsAtBonusMs, lastWordAt: $lastWordAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchPlayerCopyWith<$Res> implements $MatchPlayerCopyWith<$Res> {
  factory _$MatchPlayerCopyWith(_MatchPlayer value, $Res Function(_MatchPlayer) _then) = __$MatchPlayerCopyWithImpl;
@override @useResult
$Res call({
 String uid, String displayName, String avatarId, bool isGuest, bool ready, bool connected, int score, int wordsFound, int endsAtBonusMs, int lastWordAt, int finishedAt
});




}
/// @nodoc
class __$MatchPlayerCopyWithImpl<$Res>
    implements _$MatchPlayerCopyWith<$Res> {
  __$MatchPlayerCopyWithImpl(this._self, this._then);

  final _MatchPlayer _self;
  final $Res Function(_MatchPlayer) _then;

/// Create a copy of MatchPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? avatarId = null,Object? isGuest = null,Object? ready = null,Object? connected = null,Object? score = null,Object? wordsFound = null,Object? endsAtBonusMs = null,Object? lastWordAt = null,Object? finishedAt = null,}) {
  return _then(_MatchPlayer(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,wordsFound: null == wordsFound ? _self.wordsFound : wordsFound // ignore: cast_nullable_to_non_nullable
as int,endsAtBonusMs: null == endsAtBonusMs ? _self.endsAtBonusMs : endsAtBonusMs // ignore: cast_nullable_to_non_nullable
as int,lastWordAt: null == lastWordAt ? _self.lastWordAt : lastWordAt // ignore: cast_nullable_to_non_nullable
as int,finishedAt: null == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
