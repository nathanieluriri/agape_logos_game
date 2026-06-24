import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'bokeh_component.dart';

/// Transparent ambient backdrop: a small, capped field of drifting bokeh painted
/// over the gradient behind it. Deliberately cheap (no input, no overlays).
class AmbientBackgroundGame extends FlameGame {
  AmbientBackgroundGame({this.bokehCount = 7, int seed = 7})
      : _rng = Random(seed);

  final int bokehCount;
  final Random _rng;

  // Fully transparent: the home gradient shows through this canvas.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    addAll(BokehComponent.field(size, bokehCount, _rng));
  }
}
