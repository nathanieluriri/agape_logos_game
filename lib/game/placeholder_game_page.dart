import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens/spacing.dart';

/// Stand-in for the real Flame game. Reached from Play once the player is signed
/// in. Intentionally minimal; the actual game replaces this later.
class PlaceholderGamePage extends StatelessWidget {
  const PlaceholderGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: BackButton(color: scheme.onPrimary),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game coming soon',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: scheme.onPrimary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // TEMP: dev-only seam until real gameplay exists.
                  Semantics(
                    button: true,
                    label: 'Finish level (dev)',
                    child: FilledButton(
                      onPressed: () => context.push('/level-complete'),
                      child: const ExcludeSemantics(
                        child: Text('Finish level (dev)'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
