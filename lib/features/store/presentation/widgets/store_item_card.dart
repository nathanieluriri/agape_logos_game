import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/haptics/haptic_providers.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/petal_icon.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../application/store_providers.dart';
import '../../domain/purchase_outcome.dart';
import '../../domain/store_item.dart';

/// One catalog entry: name, description, owned count, and a Buy pill that spends
/// coins. The buy result is surfaced as a pond snack. Reads its own in-flight
/// state from [storePurchaseControllerProvider] so only this card's button
/// disables while its request is out.
class StoreItemCard extends ConsumerWidget {
  const StoreItemCard({super.key, required this.item, required this.owned});

  final StoreItem item;

  /// How many of this item (by id) the player already owns. Always 0 for
  /// bundles (bundles are not tracked as their own inventory line).
  final int owned;

  static const _cardDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: AppRadii.card,
    border: Border.fromBorderSide(BorderSide(color: AppColors.settingsBorder)),
  );

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final haptics = ref.read(hapticServiceProvider);
    final outcome = await ref
        .read(storePurchaseControllerProvider.notifier)
        .buy(item);
    if (!context.mounted) return;
    switch (outcome) {
      case PurchaseSuccess(:final replay):
        haptics.successPattern();
        showPondSnack(
          context,
          replay ? '${item.name} already yours.' : '${item.name} purchased!',
        );
      case PurchaseInsufficientCoins(:final cost, :final coins):
        haptics.mistakeImpact();
        showPondSnack(
          context,
          'Not enough petals. ${item.name} costs $cost, you have $coins.',
        );
      case PurchaseUnknownItem():
        haptics.mistakeImpact();
        showPondSnack(context, 'That item is no longer available.');
      case PurchaseUnavailable():
        haptics.mistakeImpact();
        showPondSnack(context, 'Could not reach the store. Try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buying = ref.watch(
      storePurchaseControllerProvider.select((s) => s.contains(item.id)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.padLabel,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _KindChip(label: _kindLabel(item)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppColors.padLabelSoft,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    if (!item.isBundle && owned > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Owned: $owned',
                        style: const TextStyle(
                          color: AppColors.progressFraction,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CostTag(cost: item.cost),
                  const SizedBox(height: AppSpacing.sm),
                  buying
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.padLabel,
                            ),
                          ),
                        )
                      : PondPillButton(
                          label: 'Buy',
                          semanticLabel:
                              'Buy ${item.name} for ${item.cost} petals',
                          onPressed: () => _buy(context, ref),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _kindLabel(StoreItem item) {
    if (item.category == 'hint') return 'Hint';
    switch (item.kind) {
      case 'offense':
        return 'Offense';
      case 'defense':
        return 'Defense';
      case 'utility':
        return 'Boost';
      default:
        return 'Power';
    }
  }
}

/// Small rounded tag showing an item's kind (Hint / Offense / Defense / Boost).
class _KindChip extends StatelessWidget {
  const _KindChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.settingsBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.padLabelSoft,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// The item cost, shown as a currency petal beside the number.
class _CostTag extends StatelessWidget {
  const _CostTag({required this.cost});

  final int cost;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PetalIcon(size: AppSizing.petalIconSm),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$cost',
          style: const TextStyle(
            color: AppColors.pillText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
