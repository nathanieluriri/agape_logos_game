/// Result of an attempt to claim/change the player's @handle via `PUT /me/handle`.
/// The handle claim is an online, server-authoritative write: the server can
/// reject it (someone else already holds it), so the outcome is a sealed type
/// the UI switches on rather than an optimistic success.
sealed class HandleOutcome {
  const HandleOutcome();
}

/// The server accepted the handle; [handle] is the value it stored.
class HandleChanged extends HandleOutcome {
  const HandleChanged(this.handle);
  final String handle;
}

/// 409: someone else already holds this handle.
class HandleTaken extends HandleOutcome {
  const HandleTaken();
}

/// 400: the handle failed the server's validation regex.
class HandleInvalid extends HandleOutcome {
  const HandleInvalid();
}

/// Any other failure (offline, timeout, 5xx, etc). Never a DioException.
class HandleUnavailable extends HandleOutcome {
  const HandleUnavailable();
}
