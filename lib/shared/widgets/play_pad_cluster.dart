import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/elevation.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'glyphs/pond_glyph.dart';
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

  /// The icon widget shown on the secondary pad (e.g. a [FilmPlayIcon] or a
  /// filled Material [Icon]).
  final Widget secondaryIcon;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizing.playAreaHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Play pad: lower-left of the cluster, notch pointing up-left.
          Align(
            alignment: const Alignment(-0.5, 0.55),
            child: LilyPadButton(
              size: AppSizing.playPad,
              rotationDegrees: -135,
              palette: LilyPadPalette.green,
              phase: PadElevation.playPhase,
              semanticLabel: 'Play $nextLabel',
              onPressed: onPlay,
              content: _PlayContent(label: nextLabel),
            ),
          ),
          // Secondary pad: a smooth blue pad floating up and to the right.
          Align(
            alignment: const Alignment(0.72, -0.72),
            child: LilyPadButton(
              size: AppSizing.secondaryPad,
              shape: PadShape.smooth,
              rotationDegrees: 25,
              palette: LilyPadPalette.bonusBlue,
              // PLAN: the two pads share PadElevation.bobAmplitude. The
              // secondary pad is smaller, so an identical 7px bob is
              // proportionally larger on it. If it bobs too eagerly on device,
              // add an optional amplitude passthrough to LilyPadButton.
              phase: PadElevation.secondaryPhase,
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
        // Nudged right: a play triangle only looks centered when its visual
        // mass (not its bounding box) sits in the middle of the pad.
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs),
          child: PondIcon(PondGlyph.play, size: 52),
        ),
        const SizedBox(height: AppSpacing.sm),
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
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
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
