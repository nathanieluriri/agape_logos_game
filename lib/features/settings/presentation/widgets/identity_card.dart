import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../profile/application/profile_providers.dart';
import 'edit_identity_sheet.dart';
import 'settings_action_row.dart';

/// The player's own identity row inside the Social section: display name, the
/// searchable `@handle` (the whole point of the feature: visible and copyable),
/// a copy button, and a tap target that opens the edit sheet.
///
/// The handle is deliberately NOT cached in Drift, so it is read from
/// [profileControllerProvider] (the live `GET /me`), never from the cached
/// profile, which always reports an empty handle.
class IdentityCard extends ConsumerWidget {
  const IdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // Mirrors PublicProfileSwitchRow's signed-out state.
      return SettingsActionRow(
        label: 'Sign in to pick your @handle',
        onTap: () => context.push('/sign-in'),
      );
    }
    final profile = ref.watch(profileControllerProvider).value;
    return _IdentityRow(
      displayName: profile?.displayName ?? '',
      handle: profile?.handle ?? '',
    );
  }
}

class _IdentityRow extends StatefulWidget {
  const _IdentityRow({required this.displayName, required this.handle});

  final String displayName;
  final String handle;

  @override
  State<_IdentityRow> createState() => _IdentityRowState();
}

class _IdentityRowState extends State<_IdentityRow> {
  /// Diameter of the round copy chip (matches SettingsActionRow's glyph chip).
  static const double _chipSize = 26;
  static const double _glyphSize = 16;

  bool _pressed = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: '@${widget.handle}'));
    if (!mounted) return;
    showPondSnack(context, 'Handle copied');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasHandle = widget.handle.isNotEmpty;
    final String name = widget.displayName.isEmpty
        ? 'Your name'
        : widget.displayName;
    return Semantics(
      button: true,
      label: 'Edit your name and handle',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          showEditIdentitySheet(context);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.padLabel,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        hasHandle ? '@${widget.handle}' : '-',
                        semanticsLabel: hasHandle
                            ? 'Your handle, at ${widget.handle}'
                            : 'No handle yet',
                        style: const TextStyle(
                          color: AppColors.padLabelSoft,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasHandle)
                  IconButton(
                    tooltip: 'Copy handle',
                    onPressed: _copy,
                    iconSize: _glyphSize,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(_chipSize),
                      backgroundColor: AppColors.settingsHalo,
                      foregroundColor: AppColors.padLabel,
                    ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: _chipSize,
                  height: _chipSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.settingsHalo,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: _glyphSize,
                    color: AppColors.padLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
