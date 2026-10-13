import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Standard text field: rounded, filled (via theme), RTL-aware.
///
/// Validation helpers live in [AppValidators] and use localized messages.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.autofocus = false,
  });

  /// Numeric field for money/quantity entry. Shows a numeric keyboard and
  /// restricts input to digits + one decimal separator.
  AppTextField.numeric({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
  })  : keyboardType = const TextInputType.numberWithOptions(decimal: true),
        inputFormatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ];

  @override
  Widget build(BuildContext context) {
    // Directionality comes from the app locale; textAlign follows it so
    // Urdu input naturally aligns right and English aligns left.
    final direction = Directionality.of(context);
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      textDirection: direction,
      textAlign:
          direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}

/// Localized field validators shared across all screens.
class AppValidators {
  const AppValidators._();

  static String? Function(String?) required(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return (value) {
      if (value == null || value.trim().isEmpty) return l10n.val_required;
      return null;
    };
  }

  /// Accepts a positive decimal number (e.g. "1500" or "1500.50").
  static String? Function(String?) amount(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return l10n.val_required;
      final parsed = double.tryParse(text);
      if (parsed == null || parsed <= 0) return l10n.val_invalidAmount;
      return null;
    };
  }

  /// Pakistani phone numbers: optional leading +, 10–15 digits total.
  static String? Function(String?) phone(BuildContext context,
      {bool required = false}) {
    final l10n = AppLocalizations.of(context);
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return required ? l10n.val_required : null;
      }
      final digitsOnly = text.replaceAll(RegExp(r'[\s\-()]'), '');
      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(digitsOnly)) {
        return l10n.val_invalidPhone;
      }
      return null;
    };
  }
}
