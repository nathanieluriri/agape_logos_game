import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/coin_pill.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import '../../../../shared/widgets/pond_icon_button.dart';

/// Game header: back, dictionary, centered level title, coins.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.level,
    required this.coins,
    required this.onBack,
    required this.onDictionary,
  });

  final int level;
  final int coins;
  final VoidCallback onBack;
  final VoidCallback onDictionary;

  /// Glyph size on the top-bar discs.
  static const double _glyphSize = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          PondIconButton(
            glyph: const PondIcon(PondGlyph.chevronLeft, size: _glyphSize),
            semanticLabel: 'Back',
            onPressed: onBack,
            size: AppSizing.topBarButton,
          ),
          const SizedBox(width: AppSpacing.xs),
          PondIconButton(
            glyph: const PondIcon(PondGlyph.book, size: _glyphSize),
            semanticLabel: 'Dictionary',
            onPressed: onDictionary,
            size: AppSizing.topBarButton,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Level $level',
                style: AppTypography.heading.copyWith(
                  fontSize: 20,
                  color: AppColors.pillText,
                ),
              ),
            ),
          ),
          CoinPill(amount: coins),
        ],
      ),
    );
  }
}
