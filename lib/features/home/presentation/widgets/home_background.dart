import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/ambient/ambient_background_game.dart';

/// Toggles the Flame ambient layer. Defaults on; widget tests override it off so
/// the game loop does not run. Also a natural seam for a future reduce-motion or
/// low-end-device setting.
final homeAmbientEnabledProvider = Provider<bool>((ref) => true);

/// Whether the home's looping motion (Flame ambient + button controllers) is
/// paused. Set true while another route (the game) covers the home, so off-screen
/// animation does not burn CPU/battery.
class HomeAmbientPaused extends Notifier<bool> {
  @override
  bool build() => false;

  void pause(bool value) => state = value;
}

final homeAmbientPausedProvider =
    NotifierProvider<HomeAmbientPaused, bool>(HomeAmbientPaused.new);

/// Full-screen backdrop: a tokenized gradient with an optional Flame ambient
/// layer above it. The Flame layer never intercepts taps and degrades to just the
/// gradient if the game fails to start. Looping motion pauses when
/// [homeAmbientPausedProvider] is set (e.g. while the game route covers home).
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
    final paused = ref.watch(homeAmbientPausedProvider);

    // Pause/resume the Flame loop on change, without touching the lazily-created
    // game when the ambient layer is disabled.
    ref.listen<bool>(homeAmbientPausedProvider, (_, isPaused) {
      if (!ref.read(homeAmbientEnabledProvider)) return;
      if (isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });

    return TickerMode(
      enabled: !paused,
      child: Stack(
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
      ),
    );
  }
}
