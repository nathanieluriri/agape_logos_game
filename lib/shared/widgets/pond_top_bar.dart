// lib/shared/widgets/pond_top_bar.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/spacing.dart';
import 'coin_pill.dart';
import 'settings_button.dart';
import 'sync_status_badge.dart';

/// Shared header: settings gear (+ optional action) on the left, currency pill
/// on the right.
class PondTopBar extends StatelessWidget {
  const PondTopBar({
    super.key,
    required this.coins,
    this.onSettings,
    this.onAddCoins,
    this.action,
    this.syncStatus = SyncBadgeStatus.none,
  });

  final int coins;
  final VoidCallback? onSettings;
  final VoidCallback? onAddCoins;

  /// Delivery state of [coins], passed through to the pill's inline badge.
  final SyncBadgeStatus syncStatus;

  /// Optional widget placed just right of the settings gear (e.g. the
  /// daily-gift button on Home). Omitted on screens with nothing to show there.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SettingsButton(onPressed: onSettings ?? () {}),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.sm),
                action!,
              ],
            ],
          ),
          CoinPill(amount: coins, onAdd: onAddCoins, syncStatus: syncStatus),
        ],
      ),
    );
  }
}
