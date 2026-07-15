// lib/features/multiplayer/presentation/widgets/powerup_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../shared/widgets/pond_dialog.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../store/application/store_providers.dart';
import '../../../store/domain/purchase_outcome.dart';
import '../../../store/domain/store_item.dart';

/// Info + buy sheet for a single powerup, opened from a wheel slot (owned or
/// not). Reuses the store's server-authoritative purchase flow: idempotency
/// key and balance write-through happen inside [StorePurchaseController.buy],
/// this widget only renders the outcome.
abstract final class PowerupInfoSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    StoreItem item,
  ) {
    return showPondDialog<void>(
      context: context,
      title: item.name,
      body: _describe(item),
      actions: [
        PondPillButton(
          label: 'Close',
          variant: PondPillVariant.quiet,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        Consumer(
          builder: (context, ref, _) {
            final buying = ref.watch(
              storePurchaseControllerProvider.select(
                (s) => s.contains(item.id),
              ),
            );
            if (buying) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.padLabel,
                  ),
                ),
              );
            }
            return PondPillButton(
              label: 'Buy · ${item.cost}',
              semanticLabel: 'Buy ${item.name} for ${item.cost} petals',
              onPressed: () => _buy(context, ref, item),
            );
          },
        ),
      ],
    );
  }

  static Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    StoreItem item,
  ) async {
    final outcome = await ref
        .read(storePurchaseControllerProvider.notifier)
        .buy(item);
    if (!context.mounted) return;
    switch (outcome) {
      case PurchaseSuccess(:final replay):
        showPondSnack(
          context,
          replay ? '${item.name} already yours.' : '${item.name} purchased!',
        );
      case PurchaseInsufficientCoins(:final cost, :final coins):
        showPondSnack(
          context,
          'Not enough petals. ${item.name} costs $cost, you have $coins.',
        );
      case PurchaseUnknownItem():
        showPondSnack(context, 'That item is no longer available.');
      case PurchaseUnavailable():
        showPondSnack(context, 'Could not reach the store. Try again.');
    }
  }

  static String _describe(StoreItem item) {
    final effect = item.effect;
    if (effect == null || effect.durationSec <= 0) return item.description;
    return '${item.description} Lasts ${effect.durationSec}s.';
  }
}
