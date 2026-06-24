import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Builds [ThemeData] from design tokens. The app reads theme from here -
/// no widget should hand-roll colors or text styles.
///
/// Themes are computed once (static final) - `ColorScheme.fromSeed` is
/// expensive and the inputs are compile-time-constant tokens, so there is no
/// reason to rebuild them per frame.
abstract final class AppTheme {
  const AppTheme._();

  static final ThemeData light = _build(Brightness.light, AppColors.paper);
  static final ThemeData dark = _build(Brightness.dark, AppColors.paperDark);

  static ThemeData _build(Brightness brightness, Color surface) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.pond2,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: AppTypography.textTheme(brightness),
    );
  }
}
