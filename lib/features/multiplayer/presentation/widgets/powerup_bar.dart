import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/petal_icon.dart';
import '../../../store/application/store_providers.dart';
import '../../../store/domain/store_item.dart';
import '../../application/match_providers.dart';

/// Icon for each offense powerup, keyed by the server effect rule (which equals
/// the event kind wire string, contract 8.5).
IconData _iconFor(String rule) {
  switch (rule) {
    case 'letter_freeze':
      return Icons.ac_unit_rounded;
    case 'fog_bank':
      return Icons.cloud_rounded;
    case 'scramble':
      return Icons.shuffle_rounded;
    case 'word_steal':
      return Icons.swipe_left_alt_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

/// The owned-powerup bar. Tapping an owned powerup fires it at the opponent
/// (spends inventory server-side); an unowned one shows its store cost.
// PLAN: confirm the backend uses these exact `effect.rule` strings
// (letter_freeze/fog_bank/scramble/word_steal) matching the event kinds. If the
// store item's rule differs, map it here.
class PowerupBar extends ConsumerWidget {
  const PowerupBar({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(storeCatalogProvider).value ?? const <StoreItem>[];
    final inventory =
        ref.watch(inventoryControllerProvider).value ?? const <String, int>{};
    final offense = catalog
        .where((i) => i.category == 'powerup' && i.kind == 'offense')
        .where((i) => i.effect != null)
        .toList();
    if (offense.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: AppSizing.actionButton + AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: offense.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final item = offense[i];
          final owned = inventory[item.id] ?? 0;
          return _PowerupButton(
            item: item,
            owned: owned,
            onFire: owned > 0
                ? () async {
                    final ok = await ref.read(matchServiceProvider).powerup(
                          matchId,
                          item.effect!.rule,
                          eventId: const Uuid().v4(),
                        );
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No ${item.name} left')),
                      );
                    } else {
                      // Reflect the spend at once; the server catalog/inventory
                      // reconciles on the next store open.
                      ref
                          .read(inventoryControllerProvider.notifier)
                          .applyServer({...inventory, item.id: owned - 1});
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _PowerupButton extends StatelessWidget {
  const _PowerupButton({
    required this.item,
    required this.owned,
    required this.onFire,
  });
  final StoreItem item;
  final int owned;
  final VoidCallback? onFire;

  @override
  Widget build(BuildContext context) {
    final enabled = owned > 0 && onFire != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${item.name}${enabled ? ', $owned owned' : ', locked'}',
      child: GestureDetector(
        onTap: onFire,
        child: Container(
          width: AppSizing.actionButton + AppSpacing.lg,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: enabled ? AppColors.plusButtonDeep : AppColors.pillFill,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: enabled ? AppColors.plusButtonBorder : AppColors.pillBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFor(item.effect!.rule),
                color: enabled ? AppColors.padLabel : AppColors.padLabelSoft,
                size: 22,
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (owned > 0)
                Text(
                  'x$owned',
                  style: const TextStyle(
                    color: AppColors.padLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PetalIcon(size: AppSizing.petalIconSm),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${item.cost}',
                      style: const TextStyle(
                        color: AppColors.padLabelSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
