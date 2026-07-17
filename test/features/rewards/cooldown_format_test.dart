import 'package:agape_logos_game/features/rewards/presentation/cooldown_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCooldown', () {
    test('days and hours for long waits', () {
      expect(
        formatCooldown(const Duration(days: 2, hours: 5, minutes: 30)),
        '2d 05h',
      );
    });

    test('hours and minutes under a day', () {
      expect(
        formatCooldown(const Duration(hours: 5, minutes: 12, seconds: 9)),
        '5h 12m',
      );
    });

    test('minutes and seconds under an hour', () {
      expect(formatCooldown(const Duration(minutes: 12, seconds: 30)), '12m 30s');
    });

    test('seconds only under a minute', () {
      expect(formatCooldown(const Duration(seconds: 30)), '30s');
    });

    test('zero and negative collapse to a moment', () {
      expect(formatCooldown(Duration.zero), 'a moment');
      expect(formatCooldown(const Duration(seconds: -5)), 'a moment');
    });

    test('formatCooldownMs converts from milliseconds', () {
      expect(formatCooldownMs(3 * 60 * 60 * 1000), '3h 00m');
    });
  });
}
