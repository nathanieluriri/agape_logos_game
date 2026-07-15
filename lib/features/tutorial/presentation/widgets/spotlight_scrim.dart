import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';

/// The two holes the tutorial punches through its near-black scrim: a circle
/// around the letter wheel and a rounded rect around the word board. Either
/// may be null while the overlay is still resolving on-screen geometry.
class SpotlightCutouts {
  const SpotlightCutouts({this.wheelRect, this.boardRect});

  /// The wheel's bounds in overlay coordinates; the cutout circle is derived
  /// from its center and shortest side.
  final Rect? wheelRect;

  /// The word board's bounds in overlay coordinates.
  final Rect? boardRect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotlightCutouts &&
          other.wheelRect == wheelRect &&
          other.boardRect == boardRect;

  @override
  int get hashCode => Object.hash(wheelRect, boardRect);
}

/// Paints the tutorial scrim: the whole overlay filled with a near-black
/// teal, minus the wheel circle and board rounded rect, each rimmed with the
/// pads' light glow so the cutouts read as lit rather than merely missing.
class SpotlightScrimPainter extends CustomPainter {
  const SpotlightScrimPainter({required this.cutouts});

  final SpotlightCutouts cutouts;

  /// Rim glow stroke width along each cutout edge.
  static const double _rimStroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    // Never darken the letter wheel. Until its cutout rect has been resolved
    // (the game page's first layout, or a mid-tutorial FittedBox rescale), skip
    // the scrim entirely rather than lay a hole-less black layer over the wheel.
    // The dim reappears with its wheel cutout the moment the geometry is known.
    if (cutouts.wheelRect == null) return;

    var scrim = Path()..addRect(Offset.zero & size);

    final wheelRect = cutouts.wheelRect;
    Path? wheelHole;
    if (wheelRect != null) {
      wheelHole = Path()
        ..addOval(
          Rect.fromCircle(
            center: wheelRect.center,
            radius: wheelRect.shortestSide / 2 + AppSizing.tutorialCutoutPad,
          ),
        );
      scrim = Path.combine(PathOperation.difference, scrim, wheelHole);
    }

    final boardRect = cutouts.boardRect;
    Path? boardHole;
    if (boardRect != null) {
      boardHole = Path()
        ..addRRect(
          AppRadii.card.toRRect(boardRect.inflate(AppSizing.tutorialCutoutPad)),
        );
      scrim = Path.combine(PathOperation.difference, scrim, boardHole);
    }

    canvas.drawPath(scrim, Paint()..color = AppColors.tutorialScrim);

    if (wheelHole != null) _strokeRim(canvas, wheelHole);
    if (boardHole != null) _strokeRim(canvas, boardHole);
  }

  /// Soft light rim along a cutout edge, brightest at the top (the same glow
  /// recipe the lily pads use).
  void _strokeRim(Canvas canvas, Path hole) {
    canvas.drawPath(
      hole,
      Paint()
        ..shader = AppGradients.padRimGlow.createShader(hole.getBounds())
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimStroke,
    );
  }

  @override
  bool shouldRepaint(SpotlightScrimPainter old) => old.cutouts != cutouts;
}

/// Blocks pointer input everywhere except inside the wheel cutout circle,
/// where it lets events fall straight through to the letter wheel below.
/// The board cutout stays non-interactive: the board is display-only.
class SpotlightBarrier extends SingleChildRenderObjectWidget {
  const SpotlightBarrier({
    super.key,
    this.wheelCenter,
    this.wheelRadius = 0,
    super.child,
  });

  /// Center of the interactive circle in this widget's local coordinates,
  /// or null to block everything (geometry not resolved yet).
  final Offset? wheelCenter;

  final double wheelRadius;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSpotlightBarrier(
        wheelCenter: wheelCenter,
        wheelRadius: wheelRadius,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSpotlightBarrier renderObject,
  ) {
    renderObject
      ..wheelCenter = wheelCenter
      ..wheelRadius = wheelRadius;
  }
}

/// Render box for [SpotlightBarrier]: transparent to hits inside the wheel
/// circle, opaque (absorbing) everywhere else within its bounds.
class RenderSpotlightBarrier extends RenderProxyBox {
  RenderSpotlightBarrier({
    required Offset? wheelCenter,
    required double wheelRadius,
  })  : _wheelCenter = wheelCenter, // ignore: prefer_initializing_formals
        _wheelRadius = wheelRadius; // ignore: prefer_initializing_formals

  Offset? _wheelCenter;
  set wheelCenter(Offset? value) => _wheelCenter = value;

  double _wheelRadius;
  set wheelRadius(double value) => _wheelRadius = value;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final center = _wheelCenter;
    if (center != null && (position - center).distance <= _wheelRadius) {
      // Inside the spotlight: let the pointer reach the wheel underneath.
      return false;
    }
    if (size.contains(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
