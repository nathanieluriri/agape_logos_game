// lib/app/pond_shell.dart
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/tokens/gradients.dart';
import '../game/ambient/ambient_background_game.dart';
import '../game/ambient/ambient_providers.dart'
    show ambientEnabledProvider, ambientPausedProvider;

/// The one pond for the whole app: the static radial gradient plus the drifting
/// Flame ambient layer, mounted once beneath the router's Navigator so a single
/// [AmbientBackgroundGame] survives every route change. Pages render
/// transparently above it.
class PondShell extends ConsumerStatefulWidget {
  const PondShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PondShell> createState() => _PondShellState();
}

class _PondShellState extends ConsumerState<PondShell> {
  late final AmbientBackgroundGame _game = AmbientBackgroundGame();

  @override
  Widget build(BuildContext context) {
    final ambientEnabled = ref.watch(ambientEnabledProvider);

    ref.listen<bool>(ambientPausedProvider, (_, isPaused) {
      if (!ref.read(ambientEnabledProvider)) return;
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
