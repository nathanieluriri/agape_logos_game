import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/tokens/sizing.dart';

/// The tutorial's pointing glove. Positioning the widget at an anchor point
/// places the index fingertip exactly on that point: the art keeps its tip
/// at a fixed fraction of the viewBox and the widget translates by it.
class TutorialHand extends StatelessWidget {
  const TutorialHand({super.key});

  /// Fingertip position inside `assets/tutorial/hand.svg`, as fractions of
  /// its 100x100 viewBox (the tip is drawn at roughly (30, 8)).
  static const double _tipFractionX = 0.30;
  static const double _tipFractionY = 0.08;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(
        -_tipFractionX * AppSizing.tutorialHand,
        -_tipFractionY * AppSizing.tutorialHand,
      ),
      child: SvgPicture.asset(
        'assets/tutorial/hand.svg',
        width: AppSizing.tutorialHand,
        height: AppSizing.tutorialHand,
      ),
    );
  }
}
