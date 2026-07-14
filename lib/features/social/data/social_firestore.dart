import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/friend.dart';
import '../domain/friend_request.dart';

/// The Firestore READ layer for social: the two user-scoped listeners that make
/// incoming friend requests and the friends list arrive live, without polling.
/// Writes never happen here (send / accept / decline still go through the HTTP
/// controller); the rules allow a user to read only their own subcollections.
///
/// The docs store `at` / `since` as Firestore [Timestamp]s, but the Dart models
/// carry epoch millis (`int`). The mappers below read each field explicitly and
/// convert by hand, so a raw doc never flows through `fromJson` (which would
/// throw on the Timestamp).
class SocialFirestore {
  SocialFirestore(this._db);

  final FirebaseFirestore _db;

  /// Incoming pending friend requests for [uid], newest first.
  Stream<List<FriendRequest>> watchRequests(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('friendRequests')
      .orderBy('at', descending: true)
      .snapshots()
      .map((q) => q.docs.map(_requestFrom).toList());

  /// Accepted friends for [uid], newest first.
  Stream<List<Friend>> watchFriends(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('friends')
      .orderBy('since', descending: true)
      .snapshots()
      .map((q) => q.docs.map(_friendFrom).toList());

  FriendRequest _requestFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return FriendRequest(
      fromUid: (data['fromUid'] as String?) ?? doc.id,
      handle: (data['handle'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      avatarId: (data['avatarId'] as String?) ?? '',
      at: (data['at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
    );
  }

  Friend _friendFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Friend(
      uid: (data['uid'] as String?) ?? doc.id,
      handle: (data['handle'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      avatarId: (data['avatarId'] as String?) ?? '',
      since: (data['since'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
    );
  }
}
