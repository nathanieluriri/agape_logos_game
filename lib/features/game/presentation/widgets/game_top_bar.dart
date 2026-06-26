import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/coin_pill.dart';

/// Game header: back, dictionary (stub), centered level title, coins.
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
          _CircleIcon(icon: Icons.arrow_back, label: 'Back', onTap: onBack),
          const SizedBox(width: AppSpacing.xs),
          _CircleIcon(
            icon: Icons.menu_book_outlined,
            label: 'Dictionary',
            onTap: onDictionary,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.settingsFill,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.settingsBorder),
          ),
          child: Icon(icon, size: 22, color: AppColors.pillText),
        ),
      ),
    );
  }
}
