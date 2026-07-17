// lib/features/level_complete/presentation/widgets/level_progress_bar.dart
import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/lotus_bloom.dart';
import '../../../../shared/widgets/pond_progress_track.dart';

/// "Level N Completed!" label, a premium lime-gold track that fills to the real
/// fraction, and the serif "X/Y" numeral that counts up in lock-step. A full
/// clear pops a lotus bloom at the fill's leading edge. Used only on the
/// level-complete page.
class LevelProgressBar extends StatefulWidget {
  const LevelProgressBar({
    super.key,
    required this.label,
    required this.wordsFound,
    required this.totalWords,
  });

  final String label;
  final int wordsFound;
  final int totalWords;

  @override
  State<LevelProgressBar> createState() => _LevelProgressBarState();
}

class _LevelProgressBarState extends State<LevelProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _fill,
    curve: AppCurves.emphasized,
  );

  bool _reduceMotion = false;

  double get _target => widget.totalWords == 0
      ? 0
      : (widget.wordsFound / widget.totalWords).clamp(0.0, 1.0);

  bool get _isFullClear =>
      widget.totalWords > 0 && widget.wordsFound >= widget.totalWords;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _fill.value = 1.0; // Show the final state at once.
    } else if (_fill.status == AnimationStatus.dismissed) {
      _fill.forward();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final v = _curve.value;
            final filled = v * target;
            // Bloom once, when a full clear reaches the end of the fill.
            // PLAN: today only a FULL clear blooms (the celebratory case).
            // Decide on-device whether a partial clear deserves a smaller
            // accent; if so, drop the _isFullClear gate and scale by target.
            final showBloom = !_reduceMotion && _isFullClear && v >= 0.999;
            return SizedBox(
              width: AppSizing.progressTrackWidth,
              height: AppSizing.progressTrackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  PondProgressTrack(fraction: filled),
                  if (showBloom)
                    Positioned(
                      // Centre the bloom on the fill's leading edge.
                      left:
                          (filled * AppSizing.progressTrackWidth -
                                  AppSizing.loaderBloom / 2)
                              .clamp(
                                -AppSizing.loaderBloom / 2,
                                AppSizing.progressTrackWidth -
                                    AppSizing.loaderBloom / 2,
                              ),
                      top:
                          (AppSizing.progressTrackHeight -
                              AppSizing.loaderBloom) /
                          2,
                      child: const LotusBloom(),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final shown = (_curve.value * widget.wordsFound).round();
            return Text(
              '$shown/${widget.totalWords}',
              style: AppTypography.numeral.copyWith(
                color: AppColors.progressFraction,
              ),
            );
          },
        ),
      ],
    );
  }
}
