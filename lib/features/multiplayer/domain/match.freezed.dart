// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Match {

 String get matchId; String get code; MatchStatus get status; List<String> get participants; List<String> get playerOrder; String get createdBy; int get createdAt; int get startedAt; int get endsAt; MatchSettings get settings; Map<String, MatchPlayer> get players; String? get winner;
/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchCopyWith<Match> get copyWith => _$MatchCopyWithImpl<Match>(this as Match, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Match&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.participants, participants)&&const DeepCollectionEquality().equals(other.playerOrder, playerOrder)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.players, players)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode => Object.hash(runtimeType,matchId,code,status,const DeepCollectionEquality().hash(participants),const DeepCollectionEquality().hash(playerOrder),createdBy,createdAt,startedAt,endsAt,settings,const DeepCollectionEquality().hash(players),winner);

@override
String toString() {
  return 'Match(matchId: $matchId, code: $code, status: $status, participants: $participants, playerOrder: $playerOrder, createdBy: $createdBy, createdAt: $createdAt, startedAt: $startedAt, endsAt: $endsAt, settings: $settings, players: $players, winner: $winner)';
}


}

/// @nodoc
abstract mixin class $MatchCopyWith<$Res>  {
  factory $MatchCopyWith(Match value, $Res Function(Match) _then) = _$MatchCopyWithImpl;
@useResult
$Res call({
 String matchId, String code, MatchStatus status, List<String> participants, List<String> playerOrder, String createdBy, int createdAt, int startedAt, int endsAt, MatchSettings settings, Map<String, MatchPlayer> players, String? winner
});


$MatchSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$MatchCopyWithImpl<$Res>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._self, this._then);

  final Match _self;
  final $Res Function(Match) _then;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchId = null,Object? code = null,Object? status = null,Object? participants = null,Object? playerOrder = null,Object? createdBy = null,Object? createdAt = null,Object? startedAt = null,Object? endsAt = null,Object? settings = null,Object? players = null,Object? winner = freezed,}) {
  return _then(_self.copyWith(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,playerOrder: null == playerOrder ? _self.playerOrder : playerOrder // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as MatchSettings,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as Map<String, MatchPlayer>,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchSettingsCopyWith<$Res> get settings {
  
  return $MatchSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [Match].
extension MatchPatterns on Match {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Match value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Match() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Match value)  $default,){
final _that = this;
switch (_that) {
case _Match():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Match value)?  $default,){
final _that = this;
switch (_that) {
case _Match() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String matchId,  String code,  MatchStatus status,  List<String> participants,  List<String> playerOrder,  String createdBy,  int createdAt,  int startedAt,  int endsAt,  MatchSettings settings,  Map<String, MatchPlayer> players,  String? winner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Match() when $default != null:
return $default(_that.matchId,_that.code,_that.status,_that.participants,_that.playerOrder,_that.createdBy,_that.createdAt,_that.startedAt,_that.endsAt,_that.settings,_that.players,_that.winner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String matchId,  String code,  MatchStatus status,  List<String> participants,  List<String> playerOrder,  String createdBy,  int createdAt,  int startedAt,  int endsAt,  MatchSettings settings,  Map<String, MatchPlayer> players,  String? winner)  $default,) {final _that = this;
switch (_that) {
case _Match():
return $default(_that.matchId,_that.code,_that.status,_that.participants,_that.playerOrder,_that.createdBy,_that.createdAt,_that.startedAt,_that.endsAt,_that.settings,_that.players,_that.winner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String matchId,  String code,  MatchStatus status,  List<String> participants,  List<String> playerOrder,  String createdBy,  int createdAt,  int startedAt,  int endsAt,  MatchSettings settings,  Map<String, MatchPlayer> players,  String? winner)?  $default,) {final _that = this;
switch (_that) {
case _Match() when $default != null:
return $default(_that.matchId,_that.code,_that.status,_that.participants,_that.playerOrder,_that.createdBy,_that.createdAt,_that.startedAt,_that.endsAt,_that.settings,_that.players,_that.winner);case _:
  return null;

}
}

}

/// @nodoc


class _Match extends Match {
  const _Match({required this.matchId, required this.code, required this.status, required final  List<String> participants, required final  List<String> playerOrder, required this.createdBy, required this.createdAt, required this.startedAt, required this.endsAt, required this.settings, required final  Map<String, MatchPlayer> players, this.winner}): _participants = participants,_playerOrder = playerOrder,_players = players,super._();
  

@override final  String matchId;
@override final  String code;
@override final  MatchStatus status;
 final  List<String> _participants;
@override List<String> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  List<String> _playerOrder;
@override List<String> get playerOrder {
  if (_playerOrder is EqualUnmodifiableListView) return _playerOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playerOrder);
}

@override final  String createdBy;
@override final  int createdAt;
@override final  int startedAt;
@override final  int endsAt;
@override final  MatchSettings settings;
 final  Map<String, MatchPlayer> _players;
@override Map<String, MatchPlayer> get players {
  if (_players is EqualUnmodifiableMapView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_players);
}

@override final  String? winner;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchCopyWith<_Match> get copyWith => __$MatchCopyWithImpl<_Match>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Match&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._participants, _participants)&&const DeepCollectionEquality().equals(other._playerOrder, _playerOrder)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other._players, _players)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode => Object.hash(runtimeType,matchId,code,status,const DeepCollectionEquality().hash(_participants),const DeepCollectionEquality().hash(_playerOrder),createdBy,createdAt,startedAt,endsAt,settings,const DeepCollectionEquality().hash(_players),winner);

@override
String toString() {
  return 'Match(matchId: $matchId, code: $code, status: $status, participants: $participants, playerOrder: $playerOrder, createdBy: $createdBy, createdAt: $createdAt, startedAt: $startedAt, endsAt: $endsAt, settings: $settings, players: $players, winner: $winner)';
}


}

/// @nodoc
abstract mixin class _$MatchCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$MatchCopyWith(_Match value, $Res Function(_Match) _then) = __$MatchCopyWithImpl;
@override @useResult
$Res call({
 String matchId, String code, MatchStatus status, List<String> participants, List<String> playerOrder, String createdBy, int createdAt, int startedAt, int endsAt, MatchSettings settings, Map<String, MatchPlayer> players, String? winner
});


@override $MatchSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$MatchCopyWithImpl<$Res>
    implements _$MatchCopyWith<$Res> {
  __$MatchCopyWithImpl(this._self, this._then);

  final _Match _self;
  final $Res Function(_Match) _then;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchId = null,Object? code = null,Object? status = null,Object? participants = null,Object? playerOrder = null,Object? createdBy = null,Object? createdAt = null,Object? startedAt = null,Object? endsAt = null,Object? settings = null,Object? players = null,Object? winner = freezed,}) {
  return _then(_Match(
matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,playerOrder: null == playerOrder ? _self._playerOrder : playerOrder // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as MatchSettings,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as Map<String, MatchPlayer>,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchSettingsCopyWith<$Res> get settings {
  
  return $MatchSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
