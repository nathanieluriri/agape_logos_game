// lib/shared/widgets/pond_sheet.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';

/// Shows a pond-styled modal bottom sheet: deep-water card, hand-rolled drag
/// bar, teal scrim. The shared chrome behind the auth, coming-soon and
/// multiplayer sheets, so every rising surface reads the same.
Future<T?> showPondSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  Haptics.instance.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.pondScrim,
    isScrollControlled: isScrollControlled,
    builder: (context) => PondSheetScaffold(child: builder(context)),
  );
}

/// The deep-water sheet body: gradient card with rounded top corners, a
/// hairline top border, a drag bar, and safe-area padding around [child].
class PondSheetScaffold extends StatelessWidget {
  const PondSheetScaffold({super.key, required this.child});

  final Widget child;

  /// Hand-rolled drag bar dimensions (shared with the auth sheet).
  static const double _dragBarWidth = 40;
  static const double _dragBarHeight = 4;

  static const _sheetDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
    ),
    border: Border(top: BorderSide(color: AppColors.settingsBorder)),
  );

  static const _dragBarDecoration = BoxDecoration(
    color: AppColors.settingsBorder,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _sheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: _dragBarWidth,
                  height: _dragBarHeight,
                  child: DecoratedBox(decoration: _dragBarDecoration),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
