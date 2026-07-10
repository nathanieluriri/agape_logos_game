import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../application/rewards_providers.dart';
import '../../domain/claim_result.dart';
import '../../domain/reward_status.dart';
import 'reward_timer_pad.dart';

/// The gift mark, shared by the top-bar button and its popover header.
const String _kGiftAsset = 'assets/branding/gift_icon.svg';

/// Compact daily-gift button that sits beside the settings gear in the top bar.
///
/// Mirrors the gear's halo + teal disc, with the gift mark inside and a gold
/// "ready" dot when a claim is waiting. Tapping claims the coin gift outright
/// when it is ready; otherwise it opens the gift popover (live countdown, the
/// weekly powerup, or the pre-unlock notice). Hidden entirely when there is
/// nothing actionable to show (signed out / offline / loading / error),
/// matching the old home pad's behaviour.
class RewardGiftButton extends ConsumerStatefulWidget {
  const RewardGiftButton({super.key});

  @override
  ConsumerState<RewardGiftButton> createState() => _RewardGiftButtonState();
}

class _RewardGiftButtonState extends ConsumerState<RewardGiftButton> {
  bool _pressed = false;
  bool _claiming = false;

  Future<void> _handleTap() async {
    final RewardStatus? data = ref.read(rewardStatusControllerProvider).value;
    if (data == null) return;
    Haptics.instance.lightImpact();
    // Ready coin gift: claim in one tap. Everything else (cooldown, the weekly
    // powerup, or the pre-unlock notice) lives in the popover.
    if (data.unlocked && data.coins.claimable) {
      await _claimCoins();
    } else {
      await showRewardGiftSheet(context);
    }
  }

  Future<void> _claimCoins() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final ClaimResult result =
        await ref.read(rewardStatusControllerProvider.notifier).claimCoins();
    if (!mounted) return;
    setState(() => _claiming = false);
    showPondSnack(context, _messageFor(result));
  }

  @override
  Widget build(BuildContext context) {
    final RewardStatus? data = ref.watch(rewardStatusControllerProvider).value;
    if (data == null) return const SizedBox.shrink();

    final bool ready =
        data.unlocked && (data.coins.claimable || data.powerup.claimable);

    return Semantics(
      button: true,
      label: ready ? 'Daily gift ready' : 'Daily gift',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          _handleTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: AppDurations.instant,
          child: _GiftDisc(ready: ready),
        ),
      ),
    );
  }

  static String _messageFor(ClaimResult result) => switch (result) {
        ClaimCoinsSuccess(:final claimed) => 'Claimed $claimed petals!',
        ClaimPowerupSuccess(:final granted) =>
          'Claimed a free ${_pretty(granted)}!',
        ClaimOnCooldown() => 'Already claimed. Check back soon.',
        ClaimLocked(:final minLevel) => 'Reach Lv.$minLevel to unlock gifts.',
        ClaimUnavailable() => 'Could not reach the server. Try again.',
      };

  static String _pretty(String id) => id
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// The gift disc itself: a translucent halo ring around a gradient teal disc
/// with the gift mark, plus an optional gold "ready" dot. Matches the settings
/// gear so the two read as a pair.
class _GiftDisc extends StatelessWidget {
  const _GiftDisc({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: AppSizing.settingsButton,
          height: AppSizing.settingsButton,
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.settingsHalo,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.settingsInner,
              boxShadow: AppShadows.pill,
            ),
            child: Center(
              child: ExcludeSemantics(
                child: SvgPicture.asset(_kGiftAsset, width: 24, height: 24),
              ),
            ),
          ),
        ),
        if (ready) const Positioned(top: -1, right: -1, child: _ReadyDot()),
      ],
    );
  }
}

/// Small gold badge marking that a gift (coins or the weekly powerup) is ready.
class _ReadyDot extends StatelessWidget {
  const _ReadyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
        border: Border.all(color: AppColors.padLabel, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.accent, blurRadius: 6)],
      ),
    );
  }
}

/// Opens the daily-gift popover: a pond bottom sheet with the gift mark and the
/// full reward state (live countdown, Claim button, weekly powerup row, or the
/// pre-unlock notice) rendered by the shared [RewardTimerPad].
Future<void> showRewardGiftSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.pondScrim,
    isScrollControlled: true,
    builder: (_) => const _RewardGiftSheet(),
  );
}

/// Deep-water sheet body: drag bar, the gift mark, then the live reward state.
class _RewardGiftSheet extends StatelessWidget {
  const _RewardGiftSheet();

  static const double _dragBarWidth = 40;
  static const double _dragBarHeight = 4;
  static const double _giftSize = 56;

  static const _sheetDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
    ),
    border: Border(top: BorderSide(color: AppColors.settingsBorder)),
  );

  static const _dragBarDecoration = BoxDecoration(
    color: AppColors.settingsBorder,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _sheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: _dragBarWidth,
                height: _dragBarHeight,
                child: DecoratedBox(decoration: _dragBarDecoration),
              ),
              const SizedBox(height: AppSpacing.md),
              SvgPicture.asset(
                _kGiftAsset,
                width: _giftSize,
                height: _giftSize,
                semanticsLabel: 'Daily gift',
              ),
              const SizedBox(height: AppSpacing.sm),
              // Full reward state: countdown, Claim, weekly powerup, or the
              // locked notice. Reused verbatim from the home pad.
              const RewardTimerPad(),
            ],
          ),
        ),
      ),
    );
  }
}
