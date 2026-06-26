// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSession {

 Puzzle get puzzle; List<int> get rackOrder; List<int> get selection; Set<String> get found; Map<String, int> get revealed; int get score; int get combo; int get hintsLeft;
/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSessionCopyWith<GameSession> get copyWith => _$GameSessionCopyWithImpl<GameSession>(this as GameSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSession&&(identical(other.puzzle, puzzle) || other.puzzle == puzzle)&&const DeepCollectionEquality().equals(other.rackOrder, rackOrder)&&const DeepCollectionEquality().equals(other.selection, selection)&&const DeepCollectionEquality().equals(other.found, found)&&const DeepCollectionEquality().equals(other.revealed, revealed)&&(identical(other.score, score) || other.score == score)&&(identical(other.combo, combo) || other.combo == combo)&&(identical(other.hintsLeft, hintsLeft) || other.hintsLeft == hintsLeft));
}


@override
int get hashCode => Object.hash(runtimeType,puzzle,const DeepCollectionEquality().hash(rackOrder),const DeepCollectionEquality().hash(selection),const DeepCollectionEquality().hash(found),const DeepCollectionEquality().hash(revealed),score,combo,hintsLeft);

@override
String toString() {
  return 'GameSession(puzzle: $puzzle, rackOrder: $rackOrder, selection: $selection, found: $found, revealed: $revealed, score: $score, combo: $combo, hintsLeft: $hintsLeft)';
}


}

/// @nodoc
abstract mixin class $GameSessionCopyWith<$Res>  {
  factory $GameSessionCopyWith(GameSession value, $Res Function(GameSession) _then) = _$GameSessionCopyWithImpl;
@useResult
$Res call({
 Puzzle puzzle, List<int> rackOrder, List<int> selection, Set<String> found, Map<String, int> revealed, int score, int combo, int hintsLeft
});


$PuzzleCopyWith<$Res> get puzzle;

}
/// @nodoc
class _$GameSessionCopyWithImpl<$Res>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._self, this._then);

  final GameSession _self;
  final $Res Function(GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? puzzle = null,Object? rackOrder = null,Object? selection = null,Object? found = null,Object? revealed = null,Object? score = null,Object? combo = null,Object? hintsLeft = null,}) {
  return _then(_self.copyWith(
puzzle: null == puzzle ? _self.puzzle : puzzle // ignore: cast_nullable_to_non_nullable
as Puzzle,rackOrder: null == rackOrder ? _self.rackOrder : rackOrder // ignore: cast_nullable_to_non_nullable
as List<int>,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as List<int>,found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as Set<String>,revealed: null == revealed ? _self.revealed : revealed // ignore: cast_nullable_to_non_nullable
as Map<String, int>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,combo: null == combo ? _self.combo : combo // ignore: cast_nullable_to_non_nullable
as int,hintsLeft: null == hintsLeft ? _self.hintsLeft : hintsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PuzzleCopyWith<$Res> get puzzle {
  
  return $PuzzleCopyWith<$Res>(_self.puzzle, (value) {
    return _then(_self.copyWith(puzzle: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSession].
extension GameSessionPatterns on GameSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSession value)  $default,){
final _that = this;
switch (_that) {
case _GameSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSession value)?  $default,){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Puzzle puzzle,  List<int> rackOrder,  List<int> selection,  Set<String> found,  Map<String, int> revealed,  int score,  int combo,  int hintsLeft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.puzzle,_that.rackOrder,_that.selection,_that.found,_that.revealed,_that.score,_that.combo,_that.hintsLeft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Puzzle puzzle,  List<int> rackOrder,  List<int> selection,  Set<String> found,  Map<String, int> revealed,  int score,  int combo,  int hintsLeft)  $default,) {final _that = this;
switch (_that) {
case _GameSession():
return $default(_that.puzzle,_that.rackOrder,_that.selection,_that.found,_that.revealed,_that.score,_that.combo,_that.hintsLeft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Puzzle puzzle,  List<int> rackOrder,  List<int> selection,  Set<String> found,  Map<String, int> revealed,  int score,  int combo,  int hintsLeft)?  $default,) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.puzzle,_that.rackOrder,_that.selection,_that.found,_that.revealed,_that.score,_that.combo,_that.hintsLeft);case _:
  return null;

}
}

}

/// @nodoc


class _GameSession extends GameSession {
  const _GameSession({required this.puzzle, required final  List<int> rackOrder, required final  List<int> selection, required final  Set<String> found, required final  Map<String, int> revealed, required this.score, required this.combo, required this.hintsLeft}): _rackOrder = rackOrder,_selection = selection,_found = found,_revealed = revealed,super._();
  

@override final  Puzzle puzzle;
 final  List<int> _rackOrder;
@override List<int> get rackOrder {
  if (_rackOrder is EqualUnmodifiableListView) return _rackOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rackOrder);
}

 final  List<int> _selection;
@override List<int> get selection {
  if (_selection is EqualUnmodifiableListView) return _selection;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selection);
}

 final  Set<String> _found;
