import 'friend.dart';
import 'friend_request.dart';

/// The `GET /friends` payload: accepted friends + incoming pending requests.
class FriendsSnapshot {
  const FriendsSnapshot({required this.friends, required this.requests});

  final List<Friend> friends;
  final List<FriendRequest> requests;

  static const empty = FriendsSnapshot(friends: [], requests: []);
}
