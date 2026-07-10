/// The result of sending a friend request, mapped from the endpoint's status so
/// the UI can show a precise message without inspecting HTTP codes.
sealed class FriendRequestOutcome {
  const FriendRequestOutcome();
}

/// 200: request created (or already friends / already pending, idempotent).
class FriendRequestSent extends FriendRequestOutcome {
  const FriendRequestSent();
}

/// 404: no user for that uid / handle.
class FriendRequestUserNotFound extends FriendRequestOutcome {
  const FriendRequestUserNotFound();
}

/// 400: invalid target (e.g. yourself) or malformed input.
class FriendRequestInvalid extends FriendRequestOutcome {
  const FriendRequestInvalid();
}

/// Offline, signed out, or a server/transport error: not sent, try later.
class FriendRequestUnavailable extends FriendRequestOutcome {
  const FriendRequestUnavailable();
}
