import 'package:agape_logos_game/game/ambient/ambient_background_game.dart';
import 'package:agape_logos_game/game/ambient/bokeh_component.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWithGame<AmbientBackgroundGame>(
    'loads the configured number of bokeh components',
    () => AmbientBackgroundGame(bokehCount: 5),
    (game) async {
      await game.ready();
      expect(game.children.whereType<BokehComponent>().length, 5);
    },
  );
}
