// lib/core/design/tokens/shadows.dart
import 'package:flutter/widgets.dart';

/// Soft drop-shadow tokens for the pond theme. (Material inset shadows are not
/// representable with BoxShadow; the inner highlights from the reference are
/// approximated with translucent borders on the relevant widgets.)
abstract final class AppShadows {
  const AppShadows._();

  static const pad = [
    BoxShadow(color: Color(0x3D000000), blurRadius: 11, offset: Offset(0, 9)),
  ];

  static const pill = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const logo = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 10)),
  ];

  static const track = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
}
