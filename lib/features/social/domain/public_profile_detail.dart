import 'match_history_entry.dart';
import 'public_profile.dart';

/// The `GET /users/:uid/public` payload: the projection + recent matches.
class PublicProfileDetail {
  const PublicProfileDetail({required this.profile, required this.recentMatches});

  final PublicProfile profile;
  final List<MatchHistoryEntry> recentMatches;
}
