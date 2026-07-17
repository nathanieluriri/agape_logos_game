// lib/preview/splash_previews.dart
//
// Design previews for the brand mark and the cold-start splash. Run with:
//   flutter widget-preview start
// (or open the Widget Previews panel in the IDE on Flutter 3.38+).
//
// Provider-free, per the previewer's constraints: nothing here imports
// bootstrap, Drift, or the Flame ambient layer.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/design/tokens/colors.dart';
import '../features/splash/presentation/splash_scene.dart';
import '../shared/widgets/brand_mark.dart';

Widget _stage({double width = 390, double height = 844, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(color: AppColors.paper, child: child),
      ),
    ),
  );
}

@Preview(name: 'Brand mark (assembled)')
Widget brandMarkPreview() {
  return _stage(
    width: 320,
    height: 320,
    child: const Center(child: BrandMark(size: 220)),
  );
}

@Preview(name: 'Splash (animated)')
Widget splashScenePreview() {
  return _stage(child: SplashScene(onComplete: () {}));
}
