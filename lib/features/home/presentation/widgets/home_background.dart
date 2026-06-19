import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/ambient/ambient_background_game.dart';

/// Toggles the Flame ambient layer. Defaults on; widget tests override it off so
/// the game loop does not run. Also a natural seam for a future reduce-motion or
/// low-end-device setting.
final homeAmbientEnabledProvider = Provider<bool>((ref) => true);

/// Full-screen backdrop: a tokenized gradient with an optional Flame ambient
/// layer above it. The Flame layer never intercepts taps and degrades to just the
/// gradient if the game fails to start.
class HomeBackground extends ConsumerStatefulWidget {
  const HomeBackground({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<HomeBackground> createState() => _HomeBackgroundState();
}

class _HomeBackgroundState extends ConsumerState<HomeBackground> {
  late final AmbientBackgroundGame _game = AmbientBackgroundGame();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ambient = ref.watch(homeAmbientEnabledProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primaryContainer, scheme.primary],
            ),
          ),
        ),
        if (ambient)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: GameWidget(
                  game: _game,
                  // Degrade to the gradient if the game throws; never crash home.
                  errorBuilder: (_, __) => const SizedBox.shrink(),
                  loadingBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
