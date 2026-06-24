import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A titled group of settings rows, styled as a translucent card on the pond.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.padLabel,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.pillFill,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.settingsBorder),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
