import 'package:flutter/material.dart';

import '../../../../core/design/tokens/opacities.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// Placeholder logo mark + title. The mark is a neutral tokenized stand-in (no
/// lotus); [title] is swappable copy. Real branding art replaces the mark later.
class HomeBranding extends StatelessWidget {
  const HomeBranding({super.key, this.title = 'ZEN WORD'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Placeholder mark: swap for the supplied logo art.
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: AppOpacities.scrim),
            borderRadius: AppRadii.card,
          ),
          child: Icon(Icons.image_outlined, color: scheme.onPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(color: scheme.onPrimary, letterSpacing: 2),
        ),
      ],
    );
  }
}
