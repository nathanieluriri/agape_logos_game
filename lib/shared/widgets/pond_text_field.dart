// lib/shared/widgets/pond_text_field.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/radii.dart';

/// Pond text input: a filled, rounded form field tuned for dark water
/// surfaces (sheets, dialogs, pages). The app-wide stand-in for the default
/// [TextFormField] styling; validation copy glows in the danger tones.
class PondTextField extends StatelessWidget {
  const PondTextField({
    super.key,
    this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
  });

  /// Optional controller; the field manages its own state when null.
  final TextEditingController? controller;

  /// Floating label shown inside the field.
  final String label;

  /// Optional validator run by the enclosing [Form].
  final String? Function(String?)? validator;

  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  static const _enabledBorder = OutlineInputBorder(
    borderRadius: AppRadii.card,
    borderSide: BorderSide(color: AppColors.settingsBorder),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: AppRadii.card,
    borderSide: BorderSide(color: AppColors.plusButtonBorder, width: 2),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: AppRadii.card,
    borderSide: BorderSide(color: AppColors.dangerBorder),
  );

  static const _focusedErrorBorder = OutlineInputBorder(
    borderRadius: AppRadii.card,
    borderSide: BorderSide(color: AppColors.dangerBorder, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      cursorColor: AppColors.accent,
      style: const TextStyle(color: AppColors.padLabel, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.pillFill,
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _focusedErrorBorder,
        labelStyle: const TextStyle(color: AppColors.padLabelSoft),
        floatingLabelStyle: const TextStyle(color: AppColors.padLabel),
        errorStyle: const TextStyle(
          color: AppColors.dangerOnPond,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
