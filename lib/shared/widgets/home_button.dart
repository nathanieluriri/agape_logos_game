// lib/shared/widgets/home_button.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/haptics/haptics.dart';

/// Round back-to-Home disc: the settings-gear silhouette with a back arrow.
/// Sits in the [PondTopBar] action slot on screens that are a leaf of Home.
class HomeButton extends StatefulWidget {
  const HomeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Home',
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
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.settingsInner,
                boxShadow: AppShadows.pill,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.wordmark,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
