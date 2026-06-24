// lib/shared/widgets/coming_soon_sheet.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/spacing.dart';

/// A small bottom sheet for not-yet-built features (Withdraw, Bonus, Settings,
/// Store). Shared by the home and level-complete pages.
Future<void> showComingSoon(BuildContext context, String feature) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        '$feature coming soon',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  );
}
