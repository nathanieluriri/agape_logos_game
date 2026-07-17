// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchEvent {

 String get id; int get at; String get byUid; String get targetUid; MatchEventKind get kind; Map<String, dynamic> get payload; int get expiresAt;
/// Create a copy of MatchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchEventCopyWith<MatchEvent> get copyWith => _$MatchEventCopyWithImpl<MatchEvent>(this as MatchEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.at, at) || other.at == at)&&(identical(other.byUid, byUid) || other.byUid == byUid)&&(identical(other.targetUid, targetUid) || other.targetUid == targetUid)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,at,byUid,targetUid,kind,const DeepCollectionEquality().hash(payload),expiresAt);

@override
String toString() {
  return 'MatchEvent(id: $id, at: $at, byUid: $byUid, targetUid: $targetUid, kind: $kind, payload: $payload, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $MatchEventCopyWith<$Res>  {
  factory $MatchEventCopyWith(MatchEvent value, $Res Function(MatchEvent) _then) = _$MatchEventCopyWithImpl;
@useResult
$Res call({
 String id, int at, String byUid, String targetUid, MatchEventKind kind, Map<String, dynamic> payload, int expiresAt
});




}
/// @nodoc
class _$MatchEventCopyWithImpl<$Res>
    implements $MatchEventCopyWith<$Res> {
  _$MatchEventCopyWithImpl(this._self, this._then);

  final MatchEvent _self;
  final $Res Function(MatchEvent) _then;

/// Create a copy of MatchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? at = null,Object? byUid = null,Object? targetUid = null,Object? kind = null,Object? payload = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,byUid: null == byUid ? _self.byUid : byUid // ignore: cast_nullable_to_non_nullable
as String,targetUid: null == targetUid ? _self.targetUid : targetUid // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MatchEventKind,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchEvent].
extension MatchEventPatterns on MatchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchEvent value)  $default,){
final _that = this;
switch (_that) {
case _MatchEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchEvent value)?  $default,){
final _that = this;
switch (_that) {
case _MatchEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int at,  String byUid,  String targetUid,  MatchEventKind kind,  Map<String, dynamic> payload,  int expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchEvent() when $default != null:
return $default(_that.id,_that.at,_that.byUid,_that.targetUid,_that.kind,_that.payload,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int at,  String byUid,  String targetUid,  MatchEventKind kind,  Map<String, dynamic> payload,  int expiresAt)  $default,) {final _that = this;
switch (_that) {
case _MatchEvent():
return $default(_that.id,_that.at,_that.byUid,_that.targetUid,_that.kind,_that.payload,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int at,  String byUid,  String targetUid,  MatchEventKind kind,  Map<String, dynamic> payload,  int expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchEvent() when $default != null:
return $default(_that.id,_that.at,_that.byUid,_that.targetUid,_that.kind,_that.payload,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _MatchEvent extends MatchEvent {
  const _MatchEvent({required this.id, required this.at, required this.byUid, required this.targetUid, required this.kind, required final  Map<String, dynamic> payload, required this.expiresAt}): _payload = payload,super._();
  

@override final  String id;
@override final  int at;
@override final  String byUid;
@override final  String targetUid;
@override final  MatchEventKind kind;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  int expiresAt;

/// Create a copy of MatchEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchEventCopyWith<_MatchEvent> get copyWith => __$MatchEventCopyWithImpl<_MatchEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.at, at) || other.at == at)&&(identical(other.byUid, byUid) || other.byUid == byUid)&&(identical(other.targetUid, targetUid) || other.targetUid == targetUid)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,at,byUid,targetUid,kind,const DeepCollectionEquality().hash(_payload),expiresAt);

@override
String toString() {
  return 'MatchEvent(id: $id, at: $at, byUid: $byUid, targetUid: $targetUid, kind: $kind, payload: $payload, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$MatchEventCopyWith<$Res> implements $MatchEventCopyWith<$Res> {
  factory _$MatchEventCopyWith(_MatchEvent value, $Res Function(_MatchEvent) _then) = __$MatchEventCopyWithImpl;
@override @useResult
$Res call({
 String id, int at, String byUid, String targetUid, MatchEventKind kind, Map<String, dynamic> payload, int expiresAt
});




}
/// @nodoc
class __$MatchEventCopyWithImpl<$Res>
    implements _$MatchEventCopyWith<$Res> {
  __$MatchEventCopyWithImpl(this._self, this._then);

  final _MatchEvent _self;
  final $Res Function(_MatchEvent) _then;

/// Create a copy of MatchEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? at = null,Object? byUid = null,Object? targetUid = null,Object? kind = null,Object? payload = null,Object? expiresAt = null,}) {
  return _then(_MatchEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,byUid: null == byUid ? _self.byUid : byUid // ignore: cast_nullable_to_non_nullable
as String,targetUid: null == targetUid ? _self.targetUid : targetUid // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MatchEventKind,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
