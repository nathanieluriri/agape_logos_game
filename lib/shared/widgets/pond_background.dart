// lib/shared/widgets/pond_background.dart
import 'package:flutter/widgets.dart';

/// Passthrough kept for the page call sites. The pond (gradient + Flame ambient
/// layer) is now a single app-level layer beneath the Navigator (`PondShell`),
/// so a page must not paint its own: it floats transparently over the shell.
class PondBackground extends StatelessWidget {
  const PondBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
