import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The tutorial's coach speech pill: a light paper capsule floating over the
/// scrim, with every occurrence of [highlight] inside [message] picked out
/// in the accent gold so the target word pops.
class TutorialMessagePill extends StatelessWidget {
  const TutorialMessagePill({super.key, required this.message, this.highlight});

  final String message;

  /// The word to color and embolden inside [message] (usually the tutorial's
  /// current target). Null or absent substrings render the plain message.
  final String? highlight;

  static const _baseStyle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );

  static const _highlightStyle = TextStyle(
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
  );

  static const _decoration = BoxDecoration(
    gradient: AppGradients.tutorialPill,
    borderRadius: AppRadii.pill,
    boxShadow: AppShadows.pill,
    border: Border.fromBorderSide(BorderSide(color: AppColors.pillBorder)),
  );

  /// Splits [message] around every occurrence of [highlight], styling the
  /// matches with the accent style.
  List<InlineSpan> _spans() {
    final word = highlight;
    if (word == null || word.isEmpty) return [TextSpan(text: message)];
    final spans = <InlineSpan>[];
    var from = 0;
    while (true) {
      final at = message.indexOf(word, from);
      if (at == -1) break;
      if (at > from) spans.add(TextSpan(text: message.substring(from, at)));
      spans.add(TextSpan(text: word, style: _highlightStyle));
      from = at + word.length;
    }
    if (from < message.length) {
      spans.add(TextSpan(text: message.substring(from)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppSizing.tutorialPillMaxWidth,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: _decoration,
      child: Text.rich(
        TextSpan(style: _baseStyle, children: _spans()),
        textAlign: TextAlign.center,
      ),
    );
  }
}
