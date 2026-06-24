// lib/shared/widgets/pond_stage.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/sizing.dart';

/// Layout-only scaffold: centers content in a max-width portrait column.
/// Overflow-safe: when the viewport is tall enough the column fills it
/// (Spacers distribute); when content exceeds the viewport it scrolls instead
/// of overflowing. Does NOT paint the pond (PondBackground is the outer layer).
class PondStage extends StatelessWidget {
  const PondStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: AppSizing.stageMaxWidth),
                    child: SizedBox(width: double.infinity, child: child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
