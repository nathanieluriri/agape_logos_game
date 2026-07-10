// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_rack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchRack {

 String get uid; List<String> get letters; String get letterKey; int get rackSize; List<PuzzleAnswer> get answers; int get answerCount; List<String> get foundWords;
/// Create a copy of MatchRack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchRackCopyWith<MatchRack> get copyWith => _$MatchRackCopyWithImpl<MatchRack>(this as MatchRack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchRack&&(identical(other.uid, uid) || other.uid == uid)&&const DeepCollectionEquality().equals(other.letters, letters)&&(identical(other.letterKey, letterKey) || other.letterKey == letterKey)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.answerCount, answerCount) || other.answerCount == answerCount)&&const DeepCollectionEquality().equals(other.foundWords, foundWords));
}


@override
int get hashCode => Object.hash(runtimeType,uid,const DeepCollectionEquality().hash(letters),letterKey,rackSize,const DeepCollectionEquality().hash(answers),answerCount,const DeepCollectionEquality().hash(foundWords));

@override
String toString() {
  return 'MatchRack(uid: $uid, letters: $letters, letterKey: $letterKey, rackSize: $rackSize, answers: $answers, answerCount: $answerCount, foundWords: $foundWords)';
}


}

/// @nodoc
abstract mixin class $MatchRackCopyWith<$Res>  {
  factory $MatchRackCopyWith(MatchRack value, $Res Function(MatchRack) _then) = _$MatchRackCopyWithImpl;
@useResult
$Res call({
 String uid, List<String> letters, String letterKey, int rackSize, List<PuzzleAnswer> answers, int answerCount, List<String> foundWords
});




}
/// @nodoc
class _$MatchRackCopyWithImpl<$Res>
    implements $MatchRackCopyWith<$Res> {
  _$MatchRackCopyWithImpl(this._self, this._then);

  final MatchRack _self;
  final $Res Function(MatchRack) _then;

/// Create a copy of MatchRack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? letters = null,Object? letterKey = null,Object? rackSize = null,Object? answers = null,Object? answerCount = null,Object? foundWords = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,letters: null == letters ? _self.letters : letters // ignore: cast_nullable_to_non_nullable
as List<String>,letterKey: null == letterKey ? _self.letterKey : letterKey // ignore: cast_nullable_to_non_nullable
as String,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<PuzzleAnswer>,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,foundWords: null == foundWords ? _self.foundWords : foundWords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchRack].
extension MatchRackPatterns on MatchRack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchRack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchRack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchRack value)  $default,){
final _that = this;
switch (_that) {
case _MatchRack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchRack value)?  $default,){
final _that = this;
switch (_that) {
case _MatchRack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  List<String> letters,  String letterKey,  int rackSize,  List<PuzzleAnswer> answers,  int answerCount,  List<String> foundWords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchRack() when $default != null:
return $default(_that.uid,_that.letters,_that.letterKey,_that.rackSize,_that.answers,_that.answerCount,_that.foundWords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  List<String> letters,  String letterKey,  int rackSize,  List<PuzzleAnswer> answers,  int answerCount,  List<String> foundWords)  $default,) {final _that = this;
switch (_that) {
case _MatchRack():
return $default(_that.uid,_that.letters,_that.letterKey,_that.rackSize,_that.answers,_that.answerCount,_that.foundWords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  List<String> letters,  String letterKey,  int rackSize,  List<PuzzleAnswer> answers,  int answerCount,  List<String> foundWords)?  $default,) {final _that = this;
switch (_that) {
case _MatchRack() when $default != null:
return $default(_that.uid,_that.letters,_that.letterKey,_that.rackSize,_that.answers,_that.answerCount,_that.foundWords);case _:
  return null;

}
}

}

/// @nodoc


class _MatchRack extends MatchRack {
  const _MatchRack({required this.uid, required final  List<String> letters, required this.letterKey, required this.rackSize, required final  List<PuzzleAnswer> answers, required this.answerCount, required final  List<String> foundWords}): _letters = letters,_answers = answers,_foundWords = foundWords,super._();
  

@override final  String uid;
 final  List<String> _letters;
@override List<String> get letters {
  if (_letters is EqualUnmodifiableListView) return _letters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_letters);
}

@override final  String letterKey;
@override final  int rackSize;
 final  List<PuzzleAnswer> _answers;
@override List<PuzzleAnswer> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override final  int answerCount;
 final  List<String> _foundWords;
@override List<String> get foundWords {
  if (_foundWords is EqualUnmodifiableListView) return _foundWords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foundWords);
}


/// Create a copy of MatchRack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchRackCopyWith<_MatchRack> get copyWith => __$MatchRackCopyWithImpl<_MatchRack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchRack&&(identical(other.uid, uid) || other.uid == uid)&&const DeepCollectionEquality().equals(other._letters, _letters)&&(identical(other.letterKey, letterKey) || other.letterKey == letterKey)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.answerCount, answerCount) || other.answerCount == answerCount)&&const DeepCollectionEquality().equals(other._foundWords, _foundWords));
}


@override
int get hashCode => Object.hash(runtimeType,uid,const DeepCollectionEquality().hash(_letters),letterKey,rackSize,const DeepCollectionEquality().hash(_answers),answerCount,const DeepCollectionEquality().hash(_foundWords));

@override
String toString() {
  return 'MatchRack(uid: $uid, letters: $letters, letterKey: $letterKey, rackSize: $rackSize, answers: $answers, answerCount: $answerCount, foundWords: $foundWords)';
}


}

/// @nodoc
abstract mixin class _$MatchRackCopyWith<$Res> implements $MatchRackCopyWith<$Res> {
  factory _$MatchRackCopyWith(_MatchRack value, $Res Function(_MatchRack) _then) = __$MatchRackCopyWithImpl;
@override @useResult
$Res call({
 String uid, List<String> letters, String letterKey, int rackSize, List<PuzzleAnswer> answers, int answerCount, List<String> foundWords
});




}
/// @nodoc
class __$MatchRackCopyWithImpl<$Res>
    implements _$MatchRackCopyWith<$Res> {
  __$MatchRackCopyWithImpl(this._self, this._then);

  final _MatchRack _self;
  final $Res Function(_MatchRack) _then;

/// Create a copy of MatchRack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? letters = null,Object? letterKey = null,Object? rackSize = null,Object? answers = null,Object? answerCount = null,Object? foundWords = null,}) {
  return _then(_MatchRack(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,letters: null == letters ? _self._letters : letters // ignore: cast_nullable_to_non_nullable
as List<String>,letterKey: null == letterKey ? _self.letterKey : letterKey // ignore: cast_nullable_to_non_nullable
as String,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<PuzzleAnswer>,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,foundWords: null == foundWords ? _self._foundWords : foundWords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
