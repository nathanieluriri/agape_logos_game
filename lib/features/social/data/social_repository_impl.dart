import 'package:uuid/uuid.dart';

import '../domain/friend_request_outcome.dart';
import '../domain/friends_snapshot.dart';
import '../domain/match_history_entry.dart';
import '../domain/public_profile.dart';
import '../domain/public_profile_detail.dart';
import 'social_remote.dart';
import 'social_repository.dart';

/// [SocialRepository] over the HTTP remote. Generates a fresh idempotency key per
/// mutation (the server dedupes replays of the same key, so a transport-level
/// retry is safe; distinct user taps get distinct keys). Pure passthrough for
/// reads.
class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SocialRemote _remote;
  final Uuid _uuid;

  @override
  Future<void> setPrivacy(bool isPublic) =>
      _remote.setPrivacy(isPublic, idempotencyKey: _uuid.v4());

  @override
  Future<List<PublicProfile>> searchUsers(String query) =>
      _remote.searchUsers(query);

  @override
  Future<PublicProfileDetail> publicProfile(String uid) =>
      _remote.publicProfile(uid);

  @override
  Future<FriendRequestOutcome> sendFriendRequest({
    String? toUid,
    String? handle,
  }) => _remote.sendFriendRequest(
    toUid: toUid,
    handle: handle,
    idempotencyKey: _uuid.v4(),
  );

  @override
  Future<bool> respondToFriendRequest({
    required String fromUid,
    required bool accept,
  }) => _remote.respondToFriendRequest(
    fromUid: fromUid,
    accept: accept,
    idempotencyKey: _uuid.v4(),
  );

  @override
  Future<FriendsSnapshot> friends() => _remote.friends();

  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) =>
      _remote.matchHistory(limit: limit);
}
