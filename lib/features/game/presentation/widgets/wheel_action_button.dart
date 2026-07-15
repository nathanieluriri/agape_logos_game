import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/haptics/haptics.dart';

/// A circular Shuffle/Hint button with an optional count badge, in the pond
/// chrome: a soft halo ring around a gradient teal disc (a flat water disc
/// while disabled), with a gold count badge.
class WheelActionButton extends StatefulWidget {
  const WheelActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final int? badge;
  final bool enabled;

  @override
  State<WheelActionButton> createState() => _WheelActionButtonState();
}

class _WheelActionButtonState extends State<WheelActionButton> {
  /// Halo ring thickness around the inner disc (matches the settings gear).
  static const double _haloPadding = 5;

  /// Enabled disc: lifted gradient teal.
  static const _enabledDisc = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppGradients.settingsInner,
    boxShadow: AppShadows.pill,
  );

  /// Disabled disc: flat translucent water, no lift.
  static const _disabledDisc = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.pillFill,
    border: Border.fromBorderSide(BorderSide(color: AppColors.pillBorder)),
  );

  /// Count badge: a gold droplet with a cream rim.
  static const _badgeDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.accent,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.wordmark, width: 1.5),
    ),
  );

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled
            ? () {
                setState(() => _pressed = false);
                Haptics.instance.gameImpact();
                widget.onTap();
              }
            : null,
        // The disc icon and count badge are decorative: the Semantics label
        // above already conveys the action, so exclude them from the tree.
        // (Otherwise the badge number merges into the button's label.)
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: reduceMotion ? Duration.zero : AppDurations.instant,
            curve: AppCurves.emphasized,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: AppSizing.actionButton,
                  height: AppSizing.actionButton,
                  padding: const EdgeInsets.all(_haloPadding),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.settingsHalo,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: widget.enabled ? _enabledDisc : _disabledDisc,
                    child: Icon(
                      widget.icon,
                      color: widget.enabled
                          ? AppColors.wordmark
                          : AppColors.padLabelSoft,
                    ),
                  ),
                ),
                if (widget.badge != null && widget.badge! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: _badgeDecoration,
                      child: Text(
                        '${widget.badge}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
