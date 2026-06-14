import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Builds [ThemeData] from design tokens. The app reads theme from here —
/// no widget should hand-roll colors or text styles.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.paper);
  static ThemeData dark() => _build(Brightness.dark, AppColors.paperDark);

  static ThemeData _build(Brightness brightness, Color surface) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: AppTypography.textTheme(brightness),
    );
  }
}
