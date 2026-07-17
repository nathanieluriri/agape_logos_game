/// Outcome of an outgoing challenge (POST /matches/challenge).
sealed class ChallengeOutcome {
  const ChallengeOutcome();
}

/// The challenge was created; the friend now has an open invite.
class ChallengeSent extends ChallengeOutcome {
  const ChallengeSent(this.matchId);
  final String matchId;
}

/// 409: an open match with this friend already exists.
class ChallengeAlreadyOpen extends ChallengeOutcome {
  const ChallengeAlreadyOpen();
}

/// 404: the target uid is not a friend.
class ChallengeNotFriends extends ChallengeOutcome {
  const ChallengeNotFriends();
}

/// Offline or any other failure reaching the server.
class ChallengeUnavailable extends ChallengeOutcome {
  const ChallengeUnavailable();
}
