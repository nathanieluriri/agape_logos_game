// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchHistoryEntry {

 String get matchId; String get opponentUid; String get opponentName; String get result; int get score; int get opponentScore; int get endedAt;
/// Create a copy of MatchHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchHistoryEntryCopyWith<MatchHistoryEntry> get copyWith => _$MatchHistoryEntryCopyWithImpl<MatchHistoryEntry>(this as MatchHistoryEntry, _$identity);

  /// Serializes this MatchHistoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchHistoryEntry&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.opponentUid, opponentUid) || other.opponentUid == opponentUid)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.result, result) || other.result == result)&&(identical(other.score, score) || other.score == score)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,opponentUid,opponentName,result,score,opponentScore,endedAt);

@override
String toString() {
  return 'MatchHistoryEntry(matchId: $matchId, opponentUid: $opponentUid, opponentName: $opponentName, result: $result, score: $score, opponentScore: $opponentScore, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $MatchHistoryEntryCopyWith<$Res>  {
  factory $MatchHistoryEntryCopyWith(MatchHistoryEntry value, $Res Function(MatchHistoryEntry) _then) = _$MatchHistoryEntryCopyWithImpl;
@useResult
$Res call({
 String matchId, String opponentUid, String opponentName, String result, int score, int opponentScore, int endedAt
});




}
/// @nodoc
class _$MatchHistoryEntryCopyWithImpl<$Res>
    implements $MatchHistoryEntryCopyWith<$Res> {
  _$MatchHistoryEntryCopyWithImpl(this._self, this._then);

  final MatchHistoryEntry _self;
  final $Res Function(MatchHistoryEntry) _then;

/// Create a copy of MatchHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? opponentUid = null,Object? opponentName = null,Object? result = null,Object? score = null,Object? opponentScore = null,Object? endedAt = null,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,opponentUid: null == opponentUid ? _self.opponentUid : opponentUid // ignore: cast_nullable_to_non_nullable
as String,opponentName: null == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchHistoryEntry].
extension MatchHistoryEntryPatterns on MatchHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _MatchHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _MatchHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String matchId,  String opponentUid,  String opponentName,  String result,  int score,  int opponentScore,  int endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchHistoryEntry() when $default != null:
return $default(_that.matchId,_that.opponentUid,_that.opponentName,_that.result,_that.score,_that.opponentScore,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String matchId,  String opponentUid,  String opponentName,  String result,  int score,  int opponentScore,  int endedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchHistoryEntry():
return $default(_that.matchId,_that.opponentUid,_that.opponentName,_that.result,_that.score,_that.opponentScore,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String matchId,  String opponentUid,  String opponentName,  String result,  int score,  int opponentScore,  int endedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchHistoryEntry() when $default != null:
return $default(_that.matchId,_that.opponentUid,_that.opponentName,_that.result,_that.score,_that.opponentScore,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchHistoryEntry implements MatchHistoryEntry {
  const _MatchHistoryEntry({required this.matchId, required this.opponentUid, required this.opponentName, required this.result, this.score = 0, this.opponentScore = 0, this.endedAt = 0});
  factory _MatchHistoryEntry.fromJson(Map<String, dynamic> json) => _$MatchHistoryEntryFromJson(json);

@override final  String matchId;
@override final  String opponentUid;
@override final  String opponentName;
@override final  String result;
@override@JsonKey() final  int score;
@override@JsonKey() final  int opponentScore;
@override@JsonKey() final  int endedAt;

/// Create a copy of MatchHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchHistoryEntryCopyWith<_MatchHistoryEntry> get copyWith => __$MatchHistoryEntryCopyWithImpl<_MatchHistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchHistoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchHistoryEntry&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.opponentUid, opponentUid) || other.opponentUid == opponentUid)&&(identical(other.opponentName, opponentName) || other.opponentName == opponentName)&&(identical(other.result, result) || other.result == result)&&(identical(other.score, score) || other.score == score)&&(identical(other.opponentScore, opponentScore) || other.opponentScore == opponentScore)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchId,opponentUid,opponentName,result,score,opponentScore,endedAt);

@override
String toString() {
  return 'MatchHistoryEntry(matchId: $matchId, opponentUid: $opponentUid, opponentName: $opponentName, result: $result, score: $score, opponentScore: $opponentScore, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchHistoryEntryCopyWith<$Res> implements $MatchHistoryEntryCopyWith<$Res> {
  factory _$MatchHistoryEntryCopyWith(_MatchHistoryEntry value, $Res Function(_MatchHistoryEntry) _then) = __$MatchHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String matchId, String opponentUid, String opponentName, String result, int score, int opponentScore, int endedAt
});




}
/// @nodoc
class __$MatchHistoryEntryCopyWithImpl<$Res>
    implements _$MatchHistoryEntryCopyWith<$Res> {
  __$MatchHistoryEntryCopyWithImpl(this._self, this._then);

  final _MatchHistoryEntry _self;
  final $Res Function(_MatchHistoryEntry) _then;

/// Create a copy of MatchHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? opponentUid = null,Object? opponentName = null,Object? result = null,Object? score = null,Object? opponentScore = null,Object? endedAt = null,}) {
  return _then(_MatchHistoryEntry(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,opponentUid: null == opponentUid ? _self.opponentUid : opponentUid // ignore: cast_nullable_to_non_nullable
as String,opponentName: null == opponentName ? _self.opponentName : opponentName // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,opponentScore: null == opponentScore ? _self.opponentScore : opponentScore // ignore: cast_nullable_to_non_nullable
as int,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
