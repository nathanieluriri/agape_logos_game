// lib/shared/widgets/wordmark_logo.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/design/tokens/typography.dart';
import 'lotus_mark.dart';

/// The lotus mark above the serif "ZEN WORD" wordmark.
class WordmarkLogo extends StatelessWidget {
  const WordmarkLogo({super.key, this.title = 'ZEN WORD', this.float = true});

  final String title;
  final bool float;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LotusMark(float: float),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.wordmark.copyWith(color: AppColors.wordmark),
        ),
      ],
    );
  }
}
