// lib/shared/widgets/versus_mark.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The "VS" mark: the hand-drawn `assets/branding/vs.svg`, used wherever a
/// versus/challenge affordance appears (the Home Versus pad, the multiplayer
/// sheet, the challenge sheet, and the friend-tile challenge button). Replaces
/// the old painted `PondGlyph.versus`. The artwork carries its own colors, so it
/// is rendered as authored (cream lettering) rather than tinted.
class VersusMark extends StatelessWidget {
  const VersusMark({super.key, this.size = 24});

  /// Width and height of the square mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.asset(
        'assets/branding/vs.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
