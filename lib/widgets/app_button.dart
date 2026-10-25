import 'package:flutter/material.dart';

/// Visual variant of [AppButton].
enum AppButtonVariant { primary, secondary, danger }

/// Standard app button with primary / secondary / danger variants.
/// The label is supplied by the caller (always via AppLocalizations) —
/// this widget never hardcodes text.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == AppButtonVariant.primary
                  ? scheme.onPrimary
                  : scheme.primary,
            ),
          )
        : _Label(icon: icon, label: label);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _Label extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _Label({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    // Scale the label down to fit the button instead of clipping it when
    // the button sits in a tight row on a small phone.
    final fittedLabel = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
    if (icon == null) return fittedLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: fittedLabel),
      ],
    );
  }
}
