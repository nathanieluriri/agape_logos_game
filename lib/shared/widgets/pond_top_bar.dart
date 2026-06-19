// lib/shared/widgets/pond_top_bar.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/spacing.dart';
import 'coin_pill.dart';
import 'settings_button.dart';

/// Shared header: settings gear (left) + currency pill (right).
class PondTopBar extends StatelessWidget {
  const PondTopBar({
    super.key,
    required this.coins,
    this.onSettings,
    this.onAddCoins,
  });

  final int coins;
  final VoidCallback? onSettings;
  final VoidCallback? onAddCoins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SettingsButton(onPressed: onSettings ?? () {}),
          CoinPill(amount: coins, onAdd: onAddCoins),
        ],
      ),
    );
  }
}
