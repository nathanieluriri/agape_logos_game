// lib/shared/widgets/pond_background.dart
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens/gradients.dart';
import '../../features/home/presentation/widgets/home_background.dart'
    show homeAmbientPausedProvider, homeAmbientEnabledProvider;
import '../../game/ambient/ambient_background_game.dart';

/// Full-viewport pond: a static radial gradient with the drifting Flame
/// ambient layer above it (when enabled). Fills its parent; place [child]
/// above the pond.
class PondBackground extends ConsumerStatefulWidget {
  const PondBackground({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PondBackground> createState() => _PondBackgroundState();
}

class _PondBackgroundState extends ConsumerState<PondBackground> {
  late final AmbientBackgroundGame _game = AmbientBackgroundGame();

  @override
  Widget build(BuildContext context) {
    final ambientEnabled = ref.watch(homeAmbientEnabledProvider);

    ref.listen<bool>(homeAmbientPausedProvider, (_, isPaused) {
      if (!ref.read(homeAmbientEnabledProvider)) return;
      if (isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.pond),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ambientEnabled)
            IgnorePointer(
              child: RepaintBoundary(
                child: GameWidget(
                  game: _game,
                  // Degrade to the gradient if the game throws; never crash.
                  errorBuilder: (_, __) => const SizedBox.shrink(),
                  loadingBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}
