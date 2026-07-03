// lib/features/splash/presentation/splash_gate.dart
import 'package:flutter/widgets.dart';

import '../../../core/design/motion/curves.dart';
import '../../../core/design/tokens/durations.dart';
import 'splash_scene.dart';

/// Hosts the one-shot cold-start splash over the app.
///
/// Wrapped around the router's content in `AgapeApp`, it shows [SplashScene]
/// on first build, absorbs input while the mark assembles, then fades the
/// overlay away to reveal the app. Its state persists across navigation, so
/// the splash plays once per app launch (not on every route change).
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _removed = false;
  bool _fading = false;

  void _onComplete() {
    if (mounted && !_fading) setState(() => _fading = true);
  }

  void _onFaded() {
    if (mounted && _fading && !_removed) setState(() => _removed = true);
  }

  @override
  Widget build(BuildContext context) {
    // Once the splash has faded out it is gone for the process's lifetime, so
    // drop the Stack entirely and pass the app through untouched.
    if (_removed) return widget.child;
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedOpacity(
                opacity: _fading ? 0.0 : 1.0,
                duration: AppDurations.splashFade,
                curve: AppCurves.exit,
                onEnd: _onFaded,
                child: SplashScene(onComplete: _onComplete),
              ),
            ),
          ),
      ],
    );
  }
}
