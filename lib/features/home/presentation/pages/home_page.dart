import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_sheet.dart';
import '../../application/home_controller.dart';
import '../widgets/home_background.dart';
import '../widgets/home_branding.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/level_progress.dart';
import '../widgets/play_button.dart';
import '../widgets/withdraw_gift_button.dart';

/// The home screen. Thin composition: chrome, branding, progress, and the action
/// cluster over the ambient background. All data comes from [homeControllerProvider].
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _onPlay(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentUserProvider) != null) {
      await _toGame(context, ref);
      return;
    }
    await showAuthSheet(context);
    if (!context.mounted) return;
    if (ref.read(currentUserProvider) != null) await _toGame(context, ref);
  }

  /// Navigates to the game, pausing the home's looping motion while it is covered
  /// and resuming when the player returns (the push future completes on pop).
  Future<void> _toGame(BuildContext context, WidgetRef ref) async {
    ref.read(homeAmbientPausedProvider.notifier).pause(true);
    await context.push('/game');
    if (context.mounted) {
      ref.read(homeAmbientPausedProvider.notifier).pause(false);
    }
  }

  void _comingSoon(BuildContext context, String what) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '$what coming soon',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextLevel =
        ref.watch(homeControllerProvider.select((s) => s.nextLevelLabel));

    return Scaffold(
      body: HomeBackground(
        child: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                onSettings: () => _comingSoon(context, 'Settings'),
                onAdd: () => _comingSoon(context, 'Store'),
              ),
              const Spacer(),
              const HomeBranding(),
              const SizedBox(height: AppSpacing.xl),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: LevelProgress(),
              ),
              const Spacer(),
              WithdrawGiftButton(
                onPressed: () => _comingSoon(context, 'Withdraw'),
              ),
              const SizedBox(height: AppSpacing.lg),
              PlayButton(
                label: nextLevel,
                onPressed: () => _onPlay(context, ref),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
