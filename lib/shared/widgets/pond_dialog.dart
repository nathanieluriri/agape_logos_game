// lib/shared/widgets/pond_dialog.dart
import 'package:flutter/material.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'lily_pad.dart';

/// Shows a pond-styled dialog: a deep-water card that fades and grows in over
/// a teal scrim. The app-wide stand-in for [AlertDialog].
///
/// [actions] are laid out in a row and stretched to share the width evenly,
/// so a single action spans the card. Pass [showPad] false to drop the
/// decorative lily pad above the title. An optional [content] widget (e.g. a
/// text field) sits between the body copy and the action row.
Future<T?> showPondDialog<T>({
  required BuildContext context,
  required String title,
  String? body,
  Widget? content,
  List<Widget> actions = const [],
  bool showPad = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.pondScrim,
    transitionDuration: AppDurations.normal,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.enter);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => _PondDialogCard(
      title: title,
      body: body,
      content: content,
      actions: actions,
      showPad: showPad,
    ),
  );
}

/// The centered deep-water card holding a dialog's pad, title, body copy,
/// and action row.
class _PondDialogCard extends StatelessWidget {
  const _PondDialogCard({
    required this.title,
    required this.body,
    required this.content,
    required this.actions,
    required this.showPad,
  });

  final String title;
  final String? body;
  final Widget? content;
  final List<Widget> actions;
  final bool showPad;

  /// Diameter of the decorative pad above the title.
  static const double _padSize = 44;

  static const _cardDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: AppRadii.pill,
    border: Border.fromBorderSide(BorderSide(color: AppColors.settingsBorder)),
    boxShadow: AppShadows.logo,
  );

  List<Widget> _actionRowChildren() => [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: actions[i]),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    // The view-inset padding keeps the card (and any text field in
    // [content]) above the keyboard, mirroring Material's Dialog.
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSizing.dialogMaxWidth),
            child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: _cardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showPad) ...[
                      const LilyPad(
                        size: _padSize,
                        palette: LilyPadPalette.teal,
                        shape: PadShape.smooth,
                        shadow: false,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.padLabel,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      // Long copy scrolls instead of overflowing the card on
                      // short viewports.
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(
                            body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.padLabelSoft,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      content!,
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(children: _actionRowChildren()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
