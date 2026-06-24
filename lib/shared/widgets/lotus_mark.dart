// lib/shared/widgets/lotus_mark.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';

/// The pink lotus logo mark (SVG), with an optional soft vertical float.
class LotusMark extends StatefulWidget {
  const LotusMark({super.key, this.width = AppSizing.lotusWidth, this.float = true});

  final double width;
  final bool float;

  @override
  State<LotusMark> createState() => _LotusMarkState();
}

class _LotusMarkState extends State<LotusMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppDurations.slow * 3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.float && !reduce && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (reduce || !widget.float) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svg = DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadows.logo),
      child: SvgPicture.asset(
        'assets/branding/lotus.svg',
        width: widget.width,
      ),
    );
    if (!widget.float) return svg;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * AppCurves.float.transform(_c.value)),
        child: child,
      ),
      child: svg,
    );
  }
}
