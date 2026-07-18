import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/play_flow.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/lily_pad_button.dart';
import '../../../../shared/widgets/versus_mark.dart';
import '../../application/resume_providers.dart';

/// The Home "Versus" pad: a coral lily pad that opens multiplayer matchmaking.
/// Auth-gated (guests are signed in first) via [startMultiplayerFlow]. Carries
/// a small count badge (the same combined active-matches + incoming-challenges
/// count as the "Play with friends" sheet's Resume entry, see
/// `multiplayer_sheet.dart`) so a player notices a match to resume without
/// opening the sheet. Hidden entirely when the count is 0.
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
    final challenges = ref.watch(incomingChallengesProvider).value?.length ?? 0;
    final games = ref.watch(activeMatchesProvider).value?.length ?? 0;
    final resumeCount = challenges + games;

    final pad = LilyPadButton(
      size: AppSizing.secondaryPad,
      shape: PadShape.smooth,
      rotationDegrees: -20,
      palette: LilyPadPalette.coral,
      phase: _phase,
      semanticLabel: resumeCount > 0
          ? 'Versus, play a friend, $resumeCount to resume'
          : 'Versus, play a friend',
      onPressed: () => startMultiplayerFlow(context, ref),
      content: const _VersusContent(),
    );
    if (resumeCount == 0) return pad;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        pad,
        Positioned(
          top: -AppSpacing.xs,
          right: -AppSpacing.xs,
          child: _ResumeBadge(count: resumeCount),
        ),
      ],
    );
  }
}

/// A small danger-coloured count pill for pending resumable matches (active
/// games + incoming challenges). Caps the displayed value at 9+ so it never
/// grows the pad's footprint. Copies the `_RequestBadge` idiom from
/// `friends_button.dart` so the two badges read as the same component.
class _ResumeBadge extends StatelessWidget {
  const _ResumeBadge({required this.count});

  final int count;

  /// Minimum diameter so a single digit still reads as a round pill.
  static const double _minSize = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: _minSize,
        minHeight: _minSize,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.markCream, width: 1.5),
        boxShadow: AppShadows.pill,
      ),
      child: ExcludeSemantics(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: AppColors.markCream,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
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
