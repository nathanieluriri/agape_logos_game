import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_text_link.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';
import '../../domain/multiplayer_config.dart';

/// Forces input to upper case (the wire codes are case-insensitive; the client
/// always uppercases, contract 8.6).
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Join-code entry over the reduced [kMatchCodeAlphabet]. A plain uppercase text
/// field is the reliable default; a LetterWheel built from the alphabet is an
/// optional nicety (the small, unambiguous set makes wheel entry viable). Both
/// report the completed [kMatchCodeLength]-letter code via [onSubmit].
class JoinCodeEntry extends StatefulWidget {
  const JoinCodeEntry({super.key, required this.onSubmit, this.busy = false});

  final void Function(String code) onSubmit;
  final bool busy;

  @override
  State<JoinCodeEntry> createState() => _JoinCodeEntryState();
}

class _JoinCodeEntryState extends State<JoinCodeEntry> {
  final TextEditingController _text = TextEditingController();
  bool _wheelMode = false;
  String _wheelCode = '';
  List<int> _wheelSel = const [];

  static final List<String> _alphabet = kMatchCodeAlphabet.split('');

  String get _code => _wheelMode ? _wheelCode : _text.text;
  bool get _complete => _code.length == kMatchCodeLength;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _appendWheel(String letter) {
    if (_wheelCode.length >= kMatchCodeLength) return;
    setState(() => _wheelCode += letter);
  }

  void _backspaceWheel() {
    if (_wheelCode.isEmpty) return;
    setState(() =>
        _wheelCode = _wheelCode.substring(0, _wheelCode.length - 1));
  }

  void _submit() {
    if (!_complete || widget.busy) return;
    widget.onSubmit(_code.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter the 4-letter code',
          style: TextStyle(
            color: AppColors.wordmark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_wheelMode) _wheelInput() else _textInput(),
        const SizedBox(height: AppSpacing.md),
        PondPillButton(
          label: widget.busy ? 'Joining...' : 'Join',
          // PondPillButton.onPressed is non-nullable; `enabled` gates taps and
          // _submit re-guards completeness.
          enabled: _complete && !widget.busy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        PondTextLink(
          label: _wheelMode ? 'Type it instead' : 'Use the wheel',
          onTap: () => setState(() {
            _wheelMode = !_wheelMode;
            _wheelCode = '';
            _wheelSel = const [];
            _text.clear();
          }),
        ),
      ],
    );
  }

  Widget _textInput() {
    return TextField(
      controller: _text,
      autofocus: true,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        color: AppColors.pillText,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 12,
      ),
      decoration: const InputDecoration(
        filled: true,
        fillColor: AppColors.pillFill,
        hintText: 'ABCD',
        hintStyle:
            TextStyle(color: AppColors.padLabelSoft, letterSpacing: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.settingsBorder),
        ),
      ),
      inputFormatters: [
        const _UpperCaseFormatter(),
        FilteringTextInputFormatter.allow(RegExp('[$kMatchCodeAlphabet]')),
        LengthLimitingTextInputFormatter(kMatchCodeLength),
      ],
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _wheelInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _wheelCode.padRight(kMatchCodeLength, '.'),
          style: const TextStyle(
            color: AppColors.pillText,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Reuse the single-player LetterWheel over the code alphabet. Each drag
        // appends the letters it crossed (a quick tap adds one); repeats need a
        // fresh tap since a drag cannot re-enter a node.
        // PLAN: on device, confirm 20 wheel nodes are tappable without
        // crowding; if the wheel reads too dense, the keyboard remains the
        // default and the wheel is optional, so this is not a blocker.
        LetterWheel(
          letters: _alphabet,
          selected: _wheelSel,
          onTouch: (slot) => setState(() {
            if (!_wheelSel.contains(slot)) {
              _wheelSel = [..._wheelSel, slot];
            }
          }),
          onEnd: () {
            for (final s in _wheelSel) {
              if (s >= 0 && s < _alphabet.length) _appendWheel(_alphabet[s]);
            }
            setState(() => _wheelSel = const []);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSizing.actionButton,
          child: IconButton(
            onPressed: _wheelCode.isEmpty ? null : _backspaceWheel,
            icon: const Icon(Icons.backspace_outlined,
                color: AppColors.padLabelSoft),
            tooltip: 'Delete last letter',
          ),
        ),
      ],
    );
  }
}
