import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Shows a localized delete-confirmation dialog.
///
/// Returns `true` when the user confirms, `false` otherwise
/// (including dismiss).
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final dialogL10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        title: Text(title ?? dialogL10n.confirmDelete_title),
        content: Text(message ?? dialogL10n.confirmDelete_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? dialogL10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onError,
                  )
                : null,
            child: Text(confirmLabel ?? dialogL10n.common_delete),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
