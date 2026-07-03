import 'package:flutter/animation.dart';

/// Animation curve tokens, paired conceptually with [AppDurations].
abstract final class AppCurves {
  const AppCurves._();

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve float = Curves.easeInOut;

  /// Springy overshoot for celebratory pops (combo banner, streak beats).
  static const Curve pop = Curves.easeOutBack;

  /// A block dropping and bouncing into its slot as the splash mark assembles.
  static const Curve landing = Curves.bounceOut;
}
