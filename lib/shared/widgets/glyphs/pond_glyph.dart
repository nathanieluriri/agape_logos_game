// lib/shared/widgets/glyphs/pond_glyph.dart
import 'package:flutter/widgets.dart';

import 'glyph_paths.dart';
import 'pond_glyph_painter.dart';

export 'glyph_paths.dart' show PondGlyph;

/// A hand-painted pond glyph (the design system's replacement for Material
/// [Icon]s): cream face over a darker extrusion, same family as the Play
/// triangle. Purely decorative; wrap in your own [Semantics] when the glyph
/// carries meaning on its own.
class PondIcon extends StatelessWidget {
  const PondIcon(this.glyph, {super.key, this.size = 24});

  final PondGlyph glyph;

  /// Width and height of the square glyph box.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: PondGlyphPainter(glyph),
      ),
    );
  }
}
