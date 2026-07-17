// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Friend {

 String get uid; String get handle; String get displayName; String get avatarId; int get since;
/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendCopyWith<Friend> get copyWith => _$FriendCopyWithImpl<Friend>(this as Friend, _$identity);

  /// Serializes this Friend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friend&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.since, since) || other.since == since));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,handle,displayName,avatarId,since);

@override
String toString() {
  return 'Friend(uid: $uid, handle: $handle, displayName: $displayName, avatarId: $avatarId, since: $since)';
}


}

/// @nodoc
abstract mixin class $FriendCopyWith<$Res>  {
  factory $FriendCopyWith(Friend value, $Res Function(Friend) _then) = _$FriendCopyWithImpl;
@useResult
$Res call({
 String uid, String handle, String displayName, String avatarId, int since
});




}
/// @nodoc
class _$FriendCopyWithImpl<$Res>
    implements $FriendCopyWith<$Res> {
  _$FriendCopyWithImpl(this._self, this._then);

  final Friend _self;
  final $Res Function(Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? handle = null,Object? displayName = null,Object? avatarId = null,Object? since = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Friend].
extension FriendPatterns on Friend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friend value)  $default,){
final _that = this;
switch (_that) {
case _Friend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friend value)?  $default,){
final _that = this;
switch (_that) {
case _Friend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String handle,  String displayName,  String avatarId,  int since)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.uid,_that.handle,_that.displayName,_that.avatarId,_that.since);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String handle,  String displayName,  String avatarId,  int since)  $default,) {final _that = this;
switch (_that) {
case _Friend():
return $default(_that.uid,_that.handle,_that.displayName,_that.avatarId,_that.since);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String handle,  String displayName,  String avatarId,  int since)?  $default,) {final _that = this;
switch (_that) {
case _Friend() when $default != null:
return $default(_that.uid,_that.handle,_that.displayName,_that.avatarId,_that.since);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Friend implements Friend {
  const _Friend({required this.uid, required this.handle, required this.displayName, required this.avatarId, this.since = 0});
  factory _Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);

@override final  String uid;
@override final  String handle;
@override final  String displayName;
@override final  String avatarId;
@override@JsonKey() final  int since;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendCopyWith<_Friend> get copyWith => __$FriendCopyWithImpl<_Friend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friend&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.since, since) || other.since == since));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,handle,displayName,avatarId,since);

@override
String toString() {
  return 'Friend(uid: $uid, handle: $handle, displayName: $displayName, avatarId: $avatarId, since: $since)';
}


}

/// @nodoc
abstract mixin class _$FriendCopyWith<$Res> implements $FriendCopyWith<$Res> {
  factory _$FriendCopyWith(_Friend value, $Res Function(_Friend) _then) = __$FriendCopyWithImpl;
@override @useResult
$Res call({
 String uid, String handle, String displayName, String avatarId, int since
});




}
/// @nodoc
class __$FriendCopyWithImpl<$Res>
    implements _$FriendCopyWith<$Res> {
  __$FriendCopyWithImpl(this._self, this._then);

  final _Friend _self;
  final $Res Function(_Friend) _then;

/// Create a copy of Friend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? handle = null,Object? displayName = null,Object? avatarId = null,Object? since = null,}) {
  return _then(_Friend(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