@override Set<String> get found {
  if (_found is EqualUnmodifiableSetView) return _found;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_found);
}

 final  Map<String, int> _revealed;
@override Map<String, int> get revealed {
  if (_revealed is EqualUnmodifiableMapView) return _revealed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_revealed);
}

@override final  int score;
@override final  int combo;
@override final  int hintsLeft;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSessionCopyWith<_GameSession> get copyWith => __$GameSessionCopyWithImpl<_GameSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSession&&(identical(other.puzzle, puzzle) || other.puzzle == puzzle)&&const DeepCollectionEquality().equals(other._rackOrder, _rackOrder)&&const DeepCollectionEquality().equals(other._selection, _selection)&&const DeepCollectionEquality().equals(other._found, _found)&&const DeepCollectionEquality().equals(other._revealed, _revealed)&&(identical(other.score, score) || other.score == score)&&(identical(other.combo, combo) || other.combo == combo)&&(identical(other.hintsLeft, hintsLeft) || other.hintsLeft == hintsLeft));
}


@override
int get hashCode => Object.hash(runtimeType,puzzle,const DeepCollectionEquality().hash(_rackOrder),const DeepCollectionEquality().hash(_selection),const DeepCollectionEquality().hash(_found),const DeepCollectionEquality().hash(_revealed),score,combo,hintsLeft);

@override
String toString() {
  return 'GameSession(puzzle: $puzzle, rackOrder: $rackOrder, selection: $selection, found: $found, revealed: $revealed, score: $score, combo: $combo, hintsLeft: $hintsLeft)';
}


}

/// @nodoc
abstract mixin class _$GameSessionCopyWith<$Res> implements $GameSessionCopyWith<$Res> {
  factory _$GameSessionCopyWith(_GameSession value, $Res Function(_GameSession) _then) = __$GameSessionCopyWithImpl;
@override @useResult
$Res call({
 Puzzle puzzle, List<int> rackOrder, List<int> selection, Set<String> found, Map<String, int> revealed, int score, int combo, int hintsLeft
});


@override $PuzzleCopyWith<$Res> get puzzle;

}
/// @nodoc
class __$GameSessionCopyWithImpl<$Res>
    implements _$GameSessionCopyWith<$Res> {
  __$GameSessionCopyWithImpl(this._self, this._then);

  final _GameSession _self;
  final $Res Function(_GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? puzzle = null,Object? rackOrder = null,Object? selection = null,Object? found = null,Object? revealed = null,Object? score = null,Object? combo = null,Object? hintsLeft = null,}) {
  return _then(_GameSession(
puzzle: null == puzzle ? _self.puzzle : puzzle // ignore: cast_nullable_to_non_nullable
as Puzzle,rackOrder: null == rackOrder ? _self._rackOrder : rackOrder // ignore: cast_nullable_to_non_nullable
as List<int>,selection: null == selection ? _self._selection : selection // ignore: cast_nullable_to_non_nullable
as List<int>,found: null == found ? _self._found : found // ignore: cast_nullable_to_non_nullable
as Set<String>,revealed: null == revealed ? _self._revealed : revealed // ignore: cast_nullable_to_non_nullable
as Map<String, int>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,combo: null == combo ? _self.combo : combo // ignore: cast_nullable_to_non_nullable
as int,hintsLeft: null == hintsLeft ? _self.hintsLeft : hintsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PuzzleCopyWith<$Res> get puzzle {
  
  return $PuzzleCopyWith<$Res>(_self.puzzle, (value) {
    return _then(_self.copyWith(puzzle: value));
  });
}
}

// dart format on
