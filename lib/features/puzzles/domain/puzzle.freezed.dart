// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'puzzle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PuzzleAnswer {

 String get word; int get length; String? get definition;
/// Create a copy of PuzzleAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PuzzleAnswerCopyWith<PuzzleAnswer> get copyWith => _$PuzzleAnswerCopyWithImpl<PuzzleAnswer>(this as PuzzleAnswer, _$identity);

  /// Serializes this PuzzleAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PuzzleAnswer&&(identical(other.word, word) || other.word == word)&&(identical(other.length, length) || other.length == length)&&(identical(other.definition, definition) || other.definition == definition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,length,definition);

@override
String toString() {
  return 'PuzzleAnswer(word: $word, length: $length, definition: $definition)';
}


}

/// @nodoc
abstract mixin class $PuzzleAnswerCopyWith<$Res>  {
  factory $PuzzleAnswerCopyWith(PuzzleAnswer value, $Res Function(PuzzleAnswer) _then) = _$PuzzleAnswerCopyWithImpl;
@useResult
$Res call({
 String word, int length, String? definition
});




}
/// @nodoc
class _$PuzzleAnswerCopyWithImpl<$Res>
    implements $PuzzleAnswerCopyWith<$Res> {
  _$PuzzleAnswerCopyWithImpl(this._self, this._then);

  final PuzzleAnswer _self;
  final $Res Function(PuzzleAnswer) _then;

/// Create a copy of PuzzleAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? word = null,Object? length = null,Object? definition = freezed,}) {
  return _then(_self.copyWith(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PuzzleAnswer].
extension PuzzleAnswerPatterns on PuzzleAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PuzzleAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PuzzleAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PuzzleAnswer value)  $default,){
final _that = this;
switch (_that) {
case _PuzzleAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PuzzleAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _PuzzleAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String word,  int length,  String? definition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PuzzleAnswer() when $default != null:
return $default(_that.word,_that.length,_that.definition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String word,  int length,  String? definition)  $default,) {final _that = this;
switch (_that) {
case _PuzzleAnswer():
return $default(_that.word,_that.length,_that.definition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String word,  int length,  String? definition)?  $default,) {final _that = this;
switch (_that) {
case _PuzzleAnswer() when $default != null:
return $default(_that.word,_that.length,_that.definition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PuzzleAnswer implements PuzzleAnswer {
  const _PuzzleAnswer({required this.word, required this.length, required this.definition});
  factory _PuzzleAnswer.fromJson(Map<String, dynamic> json) => _$PuzzleAnswerFromJson(json);

@override final  String word;
@override final  int length;
@override final  String? definition;

/// Create a copy of PuzzleAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PuzzleAnswerCopyWith<_PuzzleAnswer> get copyWith => __$PuzzleAnswerCopyWithImpl<_PuzzleAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PuzzleAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PuzzleAnswer&&(identical(other.word, word) || other.word == word)&&(identical(other.length, length) || other.length == length)&&(identical(other.definition, definition) || other.definition == definition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,length,definition);

@override
String toString() {
  return 'PuzzleAnswer(word: $word, length: $length, definition: $definition)';
}


}

/// @nodoc
abstract mixin class _$PuzzleAnswerCopyWith<$Res> implements $PuzzleAnswerCopyWith<$Res> {
  factory _$PuzzleAnswerCopyWith(_PuzzleAnswer value, $Res Function(_PuzzleAnswer) _then) = __$PuzzleAnswerCopyWithImpl;
@override @useResult
$Res call({
 String word, int length, String? definition
});




}
/// @nodoc
class __$PuzzleAnswerCopyWithImpl<$Res>
    implements _$PuzzleAnswerCopyWith<$Res> {
  __$PuzzleAnswerCopyWithImpl(this._self, this._then);

  final _PuzzleAnswer _self;
  final $Res Function(_PuzzleAnswer) _then;

/// Create a copy of PuzzleAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? word = null,Object? length = null,Object? definition = freezed,}) {
  return _then(_PuzzleAnswer(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Puzzle {

 String get tier; int get rackSize; List<String> get letters; String get letterKey; String get anchor; List<PuzzleAnswer> get answers; int get answerCount;
/// Create a copy of Puzzle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PuzzleCopyWith<Puzzle> get copyWith => _$PuzzleCopyWithImpl<Puzzle>(this as Puzzle, _$identity);

  /// Serializes this Puzzle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Puzzle&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&const DeepCollectionEquality().equals(other.letters, letters)&&(identical(other.letterKey, letterKey) || other.letterKey == letterKey)&&(identical(other.anchor, anchor) || other.anchor == anchor)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.answerCount, answerCount) || other.answerCount == answerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,rackSize,const DeepCollectionEquality().hash(letters),letterKey,anchor,const DeepCollectionEquality().hash(answers),answerCount);

@override
String toString() {
  return 'Puzzle(tier: $tier, rackSize: $rackSize, letters: $letters, letterKey: $letterKey, anchor: $anchor, answers: $answers, answerCount: $answerCount)';
}


}

/// @nodoc
abstract mixin class $PuzzleCopyWith<$Res>  {
  factory $PuzzleCopyWith(Puzzle value, $Res Function(Puzzle) _then) = _$PuzzleCopyWithImpl;
@useResult
$Res call({
 String tier, int rackSize, List<String> letters, String letterKey, String anchor, List<PuzzleAnswer> answers, int answerCount
});




}
/// @nodoc
class _$PuzzleCopyWithImpl<$Res>
    implements $PuzzleCopyWith<$Res> {
  _$PuzzleCopyWithImpl(this._self, this._then);

  final Puzzle _self;
  final $Res Function(Puzzle) _then;

/// Create a copy of Puzzle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? rackSize = null,Object? letters = null,Object? letterKey = null,Object? anchor = null,Object? answers = null,Object? answerCount = null,}) {
  return _then(_self.copyWith(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,letters: null == letters ? _self.letters : letters // ignore: cast_nullable_to_non_nullable
as List<String>,letterKey: null == letterKey ? _self.letterKey : letterKey // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<PuzzleAnswer>,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Puzzle].
extension PuzzlePatterns on Puzzle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Puzzle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Puzzle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Puzzle value)  $default,){
final _that = this;
switch (_that) {
case _Puzzle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Puzzle value)?  $default,){
final _that = this;
switch (_that) {
case _Puzzle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tier,  int rackSize,  List<String> letters,  String letterKey,  String anchor,  List<PuzzleAnswer> answers,  int answerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Puzzle() when $default != null:
return $default(_that.tier,_that.rackSize,_that.letters,_that.letterKey,_that.anchor,_that.answers,_that.answerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tier,  int rackSize,  List<String> letters,  String letterKey,  String anchor,  List<PuzzleAnswer> answers,  int answerCount)  $default,) {final _that = this;
switch (_that) {
case _Puzzle():
return $default(_that.tier,_that.rackSize,_that.letters,_that.letterKey,_that.anchor,_that.answers,_that.answerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tier,  int rackSize,  List<String> letters,  String letterKey,  String anchor,  List<PuzzleAnswer> answers,  int answerCount)?  $default,) {final _that = this;
switch (_that) {
case _Puzzle() when $default != null:
return $default(_that.tier,_that.rackSize,_that.letters,_that.letterKey,_that.anchor,_that.answers,_that.answerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Puzzle implements Puzzle {
  const _Puzzle({required this.tier, required this.rackSize, required final  List<String> letters, required this.letterKey, required this.anchor, required final  List<PuzzleAnswer> answers, required this.answerCount}): _letters = letters,_answers = answers;
  factory _Puzzle.fromJson(Map<String, dynamic> json) => _$PuzzleFromJson(json);

@override final  String tier;
@override final  int rackSize;
 final  List<String> _letters;
@override List<String> get letters {
  if (_letters is EqualUnmodifiableListView) return _letters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_letters);
}

@override final  String letterKey;
@override final  String anchor;
 final  List<PuzzleAnswer> _answers;
@override List<PuzzleAnswer> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override final  int answerCount;

/// Create a copy of Puzzle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PuzzleCopyWith<_Puzzle> get copyWith => __$PuzzleCopyWithImpl<_Puzzle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PuzzleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Puzzle&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.rackSize, rackSize) || other.rackSize == rackSize)&&const DeepCollectionEquality().equals(other._letters, _letters)&&(identical(other.letterKey, letterKey) || other.letterKey == letterKey)&&(identical(other.anchor, anchor) || other.anchor == anchor)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.answerCount, answerCount) || other.answerCount == answerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,rackSize,const DeepCollectionEquality().hash(_letters),letterKey,anchor,const DeepCollectionEquality().hash(_answers),answerCount);

@override
String toString() {
  return 'Puzzle(tier: $tier, rackSize: $rackSize, letters: $letters, letterKey: $letterKey, anchor: $anchor, answers: $answers, answerCount: $answerCount)';
}


}

/// @nodoc
abstract mixin class _$PuzzleCopyWith<$Res> implements $PuzzleCopyWith<$Res> {
  factory _$PuzzleCopyWith(_Puzzle value, $Res Function(_Puzzle) _then) = __$PuzzleCopyWithImpl;
@override @useResult
$Res call({
 String tier, int rackSize, List<String> letters, String letterKey, String anchor, List<PuzzleAnswer> answers, int answerCount
});




}
/// @nodoc
class __$PuzzleCopyWithImpl<$Res>
    implements _$PuzzleCopyWith<$Res> {
  __$PuzzleCopyWithImpl(this._self, this._then);

  final _Puzzle _self;
  final $Res Function(_Puzzle) _then;

/// Create a copy of Puzzle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? rackSize = null,Object? letters = null,Object? letterKey = null,Object? anchor = null,Object? answers = null,Object? answerCount = null,}) {
  return _then(_Puzzle(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,rackSize: null == rackSize ? _self.rackSize : rackSize // ignore: cast_nullable_to_non_nullable
as int,letters: null == letters ? _self._letters : letters // ignore: cast_nullable_to_non_nullable
as List<String>,letterKey: null == letterKey ? _self.letterKey : letterKey // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<PuzzleAnswer>,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
