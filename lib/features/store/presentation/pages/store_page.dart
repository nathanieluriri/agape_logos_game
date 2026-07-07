import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/store_providers.dart';
import '../../domain/store_item.dart';
import '../widgets/store_item_card.dart';

/// The coin store: spend earned coins on hints, powerups, and bundles. The
/// catalog and the caller's inventory come from the backend; a purchase debits
/// the server-owned wallet and reflects the new balance in the coin pill.
class StorePage extends ConsumerWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Store'),
              const SizedBox(height: AppSpacing.sm),
              if (user == null)
                const _SignedOutNotice()
              else
                const _StoreBody(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when signed out: the store needs an account (the wallet is per-user).
class _SignedOutNotice extends StatelessWidget {
  const _SignedOutNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Text(
            'Sign in to visit the store and spend your coins.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(
            label: 'Sign in',
            onPressed: () => context.push('/sign-in'),
          ),
        ],
      ),
    );
  }
}

class _StoreBody extends ConsumerWidget {
  const _StoreBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final catalog = ref.watch(storeCatalogProvider);
    final inventory =
        ref.watch(inventoryControllerProvider).value ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _CoinBalance(coins: coins),
        ),
        const SizedBox(height: AppSpacing.md),
        catalog.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: PondLoader(
                label: 'Loading the store',
              ),
            ),
          ),
          error: (_, __) => _StoreError(
            onRetry: () => ref.invalidate(storeCatalogProvider),
          ),
          data: (items) => _Catalog(items: items, inventory: inventory),
        ),
      ],
    );
  }
}

/// Groups the catalog into Hints, Powerups, and Bundles and lays out a card per
/// item. Base items show an owned count; bundles show what they grant.
class _Catalog extends StatelessWidget {
  const _Catalog({required this.items, required this.inventory});

  final List<StoreItem> items;
  final Map<String, int> inventory;

  @override
  Widget build(BuildContext context) {
    final hints =
        items.where((i) => i.category == 'hint' && !i.isBundle).toList();
    final powerups =
        items.where((i) => i.category == 'powerup' && !i.isBundle).toList();
    final bundles = items.where((i) => i.isBundle).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hints.isNotEmpty) ...[
            const _SectionLabel('Hints'),
            for (final item in hints)
              StoreItemCard(item: item, owned: inventory[item.id] ?? 0),
          ],
          if (powerups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Powerups'),
            for (final item in powerups)
              StoreItemCard(item: item, owned: inventory[item.id] ?? 0),
          ],
          if (bundles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Bundles'),
            for (final item in bundles)
              StoreItemCard(item: item, owned: inventory[item.id] ?? 0),
          ],
        ],
      ),
    );
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$coins coins',
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
        top: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.padLabelSoft,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StoreError extends StatelessWidget {
  const _StoreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Text(
            'Could not load the store. Check your connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}
