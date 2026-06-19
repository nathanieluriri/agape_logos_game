import 'package:flutter/material.dart';

import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// Currency display: a placeholder petal icon, an animated count-up of [amount],
/// and an optional `+` button. Icon art is a stand-in (no lotus).
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({super.key, required this.amount, this.onAdd});

  final int amount;
  final VoidCallback? onAdd;

  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.18),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placeholder currency icon (swap for the petal art later).
          Icon(Icons.spa_outlined, size: AppSpacing.md, color: scheme.onPrimary),
          const SizedBox(width: AppSpacing.xs),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: amount),
            duration: AppDurations.slow,
            builder: (context, value, _) => Text(
              _grouped(value),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.onPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onAdd,
            child: Icon(Icons.add_circle, color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}
