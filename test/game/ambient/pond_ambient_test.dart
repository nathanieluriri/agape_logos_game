import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agape_logos_game/game/ambient/ambient_background_game.dart';
import 'package:agape_logos_game/game/ambient/pad_shadow_component.dart';
import 'package:agape_logos_game/game/ambient/ripple_component.dart';

void main() {
  testWithGame<AmbientBackgroundGame>(
    'pond ambient loads shadows and ripples',
    AmbientBackgroundGame.new,
    (game) async {
      game.onGameResize(Vector2(384, 832));
      await game.ready();
      expect(game.children.whereType<PadShadowComponent>(), isNotEmpty);
      expect(game.children.whereType<RippleComponent>(), isNotEmpty);
    },
  );
}
