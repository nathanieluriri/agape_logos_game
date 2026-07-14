import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_sheet.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../../shared/widgets/pond_text_field.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../../profile/domain/handle_outcome.dart';
import '../../../profile/profile_config.dart';

/// Copy for a handle that fails [kHandlePattern]. Shown both as helper text and
/// as the inline error, so the rule reads the same before and after a rejection.
const String kHandleRuleText = '3-20 letters, numbers or _';

/// Opens the sheet that edits the player's display name and @handle.
Future<void> showEditIdentitySheet(BuildContext context) => showPondSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const EditIdentitySheet(),
);

/// Body of the identity sheet: display name + @handle, with the handle claim
/// validated locally first and then confirmed by the server. A rejected claim
/// keeps the sheet open with an inline error, never a false success.
class EditIdentitySheet extends ConsumerStatefulWidget {
  const EditIdentitySheet({super.key});

  @override
  ConsumerState<EditIdentitySheet> createState() => _EditIdentitySheetState();
}

class _EditIdentitySheetState extends ConsumerState<EditIdentitySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _handle;
  late final String _initialName;
  late final String _initialHandle;

  /// Server-supplied error for the handle field (taken / invalid); cleared on
  /// the next save attempt.
  String? _handleError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    _initialName = profile?.displayName ?? '';
    _initialHandle = profile?.handle ?? '';
    _name = TextEditingController(text: _initialName);
    _handle = TextEditingController(text: _initialHandle);
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Your name cannot be blank';
    if (name.length > kMaxDisplayNameLength) {
      return 'Keep it under $kMaxDisplayNameLength characters';
    }
    return null;
  }

  String? _validateHandle(String? value) {
    if (_handleError != null) return _handleError;
    final handle = (value ?? '').trim();
    // An empty field means "leave my handle as it is": the server has no way to
    // clear a handle (it must always be claimable/searchable), so a blank field
    // is never sent. See _save, which skips setHandle when the field is empty.
    if (handle.isEmpty) return null;
    if (!kHandlePattern.hasMatch(handle)) return kHandleRuleText;
    return null;
  }

  Future<void> _save() async {
    setState(() => _handleError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final name = _name.text.trim();
    final handle = _handle.text.trim();
    final bool nameChanged = name != _initialName;
    // An empty field is "no change to the handle", never a request to clear it.
    final bool handleChanged = handle.isNotEmpty && handle != _initialHandle;
    if (!nameChanged && !handleChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    if (nameChanged) {
      await ref.read(profileRepositoryProvider).updateDisplayName(uid, name);
    }
    if (!handleChanged) {
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop();
      return;
    }

    final outcome = await ref.read(profileRepositoryProvider).setHandle(handle);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case HandleChanged():
        // Refetch rather than invalidate: the controller's build() returns null,
        // so invalidating it would blank the identity card it feeds.
        unawaited(ref.read(profileControllerProvider.notifier).reload());
        Navigator.of(context).pop();
        showPondSnack(context, 'Handle updated');
      case HandleTaken():
        setState(() => _handleError = 'That handle is taken');
        _formKey.currentState?.validate();
      case HandleInvalid():
        setState(() => _handleError = kHandleRuleText);
        _formKey.currentState?.validate();
      case HandleUnavailable():
        showPondSnack(context, 'Could not reach the pond. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your identity',
              style: TextStyle(
                color: AppColors.padLabel,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Friends find you by your @handle.',
              style: TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            PondTextField(
              controller: _name,
              label: 'Display name',
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            PondTextField(
              controller: _handle,
              label: 'Handle',
              validator: _validateHandle,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                kHandleRuleText,
                style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PondPillButton(label: 'Save', enabled: !_busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
