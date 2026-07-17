import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/play_flow.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/lily_pad_button.dart';
import '../../../../shared/widgets/versus_mark.dart';

/// The Home "Versus" pad: a coral lily pad that opens multiplayer matchmaking.
/// Auth-gated (guests are signed in first) via [startMultiplayerFlow].
///
/// Idle motion comes from plan 05's FloatMotion (LilyPadButton delegates to it);
/// a quarter-cycle phase keeps this pad visibly out of sync with the cluster.
class MultiplayerPad extends ConsumerWidget {
  const MultiplayerPad({super.key});

  /// Bob phase offset so the Versus pad floats out of sync with the play
  /// cluster's pads (0 and 0.5).
  // PLAN: eyeball on device; tune the phase (or add a PadElevation token) if
  // the three home pads read as synchronized.
  static const double _phase = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LilyPadButton(
      size: AppSizing.secondaryPad,
      shape: PadShape.smooth,
      rotationDegrees: -20,
      palette: LilyPadPalette.coral,
      phase: _phase,
      semanticLabel: 'Versus, play a friend',
      onPressed: () => startMultiplayerFlow(context, ref),
      content: const _VersusContent(),
    );
  }
}

class _VersusContent extends StatelessWidget {
  const _VersusContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VersusMark(size: AppSizing.secondaryPadIcon),
        SizedBox(height: AppSpacing.xxs),
        Text(
          'Versus',
          style: TextStyle(
            color: AppColors.padLabel,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
