import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// Replaces the reference "Bonus Gift" affordance. A rounded button that idly
/// bobs to stay alive. Action is a placeholder sheet (wired by HomePage).
class WithdrawGiftButton extends StatefulWidget {
  const WithdrawGiftButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<WithdrawGiftButton> createState() => _WithdrawGiftButtonState();
}

class _WithdrawGiftButtonState extends State<WithdrawGiftButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -AppSpacing.xs * AppCurves.enter.transform(_bob.value)),
        child: child,
      ),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: AppRadii.pill,
        child: InkWell(
          borderRadius: AppRadii.pill,
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: scheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Withdraw Gift',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
