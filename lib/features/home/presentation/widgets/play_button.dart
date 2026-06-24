import 'package:flutter/material.dart';

import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The primary Play affordance on a placeholder lily-pad shape. Breathes while
/// idle and scales down on press. Lily-pad art is a stand-in.
class PlayButton extends StatefulWidget {
  const PlayButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
    lowerBound: 0.97,
    upperBound: 1.03,
  )..repeat(reverse: true);

  bool _pressed = false;

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppDurations.instant,
        child: ScaleTransition(
          scale: _breathe,
          child: Container(
            width: AppSpacing.xxl * 3,
            height: AppSpacing.xxl * 3,
            decoration: BoxDecoration(
              // Placeholder lily-pad shape.
              color: scheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: AppSpacing.xxl,
                  color: scheme.onTertiaryContainer,
                ),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onTertiaryContainer,
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
