// lib/shared/widgets/petal_icon.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/tokens/sizing.dart';

/// The app's currency mark: the pink petal from the brand kit
/// (`assets/branding/coin_petal.svg`). This is the SINGLE source of truth for
/// the currency glyph. Every balance, cost, and loader that shows the currency
/// renders this instead of duplicating the asset path or drawing an ad-hoc gold
/// dot.
///
/// [size] sets the render WIDTH; the height follows the SVG's intrinsic aspect
/// ratio (the viewBox is 618x626, nearly but not exactly square), so the petal
/// never distorts. Purely decorative: callers that need a semantics label or
/// pointer handling wrap this (e.g. CoinPill wraps it in `ExcludeSemantics`,
/// PondLoader in `IgnorePointer`).
class PetalIcon extends StatelessWidget {
  const PetalIcon({super.key, this.size = AppSizing.petalIconMd});

  /// Render width in logical pixels. Height follows the petal's aspect ratio.
  final double size;

  /// The one canonical path to the currency petal vector. Referenced here so no
  /// other file hard-codes the string.
  static const String asset = 'assets/branding/coin_petal.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size);
  }
}
