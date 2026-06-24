import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../application/home_controller.dart';
import 'currency_pill.dart';

/// Home chrome row: settings gear (left), currency pill + add (right). The gear
/// and add are placeholder actions for now (see HomePage).
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, this.onSettings, this.onAdd});

  final VoidCallback? onSettings;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(homeControllerProvider.select((s) => s.currency));
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onSettings,
            icon: Icon(Icons.settings, color: scheme.onPrimary),
          ),
          CurrencyPill(amount: amount, onAdd: onAdd),
        ],
      ),
    );
  }
}
