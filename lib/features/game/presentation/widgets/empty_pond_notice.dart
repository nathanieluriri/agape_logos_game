// lib/features/game/presentation/widgets/empty_pond_notice.dart
import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/pond_pill_button.dart';

/// Shown when the puzzle cache is empty and nothing could be fetched: a calm
/// message with a retry action, instead of an endless spinner.
class EmptyPondNotice extends StatelessWidget {
  const EmptyPondNotice({super.key, required this.onRetry});

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
            child: Icon(Icons.waves, size: 22, color: AppColors.padLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'The pond is out of puzzles',
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
          PondPillButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
