import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../application/rewards_providers.dart';
import '../../domain/claim_result.dart';
import '../../domain/reward_status.dart';
import '../cooldown_format.dart';

/// Home-screen daily-gift pad: a live 72h countdown that becomes a Claim button
/// when the reward is ready. Hidden entirely when signed out or offline (there
/// is nothing actionable to show); a compact locked chip before the reward
/// unlocks. This is the surface that reads the backend `GET /rewards` timer.
class RewardTimerPad extends ConsumerStatefulWidget {
  const RewardTimerPad({super.key});

  @override
  ConsumerState<RewardTimerPad> createState() => _RewardTimerPadState();
}

class _RewardTimerPadState extends ConsumerState<RewardTimerPad> {
  bool _claiming = false;

  Future<void> _claimCoins() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final ClaimResult result =
        await ref.read(rewardStatusControllerProvider.notifier).claimCoins();
    if (!mounted) return;
    setState(() => _claiming = false);
    _announce(result);
  }

  Future<void> _claimPowerup() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final ClaimResult result =
        await ref.read(rewardStatusControllerProvider.notifier).claimPowerup();
    if (!mounted) return;
    setState(() => _claiming = false);
    _announce(result);
  }

  void _announce(ClaimResult result) {
    final message = switch (result) {
      ClaimCoinsSuccess(:final claimed) => 'Claimed $claimed coins!',
      ClaimPowerupSuccess(:final granted) => 'Claimed a free ${_pretty(granted)}!',
      ClaimOnCooldown() => 'Already claimed. Check back soon.',
      ClaimLocked(:final minLevel) => 'Reach Lv.$minLevel to unlock gifts.',
      ClaimUnavailable() => 'Could not reach the server. Try again.',
    };
    showPondSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(rewardStatusControllerProvider);
    final RewardStatus? data = status.value;
    // Signed out, loading, offline, or errored: show nothing rather than a
    // broken or spinning pad on the calm home screen.
    if (data == null) return const SizedBox.shrink();

    if (!data.unlocked) {
      return _LockedChip(minLevel: data.minLevel);
    }

    if (data.coins.claimable) {
      return _GiftCard(
        claiming: _claiming,
        onClaim: _claimCoins,
        title: 'Daily gift ready',
        subtitle: '${data.coins.amount} coins waiting for you',
        actionLabel: 'Claim',
        highlighted: true,
      );
    }

    // On cooldown: tick down to the next claim, then refresh so it flips to
    // claimable without the player leaving the screen.
    return _GiftCard(
      key: ValueKey<int>(data.coins.nextClaimInMs),
      claiming: false,
      onClaim: null,
      title: 'Daily gift',
      subtitleWidget: _CooldownText(
        remainingMs: data.coins.nextClaimInMs,
        onElapsed: () =>
            ref.read(rewardStatusControllerProvider.notifier).refresh(),
      ),
      actionLabel: null,
      highlighted: false,
      // Offer the weekly powerup inline when it happens to be ready.
      footer: data.powerup.claimable
          ? _PowerupClaimRow(
              claiming: _claiming,
              onClaim: _claimPowerup,
            )
          : null,
    );
  }

  static String _pretty(String id) =>
      id.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

/// The gift pad body: a gold gift glyph, a title, a subtitle (text or a live
/// countdown), and an optional Claim button. Tappable as a whole when a claim
/// action is available.
class _GiftCard extends StatelessWidget {
  const _GiftCard({
    super.key,
    required this.claiming,
    required this.onClaim,
    required this.title,
    required this.actionLabel,
    required this.highlighted,
    this.subtitle,
    this.subtitleWidget,
    this.footer,
  });

  final bool claiming;
  final VoidCallback? onClaim;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final String? actionLabel;
  final bool highlighted;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.pondCard,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: highlighted
              ? AppColors.progressTrackBorder
              : AppColors.settingsBorder,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.padLabel,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      subtitleWidget ??
                          Text(
                            subtitle ?? '',
                            style: const TextStyle(
                              color: AppColors.padLabelSoft,
                              fontSize: 13,
                            ),
                          ),
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _ClaimButton(
                    label: actionLabel!,
                    busy: claiming,
                    onPressed: onClaim,
                  ),
                ],
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: card,
    );
  }
}

/// A small gold claim capsule with a busy spinner. Kept local to the pad so the
/// gift affordance reads distinct from the app's primary green pills.
class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.accent,
            borderRadius: AppRadii.pill,
          ),
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ink,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Inline row offering the weekly powerup when it is ready.
class _PowerupClaimRow extends StatelessWidget {
  const _PowerupClaimRow({required this.claiming, required this.onClaim});

  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.bolt_rounded, color: AppColors.progressFillMid, size: 20),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text(
            'Weekly powerup ready',
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 13),
          ),
        ),
        _ClaimButton(label: 'Claim', busy: claiming, onPressed: onClaim),
      ],
    );
  }
}

/// Small locked chip shown before rewards unlock at [minLevel].
class _LockedChip extends StatelessWidget {
  const _LockedChip({required this.minLevel});

  final int minLevel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.pillFill,
          borderRadius: AppRadii.pill,
          border: Border.all(color: AppColors.settingsBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.padLabelSoft,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Daily gift unlocks at Lv.$minLevel',
              style: const TextStyle(
                color: AppColors.padLabelSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live "next gift in ..." countdown. Ticks each second off a deadline fixed
/// when it is created (keyed by the server value upstream, so a fresh server
/// snapshot rebuilds it). Calls [onElapsed] once when it reaches zero.
class _CooldownText extends StatefulWidget {
  const _CooldownText({required this.remainingMs, required this.onElapsed});

  final int remainingMs;
  final VoidCallback onElapsed;

  @override
  State<_CooldownText> createState() => _CooldownTextState();
}

class _CooldownTextState extends State<_CooldownText> {
  late DateTime _deadline;
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(Duration(milliseconds: widget.remainingMs));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (_deadline.difference(DateTime.now()).isNegative) {
      _timer?.cancel();
      if (!_fired) {
        _fired = true;
        widget.onElapsed();
      }
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deadline.difference(DateTime.now());
    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.padLabelSoft, size: 15),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Next gift in ${formatCooldown(remaining)}',
          style: const TextStyle(
            color: AppColors.padLabelSoft,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
