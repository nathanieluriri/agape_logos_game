import '../domain/friend_request_outcome.dart';
import '../domain/friends_snapshot.dart';
import '../domain/match_history_entry.dart';
import '../domain/public_profile.dart';
import '../domain/public_profile_detail.dart';

/// App-facing seam for the social layer. OnlineOnly (no Drift cache): friends,
/// search, privacy, and history are server-owned reads/writes.
abstract interface class SocialRepository {
  Future<void> setPrivacy(bool isPublic);
  Future<List<PublicProfile>> searchUsers(String query);
  Future<PublicProfileDetail> publicProfile(String uid);
  Future<FriendRequestOutcome> sendFriendRequest({
    String? toUid,
    String? handle,
  });
  Future<bool> respondToFriendRequest({
    required String fromUid,
    required bool accept,
  });
  Future<FriendsSnapshot> friends();
  Future<List<MatchHistoryEntry>> matchHistory({int? limit});
}
