// lib/shared/widgets/pond_snack.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/spacing.dart';

/// Shows a floating pond-styled snack: a translucent water capsule with soft
/// cream text. The app-wide stand-in for the default [SnackBar] styling.
///
/// Any snack currently on screen is removed first so quick successive
/// messages replace each other instead of queueing.
void showPondSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.pillFill,
        elevation: 0,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.settingsBorder),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
}
