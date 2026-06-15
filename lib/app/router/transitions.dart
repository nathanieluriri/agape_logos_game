import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';

/// Shared animated page builder - every screen transition runs through a motion
/// token, so navigation always feels game-like and stays tunable in one place.
CustomTransitionPage<T> fadeThroughPage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.enter),
        child: child,
      );
    },
  );
}
