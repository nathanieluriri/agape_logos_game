import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/coin_pill.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          PondIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: onBack,
            size: AppSizing.topBarButton,
          ),
          const SizedBox(width: AppSpacing.xs),
          PondIconButton(
            icon: Icons.menu_book_outlined,
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
