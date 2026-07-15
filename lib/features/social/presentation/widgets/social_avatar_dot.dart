import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';

/// A small pond-colored disc showing a name's first initial. Avatars have no art
/// assets yet, so this is the stand-in used across friend tiles and search rows.
class SocialAvatarDot extends StatelessWidget {
  const SocialAvatarDot({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.lilyGreen,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.padLabel,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
