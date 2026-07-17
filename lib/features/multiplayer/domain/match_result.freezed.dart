// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchResult {

 String get matchId; String get outcome; int get myScore; int get opponentScore; String get opponentName;
/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchResultCopyWith<MatchResult> get copyWith => _$MatchResultCopyWithImpl<MatchResult>(this as MatchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchResult&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.myScore, myScore) || other.myScore == myScore)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName));
}


@override
int get hashCode => Object.hash(runtimeType,matchId,outcome,myScore,opponentScore,opponentName);

@override
String toString() {
  return 'MatchResult(matchId: $matchId, outcome: $outcome, myScore: $myScore, opponentScore: $opponentScore, opponentName: $opponentName)';
}


}

/// @nodoc
abstract mixin class $MatchResultCopyWith<$Res>  {
  factory $MatchResultCopyWith(MatchResult value, $Res Function(MatchResult) _then) = _$MatchResultCopyWithImpl;
@useResult
$Res call({
 String matchId, String outcome, int myScore, int opponentScore, String opponentName
});




}
/// @nodoc
class _$MatchResultCopyWithImpl<$Res>
    implements $MatchResultCopyWith<$Res> {
  _$MatchResultCopyWithImpl(this._self, this._then);

  final MatchResult _self;
  final $Res Function(MatchResult) _then;

/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? outcome = null,Object? myScore = null,Object? opponentScore = null,Object? opponentName = null,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,myScore: null == myScore ? _self.myScore : myScore // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,opponentName: null == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchResult].
extension MatchResultPatterns on MatchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchResult value)  $default,){
final _that = this;
switch (_that) {
case _MatchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchResult value)?  $default,){
final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String matchId,  String outcome,  int myScore,  int opponentScore,  String opponentName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that.matchId,_that.outcome,_that.myScore,_that.opponentScore,_that.opponentName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String matchId,  String outcome,  int myScore,  int opponentScore,  String opponentName)  $default,) {final _that = this;
switch (_that) {
case _MatchResult():
return $default(_that.matchId,_that.outcome,_that.myScore,_that.opponentScore,_that.opponentName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String matchId,  String outcome,  int myScore,  int opponentScore,  String opponentName)?  $default,) {final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that.matchId,_that.outcome,_that.myScore,_that.opponentScore,_that.opponentName);case _:
  return null;

}
}

}

/// @nodoc


class _MatchResult extends MatchResult {
  const _MatchResult({required this.matchId, required this.outcome, required this.myScore, required this.opponentScore, required this.opponentName}): super._();
  

@override final  String matchId;
@override final  String outcome;
@override final  int myScore;
@override final  int opponentScore;
@override final  String opponentName;

/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchResultCopyWith<_MatchResult> get copyWith => __$MatchResultCopyWithImpl<_MatchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchResult&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.myScore, myScore) || other.myScore == myScore)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName));
}


@override
int get hashCode => Object.hash(runtimeType,matchId,outcome,myScore,opponentScore,opponentName);

@override
String toString() {
  return 'MatchResult(matchId: $matchId, outcome: $outcome, myScore: $myScore, opponentScore: $opponentScore, opponentName: $opponentName)';
}


}

/// @nodoc
abstract mixin class _$MatchResultCopyWith<$Res> implements $MatchResultCopyWith<$Res> {
  factory _$MatchResultCopyWith(_MatchResult value, $Res Function(_MatchResult) _then) = __$MatchResultCopyWithImpl;
@override @useResult
$Res call({
 String matchId, String outcome, int myScore, int opponentScore, String opponentName
});




}
/// @nodoc
class __$MatchResultCopyWithImpl<$Res>
    implements _$MatchResultCopyWith<$Res> {
  __$MatchResultCopyWithImpl(this._self, this._then);

  final _MatchResult _self;
  final $Res Function(_MatchResult) _then;

/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? outcome = null,Object? myScore = null,Object? opponentScore = null,Object? opponentName = null,}) {
  return _then(_MatchResult(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,myScore: null == myScore ? _self.myScore : myScore // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,opponentName: null == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
