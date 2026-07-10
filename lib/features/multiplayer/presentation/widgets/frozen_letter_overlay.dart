import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';

/// A frost disc over each currently frozen wheel node. Pure: the match page
/// recomputes [frozenSlots] against its ticker, so a disc vanishes when its
/// freeze lapses at `expiresAt`. Reduced motion changes nothing here (a static
/// tint, no pulse), so it is inherently accessible.
class FrozenLetterOverlay extends StatelessWidget {
  const FrozenLetterOverlay({
    super.key,
    required this.frozenSlots,
    required this.letterCount,
    required this.size,
  });

  /// Wheel SLOT indices (not rack letter indices) currently frozen.
  final Set<int> frozenSlots;
  final int letterCount;
  final Size size;

  static const double _node = AppSizing.wheelNode;

  @override
  Widget build(BuildContext context) {
    if (frozenSlots.isEmpty) return const SizedBox.shrink();
    final centers = LetterWheel.centersIn(size, letterCount);
    return IgnorePointer(
      child: Stack(
        children: [
          for (final slot in frozenSlots)
            if (slot >= 0 && slot < centers.length)
              Positioned(
                left: centers[slot].dx - _node / 2,
                top: centers[slot].dy - _node / 2,
                width: _node,
                height: _node,
                child: const _FrostDisc(),
              ),
        ],
      ),
    );
  }
}

class _FrostDisc extends StatelessWidget {
  const _FrostDisc();
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.frostFill,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.frostBorder, width: 2),
        ),
      ),
      child: const Icon(Icons.ac_unit_rounded,
          color: AppColors.frostBorder, size: 24),
    );
  }
}
