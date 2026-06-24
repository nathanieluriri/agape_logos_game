import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'pad_shadow_component.dart';
import 'ripple_component.dart';

/// Transparent ambient backdrop: a pond field of drifting pad shadows and
/// surface ripples painted over the gradient behind it.
/// Deliberately cheap (no input, no overlays).
class AmbientBackgroundGame extends FlameGame {
  AmbientBackgroundGame();

  // Fully transparent: the home gradient shows through this canvas.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final rng = Random();
    addAll(PadShadowComponent.field(size, rng));
    addAll(RippleComponent.field(size, rng));
  }
}
