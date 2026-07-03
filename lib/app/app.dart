import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/theme/app_theme.dart';
import '../features/splash/presentation/splash_gate.dart';
import '../shared/widgets/tap_ripple_overlay.dart';
import 'router/app_router.dart';

class AgapeApp extends ConsumerWidget {
  const AgapeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Agape Logos',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // App-wide water-tap ripple over every screen (and dialogs), without
      // absorbing any gestures. The one-shot cold-start splash sits above it.
      builder: (context, child) => SplashGate(
        child: TapRippleOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
