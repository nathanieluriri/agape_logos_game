import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'lily_pad.dart';
import 'lily_pad_button.dart';

/// The floating play cluster shared by the home and level-complete pages:
/// a green Play pad centered, with a teal secondary pad floating up and to the
/// right. The secondary pad is Withdraw on home and Bonus Gift on level-complete.
class PlayPadCluster extends StatelessWidget {
  const PlayPadCluster({
    super.key,
    required this.nextLabel,
    required this.onPlay,
    required this.secondaryIcon,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String nextLabel;
  final VoidCallback onPlay;
  final IconData secondaryIcon;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizing.playAreaHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LilyPadButton(
            size: AppSizing.playPad,
            rotationDegrees: 20,
            palette: LilyPadPalette.green,
            semanticLabel: 'Play $nextLabel',
            onPressed: onPlay,
            content: _PlayContent(label: nextLabel),
          ),
          Positioned(
            right: 4,
            top: 8,
            child: LilyPadButton(
              size: AppSizing.secondaryPad,
              rotationDegrees: -15,
              palette: LilyPadPalette.teal,
              idle: IdleMotion.bob,
              semanticLabel: secondaryLabel,
              onPressed: onSecondary,
              content: _SecondaryContent(icon: secondaryIcon, label: secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayContent extends StatelessWidget {
  const _PlayContent({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow_rounded,
            size: 56, color: AppColors.playTriangle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SecondaryContent extends StatelessWidget {
  const _SecondaryContent({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: AppColors.padLabel),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
