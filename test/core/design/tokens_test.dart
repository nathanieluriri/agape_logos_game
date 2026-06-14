import 'package:agape_logos_game/core/design/tokens/spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spacing scale is strictly increasing', () {
    const scale = <double>[
      AppSpacing.xxs,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
    ];
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]));
    }
  });
}
