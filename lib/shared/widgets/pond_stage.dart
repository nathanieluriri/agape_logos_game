// lib/shared/widgets/pond_stage.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/sizing.dart';

/// Layout-only scaffold: centers content in a max-width portrait column.
/// Does NOT paint the pond (PondBackground is the outer layer).
class PondStage extends StatelessWidget {
  const PondStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizing.stageMaxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
