import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/play_flow.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../features/rewards/presentation/widgets/reward_timer_pad.dart';
import '../../../../shared/widgets/coming_soon_sheet.dart';
import '../../../../shared/widgets/play_pad_cluster.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_dialog.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_top_bar.dart';
import '../../../../shared/widgets/wordmark_logo.dart';

/// The home screen (withdraw state). Thin composition of shared pond widgets.
/// Shows the wordmark + the Play pad + a Withdraw pad. No progress, no bonus.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final nextLabel = 'Lv.${ref.watch(nextLevelProvider)}';

    return PopScope(
      // Home is the root: intercept the Android back gesture and confirm before
      // letting it close the app, rather than dropping the player out silently.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave) await SystemNavigator.pop();
      },
      child: Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            children: [
              PondTopBar(
                coins: coins,
                onSettings: () => context.push('/settings'),
                onAddCoins: () => context.push('/store'),
              ),
              const RewardTimerPad(),
              const Spacer(),
              const WordmarkLogo(),
              const Spacer(),
              PlayPadCluster(
                nextLabel: nextLabel,
                onPlay: () => startPlayFlow(context, ref),
                secondaryIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 26,
                  color: AppColors.padLabel,
                ),
                secondaryLabel: 'Withdraw',
                onSecondary: () => showComingSoon(context, 'Withdraw'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Pond-styled confirm before leaving the app from Home. Returns true when
  /// the player taps Leave.
  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showPondDialog<bool>(
      context: context,
      title: 'Leave the game?',
      body: 'Are you sure you want to leave?',
      actions: [
        PondPillButton(
          label: 'Stay',
          variant: PondPillVariant.quiet,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        PondPillButton(
          label: 'Leave',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );
    return result ?? false;
  }
}
