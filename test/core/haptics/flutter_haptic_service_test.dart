import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A recording seam standing in for the real platform vibration layer, so the
  // service is exercised with no plugin, no device, and no browser.
  late List<String> calls;
  FlutterHapticService build({bool hasVibrator = true}) {
    calls = <String>[];
    return FlutterHapticService(
      hasVibrator: () async => hasVibrator,
      vibrate: (int durationMs, {int amplitude = -1}) async {
        calls.add('vibrate:$durationMs:$amplitude');
      },
      vibratePattern: (List<int> pattern,
          {List<int> amplitudes = const <int>[]}) async {
        calls.add('pattern:${pattern.join(",")}');
      },
    );
  }

  test('a single-pulse impact drives the platform vibrate with its tuning',
      () async {
    final svc = build();
    await svc.lightImpact();
    expect(calls, ['vibrate:25:120']);
  });

  test('a multi-pulse impact drives the platform pattern call', () async {
    final svc = build();
    await svc.mistakeImpact();
    expect(calls.single, startsWith('pattern:'));
  });

  test('the new successPattern and tickImpact route through the service',
      () async {
    final svc = build();
    await svc.successPattern();
    await svc.tickImpact();
    expect(calls, hasLength(2));
    expect(calls.first, startsWith('pattern:')); // success is a pattern
    expect(calls.last, startsWith('vibrate:')); // tick is a single pulse
  });

  test('muted swallows every kind of feedback', () async {
    final svc = build()..setMuted(true);
    await svc.lightImpact();
    await svc.heavyImpact();
    await svc.streakImpact();
    await svc.successPattern();
    await svc.tickImpact();
    expect(calls, isEmpty);
  });

  test('unmuting restores feedback', () async {
    final svc = build()..setMuted(true);
    await svc.mediumImpact();
    expect(calls, isEmpty);
    svc.setMuted(false);
    await svc.mediumImpact();
    expect(calls, ['vibrate:40:180']);
  });

  // PLAN: if this case is flaky under the test binding (it touches
  // SystemChannels.platform through HapticFeedback), it may be dropped; the
  // injected-seam cases above fully cover mute and delegation. Keep the mutes.
  test('no vibrator takes the silent fallback and never calls platform vibrate',
      () async {
    // With no vibrator the service uses HapticFeedback, which is a harmless
    // no-op under the test binding. The injected platform vibrate must not fire.
    TestWidgetsFlutterBinding.ensureInitialized();
    final svc = build(hasVibrator: false);
    await svc.lightImpact();
    expect(calls, isEmpty);
  });
}
