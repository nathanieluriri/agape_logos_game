import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/player/application/player_controller.dart';
import '../../../../shared/widgets/coming_soon_sheet.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/lily_pad_button.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_top_bar.dart';
import '../../../../shared/widgets/wordmark_logo.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_sheet.dart';
import '../widgets/home_background.dart' show homeAmbientPausedProvider;

/// The home screen (withdraw state). Thin composition of shared pond widgets.
/// Shows the wordmark + the Play pad + a Withdraw pad. No progress, no bonus.
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

  /// Navigates to the game, pausing the ambient while it is covered and
  /// resuming when the player returns (the push future completes on pop).
  Future<void> _toGame(BuildContext context, WidgetRef ref) async {
    ref.read(homeAmbientPausedProvider.notifier).pause(true);
    await context.push('/game');
    if (context.mounted) {
      ref.read(homeAmbientPausedProvider.notifier).pause(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(playerStateProvider.select((s) => s.coins));
    final nextLabel =
        ref.watch(playerStateProvider.select((s) => s.nextLevelLabel));

    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            children: [
              PondTopBar(
                coins: coins,
                onSettings: () => showComingSoon(context, 'Settings'),
                onAddCoins: () => showComingSoon(context, 'Store'),
              ),
              const Spacer(),
              const WordmarkLogo(),
              const Spacer(),
              _PlayArea(
                nextLabel: nextLabel,
                onPlay: () => _onPlay(context, ref),
                onWithdraw: () => showComingSoon(context, 'Withdraw'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating play cluster: the green Play pad centered, with the teal
/// Withdraw pad floating up and to the right.
class _PlayArea extends StatelessWidget {
  const _PlayArea({
    required this.nextLabel,
    required this.onPlay,
    required this.onWithdraw,
  });

  final String nextLabel;
  final VoidCallback onPlay;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LilyPadButton(
            size: 180,
            rotationDegrees: 20,
            palette: LilyPadPalette.green,
            semanticLabel: 'Play $nextLabel',
            onPressed: onPlay,
            content: _PlayContent(label: nextLabel),
          ),
          Positioned(
            right: 4,
            top: 8,
            child: LilyPadButton(
              size: 104,
              rotationDegrees: -15,
              palette: LilyPadPalette.teal,
              idle: IdleMotion.bob,
              semanticLabel: 'Withdraw',
              onPressed: onWithdraw,
              content: const _SecondaryContent(
                icon: Icons.account_balance_wallet,
                label: 'Withdraw',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayContent extends StatelessWidget {
  const _PlayContent({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow_rounded,
            size: 56, color: AppColors.playTriangle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SecondaryContent extends StatelessWidget {
  const _SecondaryContent({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: AppColors.padLabel),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
