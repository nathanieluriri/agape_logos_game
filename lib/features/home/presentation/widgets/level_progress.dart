import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/opacities.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../application/home_controller.dart';

/// "Level N Completed!" label, an animated fill bar, and the "x / y" count.
class LevelProgress extends ConsumerWidget {
  const LevelProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          state.levelLabel,
          style: textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppRadii.pill,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.progressFraction),
            duration: AppDurations.slow,
            curve: AppCurves.emphasized,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: AppSpacing.sm,
              backgroundColor: scheme.surface.withValues(alpha: AppOpacities.scrimStrong),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.secondary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${state.progressDone} / ${state.progressTotal}',
          style: textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
        ),
      ],
    );
  }
}
