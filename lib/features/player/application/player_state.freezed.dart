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
mixin _$LevelSummary {

/// The progression level that was completed (backend `highestLevel` value).
 int get completedLevel;/// Words found in the puzzle (equals [totalWords] on a full completion).
 int get wordsFound;/// The puzzle's total answers (`answerCount` from the backend puzzle).
 int get totalWords;
/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LevelSummaryCopyWith<LevelSummary> get copyWith => _$LevelSummaryCopyWithImpl<LevelSummary>(this as LevelSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelSummary&&(identical(other.completedLevel, completedLevel) || other.completedLevel == completedLevel)&&(identical(other.wordsFound, wordsFound) || other.wordsFound == wordsFound)&&(identical(other.totalWords, totalWords) || other.totalWords == totalWords));
}


@override
int get hashCode => Object.hash(runtimeType,completedLevel,wordsFound,totalWords);

@override
String toString() {
  return 'LevelSummary(completedLevel: $completedLevel, wordsFound: $wordsFound, totalWords: $totalWords)';
}


}

/// @nodoc
abstract mixin class $LevelSummaryCopyWith<$Res>  {
  factory $LevelSummaryCopyWith(LevelSummary value, $Res Function(LevelSummary) _then) = _$LevelSummaryCopyWithImpl;
@useResult
$Res call({
 int completedLevel, int wordsFound, int totalWords
});




}
/// @nodoc
class _$LevelSummaryCopyWithImpl<$Res>
    implements $LevelSummaryCopyWith<$Res> {
  _$LevelSummaryCopyWithImpl(this._self, this._then);

  final LevelSummary _self;
  final $Res Function(LevelSummary) _then;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completedLevel = null,Object? wordsFound = null,Object? totalWords = null,}) {
  return _then(_self.copyWith(
completedLevel: null == completedLevel ? _self.completedLevel : completedLevel // ignore: cast_nullable_to_non_nullable
as int,wordsFound: null == wordsFound ? _self.wordsFound : wordsFound // ignore: cast_nullable_to_non_nullable
as int,totalWords: null == totalWords ? _self.totalWords : totalWords // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LevelSummary].
extension LevelSummaryPatterns on LevelSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LevelSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LevelSummary value)  $default,){
final _that = this;
switch (_that) {
case _LevelSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LevelSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int completedLevel,  int wordsFound,  int totalWords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
return $default(_that.completedLevel,_that.wordsFound,_that.totalWords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int completedLevel,  int wordsFound,  int totalWords)  $default,) {final _that = this;
switch (_that) {
case _LevelSummary():
return $default(_that.completedLevel,_that.wordsFound,_that.totalWords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int completedLevel,  int wordsFound,  int totalWords)?  $default,) {final _that = this;
switch (_that) {
case _LevelSummary() when $default != null:
return $default(_that.completedLevel,_that.wordsFound,_that.totalWords);case _:
  return null;

}
}

}

/// @nodoc


class _LevelSummary extends LevelSummary {
  const _LevelSummary({required this.completedLevel, required this.wordsFound, required this.totalWords}): super._();
  

/// The progression level that was completed (backend `highestLevel` value).
@override final  int completedLevel;
/// Words found in the puzzle (equals [totalWords] on a full completion).
@override final  int wordsFound;
/// The puzzle's total answers (`answerCount` from the backend puzzle).
@override final  int totalWords;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LevelSummaryCopyWith<_LevelSummary> get copyWith => __$LevelSummaryCopyWithImpl<_LevelSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LevelSummary&&(identical(other.completedLevel, completedLevel) || other.completedLevel == completedLevel)&&(identical(other.wordsFound, wordsFound) || other.wordsFound == wordsFound)&&(identical(other.totalWords, totalWords) || other.totalWords == totalWords));
}


@override
int get hashCode => Object.hash(runtimeType,completedLevel,wordsFound,totalWords);

@override
String toString() {
  return 'LevelSummary(completedLevel: $completedLevel, wordsFound: $wordsFound, totalWords: $totalWords)';
}


}

/// @nodoc
abstract mixin class _$LevelSummaryCopyWith<$Res> implements $LevelSummaryCopyWith<$Res> {
  factory _$LevelSummaryCopyWith(_LevelSummary value, $Res Function(_LevelSummary) _then) = __$LevelSummaryCopyWithImpl;
@override @useResult
$Res call({
 int completedLevel, int wordsFound, int totalWords
});




}
/// @nodoc
class __$LevelSummaryCopyWithImpl<$Res>
    implements _$LevelSummaryCopyWith<$Res> {
  __$LevelSummaryCopyWithImpl(this._self, this._then);

  final _LevelSummary _self;
  final $Res Function(_LevelSummary) _then;

/// Create a copy of LevelSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completedLevel = null,Object? wordsFound = null,Object? totalWords = null,}) {
  return _then(_LevelSummary(
completedLevel: null == completedLevel ? _self.completedLevel : completedLevel // ignore: cast_nullable_to_non_nullable
as int,wordsFound: null == wordsFound ? _self.wordsFound : wordsFound // ignore: cast_nullable_to_non_nullable
as int,totalWords: null == totalWords ? _self.totalWords : totalWords // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
