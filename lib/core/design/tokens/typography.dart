import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography tokens, expressed as a [TextTheme] built per [Brightness].
abstract final class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final Color c = brightness == Brightness.dark ? AppColors.paper : AppColors.ink;
    return TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: c),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c),
      bodyLarge: TextStyle(fontSize: 16, color: c),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c),
    );
  }
}
