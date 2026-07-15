import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../social/application/social_providers.dart';
import '../domain/active_match.dart';
import '../domain/challenge_invite.dart';
import 'match_providers.dart';

/// Incoming friend challenges, live over a Firestore listener (no polling).
///
/// AUTH-GATED exactly like the friend-request listener: while auth is still
/// restoring the persisted user we emit an empty stream rather than attaching a
/// listener. A listener attached before the user is known is denied by the
/// security rules and dies permanently (never retries), which on web reads as
/// an empty inbox forever. Once auth settles the provider rebuilds and attaches.
final incomingChallengesProvider = StreamProvider<List<ChallengeInvite>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return const Stream<List<ChallengeInvite>>.empty();
  final user = auth.value;
  if (user == null) return Stream.value(const <ChallengeInvite>[]);
  return ref.watch(socialFirestoreProvider).watchChallenges(user.uid);
});

/// `GET /me/matches/active`: the player's in-progress matches. Invalidate to
/// refresh (the Resume list pulls to reload).
final activeMatchesProvider = FutureProvider<List<ActiveMatch>>(
  (ref) => ref.watch(matchServiceProvider).activeMatches(),
);

/// Tracks in-flight challenge responses by matchId so each invite tile disables
/// only its own Accept/Decline buttons while its response is out.
class ChallengeActionsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isBusy(String matchId) => state.contains(matchId);

  /// Accepts or declines an incoming challenge. Returns true on success.
  Future<bool> respond(String matchId, {required bool accept}) async {
    state = <String>{...state, matchId};
    try {
      await ref
          .read(matchServiceProvider)
          .respondChallenge(matchId, accept: accept);
      // An accepted challenge becomes an in-progress game, so refresh the
      // one-shot active-matches list; otherwise the accepted match would not
      // appear under "Your games" until a manual pull-to-refresh.
      if (accept) ref.invalidate(activeMatchesProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = <String>{...state}..remove(matchId);
    }
  }
}

final challengeActionsControllerProvider =
    NotifierProvider<ChallengeActionsController, Set<String>>(
      ChallengeActionsController.new,
    );
