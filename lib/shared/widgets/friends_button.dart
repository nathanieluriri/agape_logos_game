import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';
import '../../features/social/application/social_providers.dart';
import 'glyphs/pond_glyph.dart';

/// Round Friends button that matches the settings gear: a translucent halo ring
/// around a gradient teal disc with a filled cream people glyph. Scales down on
/// press. When there are pending friend requests it carries a small count pill
/// on its top-right corner. Sits in the Home top bar next to the daily-gift
/// button.
class FriendsButton extends ConsumerStatefulWidget {
  const FriendsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  ConsumerState<FriendsButton> createState() => _FriendsButtonState();
}

class _FriendsButtonState extends ConsumerState<FriendsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingRequestCountProvider);
    return Semantics(
      button: true,
      label: pending > 0 ? 'Friends, $pending pending requests' : 'Friends',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          Haptics.instance.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: AppDurations.instant,
          child: Stack(
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
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.settingsInner,
                    boxShadow: AppShadows.pill,
                  ),
                  child: const PondIcon(PondGlyph.friends, size: 22),
                ),
              ),
              if (pending > 0)
                Positioned(
                  top: -AppSpacing.xs,
                  right: -AppSpacing.xs,
                  child: _RequestBadge(count: pending),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small danger-coloured count pill for pending friend requests. Caps the
/// displayed value at 9+ so it never grows the disc's footprint.
class _RequestBadge extends StatelessWidget {
  const _RequestBadge({required this.count});

  final int count;

  /// Minimum diameter so a single digit still reads as a round pill.
  static const double _minSize = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: _minSize,
        minHeight: _minSize,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.markCream, width: 1.5),
        boxShadow: AppShadows.pill,
      ),
      child: ExcludeSemantics(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: AppColors.markCream,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
