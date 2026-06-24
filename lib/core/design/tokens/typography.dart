import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography tokens, expressed as a [TextTheme] per [Brightness].
/// Memoized - the two possible outputs are built once for the app's lifetime.
abstract final class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'ZenSerif';

  /// "ZEN WORD" wordmark. Serif, airy letter-spacing, light weight.
  static const wordmark = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: ['serif'],
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: 2,
    height: 1.1,
  );

  /// Progress fraction ("5/8"). Serif, bold.
  static const numeral = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: ['serif'],
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static final TextTheme _light = _build(Brightness.light);
  static final TextTheme _dark = _build(Brightness.dark);

  static TextTheme textTheme(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static TextTheme _build(Brightness brightness) {
    final Color c = brightness == Brightness.dark ? AppColors.paper : AppColors.ink;
    return TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: c),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c),
      bodyLarge: TextStyle(fontSize: 16, color: c),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c),
    );
  }
}
