import 'package:flutter/animation.dart';

/// Animation curve tokens, paired conceptually with [AppDurations].
abstract final class AppCurves {
  const AppCurves._();

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve float = Curves.easeInOut;
}
