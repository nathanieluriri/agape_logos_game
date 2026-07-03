// lib/shared/widgets/coming_soon_sheet.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/spacing.dart';
import 'lily_pad.dart';
import 'pond_pill_button.dart';

/// A pond-styled bottom sheet for not-yet-built features (Withdraw, Bonus,
/// Store): a sprouting lily pad rising out of deep water. Shared by the home
/// and level-complete pages.
Future<void> showComingSoon(BuildContext context, String feature) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.pondScrim,
    builder: (context) => _ComingSoonSheet(feature: feature),
  );
}

/// Deep-water sheet body: drag bar, sprouting pad, headline, and an Okay pill.
class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({required this.feature});

  final String feature;

  /// Hand-rolled drag bar dimensions.
  static const double _dragBarWidth = 40;
  static const double _dragBarHeight = 4;

  /// Diameter of the decorative sprouting pad.
  static const double _padSize = 56;

  static const _sheetDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
    ),
    border: Border(top: BorderSide(color: AppColors.settingsBorder)),
  );

  static const _dragBarDecoration = BoxDecoration(
    color: AppColors.settingsBorder,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _sheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: _dragBarWidth,
                height: _dragBarHeight,
                child: DecoratedBox(decoration: _dragBarDecoration),
              ),
              const SizedBox(height: AppSpacing.md),
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
          ),
        ),
      ),
    );
  }
}
