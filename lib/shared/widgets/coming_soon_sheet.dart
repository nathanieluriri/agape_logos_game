// lib/shared/widgets/coming_soon_sheet.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/spacing.dart';
import 'lily_pad.dart';
import 'pond_pill_button.dart';
import 'pond_sheet.dart';

/// A pond-styled bottom sheet for not-yet-built features (Withdraw, Bonus,
/// Store): a sprouting lily pad rising out of deep water. Shared by the home
/// and level-complete pages.
Future<void> showComingSoon(BuildContext context, String feature) {
  return showPondSheet<void>(
    context: context,
    builder: (context) => _ComingSoonBody(feature: feature),
  );
}

/// Sheet content: sprouting pad, headline, and an Okay pill. The chrome
/// (card, drag bar, scrim) comes from PondSheetScaffold.
class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({required this.feature});

  final String feature;

  /// Diameter of the decorative sprouting pad.
  static const double _padSize = 56;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LilyPad(
          size: _padSize,
          palette: LilyPadPalette.green,
          shape: PadShape.smooth,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '$feature coming soon',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'This lily pad is still sprouting.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: PondPillButton(
            label: 'Okay',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
