// lib/shared/widgets/pond_stage.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/sizing.dart';

/// Layout-only scaffold: centers content in a max-width portrait column.
/// Overflow-safe: when the viewport is tall enough the column fills it
/// (Spacers distribute); when content exceeds the viewport it scrolls instead
/// of overflowing. Does NOT paint the pond (PondBackground is the outer layer).
class PondStage extends StatelessWidget {
  const PondStage({super.key, required this.child}) : _scrolls = true;

  /// For pages that own their scrolling (a `ListView`, `CustomScrollView`, or a
  /// `SingleChildScrollView` inside an `Expanded`). The stage then ONLY applies
  /// the safe area and the max-width column, and fills the viewport.
  ///
  /// The default constructor wraps the child in `SingleChildScrollView` +
  /// `IntrinsicHeight`, and a viewport cannot report intrinsic dimensions
  /// ("RenderViewport does not support returning intrinsic dimensions"), so a
  /// page with an inner scrollable MUST use this variant.
  const PondStage.fill({super.key, required this.child}) : _scrolls = false;

  final Widget child;

  /// Whether the stage provides the scrolling (default) or the child does.
  final bool _scrolls;

  @override
  Widget build(BuildContext context) {
    final Widget column = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.stageMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
    if (!_scrolls) return SafeArea(child: column);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: column),
            ),
          );
        },
      ),
    );
  }
}
