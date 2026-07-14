// lib/features/splash/presentation/splash_scene.dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/brand_mark_geometry.dart';
import '../../../core/design/motion/curves.dart';
import '../../../core/design/tokens/colors.dart';
import '../../../core/design/tokens/durations.dart';
import '../../../core/design/tokens/gradients.dart';
import '../../../core/design/tokens/spacing.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../shared/widgets/brand_mark.dart';
import 'icon_slices.dart';

/// The cold-start splash: the app icon is cut into five blocks (four quadrant
/// tiles and the crimson bud keystone) that tumble in from off-screen and
/// bounce into place, reassembling the exact artwork; a soft mint glow blooms
/// behind and the wordmark settles. Calls [onComplete] once the sequence ends.
///
/// The blocks are clipped straight from `assets/branding/app_icon.png`, so the
/// splash uses the real icon. Until that PNG has been added the scene falls back
/// to the vector [BrandMark], so it always renders. Provider-free and
/// self-contained (it paints its own cream background); honors reduced motion.
class SplashScene extends StatefulWidget {
  const SplashScene({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene>
    with SingleTickerProviderStateMixin {
  static const String _iconAsset = 'assets/branding/app_icon.svg';

  // Per-block choreography (0..3 tiles, 4 bud). Fractions are of the
  // controller's run; the bud lands last as the keystone.
  static const List<double> _start = <double>[0.0, 0.08, 0.16, 0.24, 0.36];
  static const List<double> _end = <double>[0.30, 0.38, 0.46, 0.54, 0.66];
  static const List<double> _spin = <double>[-0.5, 0.45, 0.5, -0.45, -0.7];
  static const List<double> _drift = <double>[-0.10, 0.10, -0.08, 0.08, 0.0];
  static const List<double> _scale0 = <double>[0.7, 0.7, 0.7, 0.7, 0.5];

  late final AnimationController _controller;
  late final CurvedAnimation _glowFade;
  late final CurvedAnimation _wordFade;
  late final Animation<double> _glowScale;
  late final Animation<Offset> _wordSlide;
  bool _started = false;
  bool _reduce = false;
  bool _useVector = false;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppDurations.splashRun)
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.completed) widget.onComplete();
          });
    _glowFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: AppCurves.enter));
    _wordFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.90, curve: AppCurves.enter));
    _glowScale = Tween<double>(begin: 0.6, end: 1.0).animate(_glowFade);
    _wordSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(_wordFade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.duration =
        _reduce ? AppDurations.splashReduced : AppDurations.splashRun;
    // Warm the vector so the first block never renders on an unparsed picture.
    // The SVG ships with the bundle, so unlike the old PNG it cannot be missing;
    // a parse failure still falls back to the vector BrandMark rather than
    // stranding the splash on an empty box.
    vg
        .loadPicture(const SvgAssetLoader(_iconAsset), context)
        .then((_) => _begin(useVector: false))
        .catchError((Object _) => _begin(useVector: true));
  }

  void _begin({required bool useVector}) {
    if (!mounted || _resolved) return;
    setState(() {
      _resolved = true;
      _useVector = useVector;
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _glowFade.dispose();
    _wordFade.dispose();
    _controller.dispose();
    super.dispose();
  }

  double _seg(double v, double a, double b, Curve curve) =>
      curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  Alignment _pieceAlignment(int index) {
    if (_useVector) {
      final Offset c = BrandMarkGeometry.pieceCenter(index);
      return Alignment(c.dx / 50 - 1, c.dy / 50 - 1);
    }
    return IconSlices.alignment(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) return const ColoredBox(color: AppColors.paper);
    final Size size = MediaQuery.of(context).size;
    final double markSize = (size.shortestSide * 0.46).clamp(140.0, 240.0);
    // Blocks start fully above the visible area, so they drop in rather than
    // pop into existence.
    final double fall = size.height * 0.5 + markSize;
    return ColoredBox(
      color: AppColors.paper,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: markSize,
              height: markSize,
              child: _reduce
                  ? _restStack(markSize)
                  : _movingStack(markSize, fall),
            ),
            const SizedBox(height: AppSpacing.xl),
            _reduce
                ? _wordmarkText()
                : FadeTransition(
                    opacity: _wordFade,
                    child: SlideTransition(
                        position: _wordSlide, child: _wordmarkText()),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _restStack(double markSize) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[_glowBox(markSize), _fullMark(markSize)],
    );
  }

  Widget _movingStack(double markSize, double fall) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        FadeTransition(
          opacity: _glowFade,
          child: ScaleTransition(scale: _glowScale, child: _glowBox(markSize)),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              for (var i = 0; i < IconSlices.pieceCount; i++)
                _block(i, _controller.value, markSize, fall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _block(int i, double v, double markSize, double fall) {
    final double land = _seg(v, _start[i], _end[i], AppCurves.landing);
    final double smooth = _seg(v, _start[i], _end[i], AppCurves.enter);
    final double fallY = (1 - land) * (-fall);
    final double driftX = (1 - land) * (_drift[i] * markSize);
    final double angle = (1 - land) * _spin[i];
    final double scale = lerpDouble(_scale0[i], 1.0, smooth)!;
    return Transform.translate(
      offset: Offset(driftX, fallY),
      child: Transform(
        alignment: _pieceAlignment(i),
        transform: Matrix4.identity()
          ..rotateZ(angle)
          ..scaleByDouble(scale, scale, 1, 1),
        child: RepaintBoundary(child: _pieceChild(i, markSize)),
      ),
    );
  }

  /// One block: the icon clipped to piece [i]'s region, or the matching vector
  /// piece when the PNG is absent.
  Widget _pieceChild(int i, double markSize) {
    if (_useVector) return BrandMark(size: markSize, piece: i);
    return ClipPath(
      clipper: IconSlices.clipper(i),
      child: _iconImage(markSize),
    );
  }

  /// The whole assembled icon (vector fallback or the real PNG).
  Widget _fullMark(double markSize) =>
      _useVector ? BrandMark(size: markSize) : _iconImage(markSize);

  /// The mark itself. Vector (`app_icon.svg`), so it stays crisp at any density
  /// on both web and mobile instead of resampling the PNG.
  Widget _iconImage(double markSize) => SizedBox(
        width: markSize,
        height: markSize,
        child: SvgPicture.asset(
          _iconAsset,
          width: markSize,
          height: markSize,
          fit: BoxFit.fill,
        ),
      );

  Widget _glowBox(double markSize) {
    final double side = markSize * 1.7;
    return OverflowBox(
      maxWidth: side,
      maxHeight: side,
      child: SizedBox(
        width: side,
        height: side,
        child: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.splashGlow),
        ),
      ),
    );
  }

  Widget _wordmarkText() {
    return Text(
      'Agape Logos',
      style: AppTypography.splashWordmark.copyWith(color: AppColors.ink),
    );
  }
}
