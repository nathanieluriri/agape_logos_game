/// Tracks the offset between this device's clock and the server's, so effect
/// expiries (server-authored epoch millis) compare correctly even when the
/// device clock is skewed. Fed by `serverNow` on every powerup/match response
/// (contract update: server clock).
///
/// Offset is zero until the first [sync]: a never-synced client trusts its own
/// clock rather than guessing.
class ServerClock {
  Duration _offset = Duration.zero;
  bool _synced = false;

  /// Records the server's clock at the moment its response was received,
  /// corrected for the request's round trip (issue #58). `serverNowMs` is the
  /// server's clock reading at the instant it handled the request, not at the
  /// instant this device receives the response, so treating it as "now" biases
  /// the offset by roughly one downlink hop. [roundTrip] is the caller-measured
  /// request latency (time from firing the request to receiving this
  /// response); Cristian's algorithm estimates the server's clock at receipt
  /// as `serverNowMs + roundTrip / 2`, assuming symmetric up/down latency.
  void sync(int serverNowMs, {Duration roundTrip = Duration.zero}) {
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    final correctedServerNowMs = serverNowMs + roundTrip.inMilliseconds ~/ 2;
    _offset = Duration(milliseconds: correctedServerNowMs - deviceNowMs);
    _synced = true;
  }

  /// Device now, corrected by the last known [offset].
  DateTime now() => DateTime.now().add(_offset);

  Duration get offset => _offset;

  /// Whether [sync] has ever landed. Lets a caller (the match page, on load)
  /// tell a genuinely never-synced clock apart from one that just happens to
  /// carry a zero offset, so it knows whether a dedicated sync is still owed.
  bool get isSynced => _synced;
}
