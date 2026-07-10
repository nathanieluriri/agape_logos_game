import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/haptics/haptics.dart';
import 'glyphs/pond_glyph.dart';

/// Round Friends button that matches the settings gear: a translucent halo ring
/// around a gradient teal disc with a filled cream people glyph. Scales down on
/// press. Sits in the Home top bar next to the daily-gift button.
class FriendsButton extends StatefulWidget {
  const FriendsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<FriendsButton> createState() => _FriendsButtonState();
}

class _FriendsButtonState extends State<FriendsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Friends',
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
          child: Container(
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
        ),
      ),
    );
  }
}
