// lib/shared/widgets/pond_page_header.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/design/tokens/typography.dart';
import 'glyphs/pond_glyph.dart';
import 'pond_icon_button.dart';

/// Pond-styled page header shared by routed pages: a round pond back button
/// (web-safe) and a calm serif page title.
class PondPageHeader extends StatelessWidget {
  const PondPageHeader({super.key, required this.title, this.onBack});

  final String title;

  /// Overrides the default back behaviour (pop, or go home when the page is
  /// a deep-link root). Pages that must clean up first (e.g. leaving a
  /// multiplayer lobby) pass their own handler.
  final VoidCallback? onBack;

  /// Chevron glyph size on the 44px disc (mirrors the old 0.46 icon scale).
  static const double _chevronSize = 20;

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
            glyph: const PondIcon(PondGlyph.chevronLeft, size: _chevronSize),
            semanticLabel: 'Back',
            onPressed: onBack ??
                () => context.canPop() ? context.pop() : context.go('/'),
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
