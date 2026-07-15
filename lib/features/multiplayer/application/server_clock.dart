/// Tracks the offset between this device's clock and the server's, so effect
/// expiries (server-authored epoch millis) compare correctly even when the
/// device clock is skewed. Fed by `serverNow` on every powerup/match response
/// (contract update: server clock).
///
/// Offset is zero until the first [sync]: a never-synced client trusts its own
/// clock rather than guessing.
class ServerClock {
  Duration _offset = Duration.zero;

  /// Records the server's clock at the moment its response was received.
  void sync(int serverNowMs) {
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    _offset = Duration(milliseconds: serverNowMs - deviceNowMs);
  }

  /// Device now, corrected by the last known [offset].
  DateTime now() => DateTime.now().add(_offset);

  Duration get offset => _offset;
}
