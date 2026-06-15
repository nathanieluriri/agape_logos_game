import 'package:flutter/material.dart';

/// Raw color palette - the single source of truth for color.
///
/// Widgets must NOT use literal `Color(...)` values; reference these tokens
/// (or, preferably, the `ColorScheme` produced by `AppTheme`) instead.
abstract final class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF5B8A72);
  static const Color ink = Color(0xFF1A1C1A);
  static const Color paper = Color(0xFFF7F4EC);
  static const Color paperDark = Color(0xFF14160F);
  static const Color accent = Color(0xFFD9A441);
  static const Color danger = Color(0xFFB3261E);
}
