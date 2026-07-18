import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a fresh clock is unsynced and trusts the device clock (zero offset)', () {
    final clock = ServerClock();
    expect(clock.isSynced, isFalse);
    expect(clock.offset, Duration.zero);
  });

  test('sync with no round trip behaves like the old serverNow - deviceNow offset', () {
    final clock = ServerClock();
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    // Pretend the server's clock is exactly 10s ahead of this device.
    clock.sync(deviceNowMs + 10000);
    expect(clock.isSynced, isTrue);
    // No round trip supplied: offset should land within a small scheduling
    // tolerance of the naive +10000ms delta (sync() reads DateTime.now()
    // again internally, a few ms after deviceNowMs was captured above).
    expect(clock.offset.inMilliseconds, inInclusiveRange(9900, 10100));
  });

  // Issue #58: sync() must apply Cristian's algorithm, estimating the
  // server's true clock at receipt as `serverNow + roundTrip / 2` rather than
  // treating serverNow as if it landed instantly. A known serverNow plus a
  // known, injected round trip must yield an offset shifted by roughly half
  // that round trip versus the uncorrected case.
  test('sync with a known round trip applies the half-RTT correction', () {
    final clock = ServerClock();
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    // Server clock reads exactly level with this device at the moment it
    // handled the request; the response then took 200ms round trip to
    // arrive back.
    clock.sync(deviceNowMs, roundTrip: const Duration(milliseconds: 200));
    // Corrected server time at receipt = serverNow + 100ms, so the offset
    // should read ~+100ms (server ahead), not ~0ms as an uncorrected sync
    // would compute.
    expect(clock.offset.inMilliseconds, inInclusiveRange(80, 120));
  });

  test('a larger round trip shifts the offset by proportionally more', () {
    final clock = ServerClock();
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    clock.sync(deviceNowMs, roundTrip: const Duration(milliseconds: 900));
    // Half of 900ms = 450ms.
    expect(clock.offset.inMilliseconds, inInclusiveRange(420, 480));
  });

  test('now() reflects the corrected offset', () {
    final clock = ServerClock();
    final deviceNowMs = DateTime.now().millisecondsSinceEpoch;
    clock.sync(deviceNowMs + 5000, roundTrip: const Duration(milliseconds: 100));
    // Expected offset ~= 5000 + 50 = 5050ms.
    final delta = clock.now().millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    expect(delta, inInclusiveRange(4950, 5150));
  });
}
