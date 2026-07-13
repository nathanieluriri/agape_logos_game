import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/pond_pill_button.dart';

/// Shown when a match listener fails (most often a permission-denied read while
/// signed out). The match screens must never render a failure as a spinner: an
/// endless spinner is indistinguishable from a hang.
class MatchLoadError extends StatelessWidget {
  const MatchLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  /// Diameter of the decorative pad floating above the message.
  static const double _padSize = 56;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LilyPad(
            size: _padSize,
            palette: LilyPadPalette.teal,
            shape: PadShape.smooth,
            child: Icon(Icons.wifi_off_rounded,
                size: 22, color: AppColors.padLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not reach the match',
            style: TextStyle(
              color: AppColors.padLabel,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}
