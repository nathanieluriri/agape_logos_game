// lib/shared/widgets/coin_pill.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/haptics/haptics.dart';
import 'petal_icon.dart';

/// Currency chip: a pink petal coin straddling the pill's left edge, the
/// animated count-up amount, and a round plus button on the right.
///
/// The widget's own box reserves the petal's overhang on the left, so the petal
/// only ever paints over the pill, never over a neighbour (e.g. the level title
/// in the game top bar). Kept compact so it never crowds the rest of a top bar.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.amount, this.onAdd});

  final int amount;
  final VoidCallback? onAdd;

  /// Width reserved to the left of the pill for the petal's overhang, so it
  /// stays inside the CoinPill's own footprint.
  static const double _petalOverhang = 16;

  /// Pill body insets: the left clears the petal's overlap, the right clears the
  /// plus button; the vertical is tight so the chip stays short.
  static const EdgeInsets _pillPadding = EdgeInsets.fromLTRB(30, 5, 34, 5);

  /// Diameter of the round add button.
  static const double _plusSize = 28;

  static String _grouped(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _petalOverhang),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Container(
            padding: _pillPadding,
            decoration: BoxDecoration(
              color: AppColors.pillFill,
              borderRadius: AppRadii.pill,
              border: Border.all(color: AppColors.pillBorder),
              boxShadow: AppShadows.pill,
            ),
            child: TweenAnimationBuilder<int>(
              duration: AppDurations.slow,
              tween: IntTween(begin: 0, end: amount),
              builder: (context, value, _) => Text(
                _grouped(value),
                style: const TextStyle(
                  color: AppColors.pillText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          // Petal straddling the pill's left edge. Its left edge lands at the
          // CoinPill's own left bound (via the reserved overhang above), and it
          // is vertically centred on the pill by the stack alignment.
          const Positioned(
            left: -_petalOverhang,
            child: ExcludeSemantics(
              child: PetalIcon(size: AppSizing.coinPetal),
            ),
          ),
          Positioned(
            right: 2,
            child: Semantics(
              button: true,
              label: 'Add petals',
              child: GestureDetector(
                onTap: onAdd == null
                    ? null
                    : () {
                        Haptics.instance.lightImpact();
                        onAdd!();
                      },
                child: Container(
                  width: _plusSize,
                  height: _plusSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.plusButton,
                    border: Border.all(color: AppColors.plusButtonBorder, width: 2),
                    boxShadow: AppShadows.pill,
                  ),
                  child: const ExcludeSemantics(
                    child: CustomPaint(
                      size: Size(12, 12),
                      painter: _PlusCrossPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A chunky rounded cross, matching the reference plus button.
class _PlusCrossPainter extends CustomPainter {
  const _PlusCrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.padLabel;
    final bar = size.width * 0.3;
    final radius = Radius.circular(bar / 2);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: size.width,
            height: bar,
          ),
          radius,
        ),
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: bar,
            height: size.height,
          ),
          radius,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _PlusCrossPainter oldDelegate) => false;
}
