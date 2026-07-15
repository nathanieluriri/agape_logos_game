import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/petal_icon.dart';
import '../../../store/application/store_providers.dart';
import '../../../store/domain/store_item.dart';
import '../../application/match_providers.dart';
import '../../domain/powerup_kind.dart';

/// The hand-drawn powerup art, keyed by the STORE ITEM ID (the filename is the
/// id: `assets/powerups/<id>.svg`, POWERUPS.md). The SVGs are full-color, so a
/// locked/unowned powerup is dimmed rather than tinted.
Widget _powerupIcon(String itemId, {required bool enabled}) {
  final Widget art = SvgPicture.asset(
    'assets/powerups/$itemId.svg',
    width: 26,
    height: 26,
  );
  return enabled ? art : Opacity(opacity: 0.4, child: art);
}

/// The owned-powerup bar. Tapping an owned powerup fires it at the opponent
/// (spends inventory server-side); an unowned one shows its store cost.
///
/// The earlier PLAN note here asked someone to confirm the backend used the
/// item's `effect.rule` as the wire kind. It does not: `rule` is rules text, so
/// the server rejected every fire with a 400. The bar now resolves the kind from
/// the item id via [powerupWireKind], which is also what decides whether an item
/// is firable at all (defense/utility items have no gameplay hook yet).
class PowerupBar extends ConsumerWidget {
  const PowerupBar({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog =
        ref.watch(storeCatalogProvider).value ?? const <StoreItem>[];
    final inventory =
        ref.watch(inventoryControllerProvider).value ?? const <String, int>{};
    // Firable == the server implements it. Keying off the id map (rather than
    // category/kind) also keeps bundles like skirmish_pack out of the bar.
    final offense = catalog
        .where((i) => powerupWireKind(i.id) != null)
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
                    final ok = await ref
                        .read(matchServiceProvider)
                        .powerup(
                          matchId,
                          powerupWireKind(item.id)!,
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
              color: enabled
                  ? AppColors.plusButtonBorder
                  : AppColors.pillBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _powerupIcon(item.id, enabled: enabled),
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
