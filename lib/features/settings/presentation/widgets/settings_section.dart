import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A titled group of settings rows: a deeper-water card with a soft shadow
/// and hairline dividers between rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  /// Hairline thickness of the row divider.
  static const double _dividerThickness = 1;

  static const _cardDecoration = BoxDecoration(
    color: AppColors.pillFill,
    borderRadius: AppRadii.card,
    border: Border.fromBorderSide(BorderSide(color: AppColors.settingsBorder)),
    boxShadow: AppShadows.pill,
  );

  /// Hairline separator drawn between rows, never before the first or after
  /// the last.
  static const _divider = Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: SizedBox(
      height: _dividerThickness,
      width: double.infinity,
      child: ColoredBox(color: AppColors.rowDivider),
    ),
  );

  List<Widget> _dividedChildren() => [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) _divider,
      children[i],
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Left-aligned with the card content, which is inset by md.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
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
          decoration: _cardDecoration,
          // The clip keeps pressed/child paint inside the rounded corners.
          child: ClipRRect(
            borderRadius: AppRadii.card,
            child: Column(children: _dividedChildren()),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
