import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_providers.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/social_firestore.dart';
import '../data/social_remote.dart';
import '../data/social_repository.dart';
import '../data/social_repository_impl.dart';
import '../domain/friend.dart';
import '../domain/friend_request.dart';
import '../domain/friend_request_outcome.dart';
import '../domain/match_history_entry.dart';
import '../domain/public_profile.dart';
import '../domain/public_profile_detail.dart';

final socialRemoteProvider = Provider<SocialRemote>(
  (ref) => HttpSocialRemote(ref.watch(apiClientProvider)),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepositoryImpl(ref.watch(socialRemoteProvider)),
);

/// The Firestore READ layer for friends + incoming requests. Reads only; the
/// send / accept / decline writes still go through [socialRepositoryProvider].
final socialFirestoreProvider = Provider<SocialFirestore>(
  (ref) => SocialFirestore(ref.watch(firebaseFirestoreProvider)),
);

/// Incoming friend requests, live over a Firestore listener (no polling).
///
/// AUTH-GATED like the match listeners: while auth is still restoring the
/// persisted user we emit an empty stream rather than attaching a listener. A
/// listener attached before the user is known is denied by the security rules
/// and dies permanently (never retries), which on web reads as an empty inbox
/// forever. Once auth settles the provider rebuilds and attaches for real.
final liveFriendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return const Stream<List<FriendRequest>>.empty();
  final user = auth.value;
  if (user == null) return Stream.value(const <FriendRequest>[]);
  return ref.watch(socialFirestoreProvider).watchRequests(user.uid);
});

/// Accepted friends, live over a Firestore listener. Auth-gated as above.
final liveFriendsProvider = StreamProvider<List<Friend>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return const Stream<List<Friend>>.empty();
  final user = auth.value;
  if (user == null) return Stream.value(const <Friend>[]);
  return ref.watch(socialFirestoreProvider).watchFriends(user.uid);
});

/// The pending-request count for the Friends button badge.
final pendingRequestCountProvider = Provider<int>(
  (ref) => ref.watch(liveFriendRequestsProvider).value?.length ?? 0,
);

/// The accepted friends list (empty while loading / on error).
final friendsProvider = Provider<List<Friend>>(
  (ref) => ref.watch(liveFriendsProvider).value ?? const <Friend>[],
);

/// Incoming pending friend requests (empty while loading / on error).
final friendRequestsProvider = Provider<List<FriendRequest>>(
  (ref) => ref.watch(liveFriendRequestsProvider).value ?? const <FriendRequest>[],
);

/// `GET /me/matches`. Invalidate to refresh.
final matchHistoryProvider = FutureProvider<List<MatchHistoryEntry>>(
  (ref) => ref.watch(socialRepositoryProvider).matchHistory(),
);

/// OnlineOnly friend search over a trimmed query. An empty query short-circuits
/// to an empty list (no network call), so the field can watch it live.
final userSearchProvider = FutureProvider.family<List<PublicProfile>, String>((
  ref,
  query,
) {
  final q = query.trim();
  if (q.isEmpty) {
    return Future<List<PublicProfile>>.value(const <PublicProfile>[]);
  }
  return ref.watch(socialRepositoryProvider).searchUsers(q);
});

/// `GET /users/:uid/public`. Throws `ProfileNotVisible` for a private target,
/// which the page surfaces as a "private profile" state.
final publicProfileProvider = FutureProvider.family<PublicProfileDetail, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).publicProfile(uid),
  // Riverpod 3 retries failed providers by default, and a retrying provider
  // reports `AsyncLoading` (carrying the previous error), never `AsyncError`.
  // `ProfileNotVisible` is the server's terminal answer for a private or
  // missing profile (403/404), so retrying it would leave the page stuck on the
  // loading branch forever instead of showing the "private" state. Retry only
  // genuinely transient failures, and only a few times.
  retry: (retryCount, error) {
    if (error is ProfileNotVisible) return null;
    if (retryCount >= 3) return null;
    return Duration(milliseconds: 200 * (1 << retryCount));
  },
);

/// The "make my profile public" flag. Reads the authoritative value from the
/// server profile (`GET /me`) on build, then flips optimistically on toggle and
/// reverts if the `PUT /me/privacy` write fails.
class ProfilePrivacyController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;
    try {
      final profile = await ref.read(profileRemoteProvider).me();
      return profile.public;
    } catch (_) {
      // Offline or any other failure: default to the private-safe value so the
      // switch stays usable. Catching everything (not just DioException) matters
      // because Riverpod 3 retries a failed provider, and a retrying provider
      // reports AsyncLoading forever, which would leave the switch spinning.
      return false;
    }
  }

  Future<void> setPublic(bool value) async {
    final bool previous = state.value ?? false;
    state = AsyncData<bool>(value); // optimistic
    try {
      await ref.read(socialRepositoryProvider).setPrivacy(value);
    } catch (_) {
      state = AsyncData<bool>(previous); // revert on failure
    }
  }
}

final profilePrivacyControllerProvider =
    AsyncNotifierProvider<ProfilePrivacyController, bool>(
      ProfilePrivacyController.new,
    );

/// Tracks in-flight friend actions by a target id (uid / handle / fromUid) so
/// each tile disables only its own button while its request is out.
class FriendActionsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isBusy(String id) => state.contains(id);

  /// Sends a friend request; returns the typed outcome for a snack. Signed-out
  /// callers get [FriendRequestUnavailable] without a network call.
  Future<FriendRequestOutcome> sendRequest({
    String? toUid,
    String? handle,
  }) async {
    final String id = toUid ?? handle ?? '';
    if (ref.read(currentUserProvider) == null) {
      return const FriendRequestUnavailable();
    }
    state = <String>{...state, id};
    try {
      return await ref
          .read(socialRepositoryProvider)
          .sendFriendRequest(toUid: toUid, handle: handle);
    } finally {
      state = <String>{...state}..remove(id);
    }
  }

  /// Accepts or declines a request. The live listeners already reflect the
  /// server write within a moment; the explicit re-subscribe just gives an
  /// immediate kick so the list and the request badge update at once.
  Future<bool> respond({required String fromUid, required bool accept}) async {
    state = <String>{...state, fromUid};
    try {
      final ok = await ref
          .read(socialRepositoryProvider)
          .respondToFriendRequest(fromUid: fromUid, accept: accept);
      if (ok) {
        ref.invalidate(liveFriendsProvider);
        ref.invalidate(liveFriendRequestsProvider);
      }
      return ok;
    } finally {
      state = <String>{...state}..remove(fromUid);
    }
  }
}

final friendActionsControllerProvider =
    NotifierProvider<FriendActionsController, Set<String>>(
      FriendActionsController.new,
    );
