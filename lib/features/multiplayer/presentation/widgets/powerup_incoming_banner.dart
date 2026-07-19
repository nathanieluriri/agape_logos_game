import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// What triggered a [PowerupIncomingBanner]: who cast it, what it's called,
/// and whether a shield absorbed it before it landed on me.
class IncomingBannerData {
  const IncomingBannerData({
    required this.casterName,
    required this.powerupName,
    this.blocked = false,
  });

  final String casterName;
  final String powerupName;

  /// True for the "my shield absorbed it" variant (shield-shatter styling).
  final bool blocked;
}

/// The victim's half of the cast feedback loop: the card drops from the top
/// edge to center, holds for [AppDurations.powerupBannerHold] so the message
/// reads, then flies away as the effect (already active on the match doc)
/// becomes visible. [PowerupCastFlyout] is the caster's mirror of this.
class PowerupIncomingBanner extends StatefulWidget {
  const PowerupIncomingBanner({
    super.key,
    required this.data,
    required this.onDone,
  });

  final IncomingBannerData data;
  final VoidCallback onDone;

  @override
  State<PowerupIncomingBanner> createState() => _PowerupIncomingBannerState();
}

class _PowerupIncomingBannerState extends State<PowerupIncomingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _holdTimer;
  bool _leaving = false;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.powerupBannerTransition,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      // Snap into place instead of dropping in with easeOutBack; the card
      // still registers briefly before it snaps away.
      _controller.value = 1;
      _holdTimer = Timer(AppDurations.powerupBannerHold, _leave);
    } else {
      _controller.forward().whenComplete(() {
        if (!mounted) return;
        _holdTimer = Timer(AppDurations.powerupBannerHold, _leave);
      });
    }
  }

  void _leave() {
    if (!mounted || _leaving) return;
    _leaving = true;
    if (_reduceMotion) {
      _controller.value = 0;
      widget.onDone();
      return;
    }
    _controller.duration = AppDurations.powerupBannerTransition;
    _controller.reverse(from: 1).whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final title = d.blocked
        ? 'Shield blocked ${d.powerupName}!'
        : '${d.casterName} cast ${d.powerupName}!';
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _controller,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final t = Curves.easeOutBack.transform(
                _controller.value.clamp(0.0, 1.0),
              );
              return Transform.translate(
                offset: Offset(0, (1 - t) * -AppSpacing.powerupBannerDropDistance),
                child: child,
              );
            },
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.powerupBannerTopInset),
                child: _BannerCard(title: title, blocked: d.blocked),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.title, required this.blocked});

  final String title;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: blocked ? AppColors.dangerFill : AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(
          color: blocked ? AppColors.dangerBorder : AppColors.pillBorder,
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: blocked ? AppColors.dangerOnPond : AppColors.pillText,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
