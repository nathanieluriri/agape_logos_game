// lib/shared/widgets/coin_pill.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';

/// Currency chip: a pink petal coin over a translucent pill with the
/// animated count-up amount and a round plus button.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.amount, this.onAdd});

  final int amount;
  final VoidCallback? onAdd;

  static String _grouped(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.xl + AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.pillFill,
            borderRadius: AppRadii.pill,
            border: Border.all(color: AppColors.pillBorder),
            boxShadow: AppShadows.pill,
          ),
          child: TweenAnimationBuilder<int>(
            duration: AppDurations.slow,
            tween: IntTween(begin: 0, end: amount),
            builder: (context, value, _) => Text(
              _grouped(value),
              style: const TextStyle(
                color: AppColors.pillText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: -18,
          top: -4,
          child: Transform.rotate(
            angle: -0.384, // ~ -22 degrees
            child: SvgPicture.asset(
              'assets/branding/coin_petal.svg',
              width: AppSizing.coinPetal,
            ),
          ),
        ),
        Positioned(
          right: 3,
          child: Semantics(
            button: true,
            label: 'Add coins',
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.plusButton,
                ),
                child: const ExcludeSemantics(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: AppColors.padLabel,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
