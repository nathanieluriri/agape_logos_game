// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LevelResult {

 String get id; int get levelId; int get score; int get completedAt; bool get synced;
/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelResultCopyWith<LevelResult> get copyWith => _$LevelResultCopyWithImpl<LevelResult>(this as LevelResult, _$identity);

  /// Serializes this LevelResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelResult&&(identical(other.id, id) || other.id == id)&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.score, score) || other.score == score)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.synced, synced) || other.synced == synced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,levelId,score,completedAt,synced);

@override
String toString() {
  return 'LevelResult(id: $id, levelId: $levelId, score: $score, completedAt: $completedAt, synced: $synced)';
}


}

/// @nodoc
abstract mixin class $LevelResultCopyWith<$Res>  {
  factory $LevelResultCopyWith(LevelResult value, $Res Function(LevelResult) _then) = _$LevelResultCopyWithImpl;
@useResult
$Res call({
 String id, int levelId, int score, int completedAt, bool synced
});




}
/// @nodoc
class _$LevelResultCopyWithImpl<$Res>
    implements $LevelResultCopyWith<$Res> {
  _$LevelResultCopyWithImpl(this._self, this._then);

  final LevelResult _self;
  final $Res Function(LevelResult) _then;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? levelId = null,Object? score = null,Object? completedAt = null,Object? synced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelResult].
extension LevelResultPatterns on LevelResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelResult value)  $default,){
final _that = this;
switch (_that) {
case _LevelResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelResult value)?  $default,){
final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int levelId,  int score,  int completedAt,  bool synced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
return $default(_that.id,_that.levelId,_that.score,_that.completedAt,_that.synced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int levelId,  int score,  int completedAt,  bool synced)  $default,) {final _that = this;
switch (_that) {
case _LevelResult():
return $default(_that.id,_that.levelId,_that.score,_that.completedAt,_that.synced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int levelId,  int score,  int completedAt,  bool synced)?  $default,) {final _that = this;
switch (_that) {
case _LevelResult() when $default != null:
return $default(_that.id,_that.levelId,_that.score,_that.completedAt,_that.synced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LevelResult implements LevelResult {
  const _LevelResult({required this.id, required this.levelId, required this.score, required this.completedAt, this.synced = false});
  factory _LevelResult.fromJson(Map<String, dynamic> json) => _$LevelResultFromJson(json);

@override final  String id;
@override final  int levelId;
@override final  int score;
@override final  int completedAt;
@override@JsonKey() final  bool synced;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelResultCopyWith<_LevelResult> get copyWith => __$LevelResultCopyWithImpl<_LevelResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LevelResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelResult&&(identical(other.id, id) || other.id == id)&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.score, score) || other.score == score)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.synced, synced) || other.synced == synced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,levelId,score,completedAt,synced);

@override
String toString() {
  return 'LevelResult(id: $id, levelId: $levelId, score: $score, completedAt: $completedAt, synced: $synced)';
}


}

/// @nodoc
abstract mixin class _$LevelResultCopyWith<$Res> implements $LevelResultCopyWith<$Res> {
  factory _$LevelResultCopyWith(_LevelResult value, $Res Function(_LevelResult) _then) = __$LevelResultCopyWithImpl;
@override @useResult
$Res call({
 String id, int levelId, int score, int completedAt, bool synced
});




}
/// @nodoc
class __$LevelResultCopyWithImpl<$Res>
    implements _$LevelResultCopyWith<$Res> {
  __$LevelResultCopyWithImpl(this._self, this._then);

  final _LevelResult _self;
  final $Res Function(_LevelResult) _then;

/// Create a copy of LevelResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? levelId = null,Object? score = null,Object? completedAt = null,Object? synced = null,}) {
  return _then(_LevelResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
