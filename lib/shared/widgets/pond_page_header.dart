// lib/shared/widgets/pond_page_header.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/design/tokens/typography.dart';
import 'pond_icon_button.dart';

/// Pond-styled page header shared by routed pages: a round pond back button
/// (web-safe) and a calm serif page title.
class PondPageHeader extends StatelessWidget {
  const PondPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          PondIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.heading.copyWith(color: AppColors.padLabel),
          ),
        ],
      ),
    );
  }
}
