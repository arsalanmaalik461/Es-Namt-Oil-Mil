import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Standard search bar used above lists. RTL-aware, localized hint.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hint,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // SearchBar inherits text direction from the ambient Directionality,
    // which follows the app locale (RTL for Urdu) — no explicit
    // textDirection needed.
    return SearchBar(
      controller: controller,
      onChanged: onChanged,
      autoFocus: autofocus,
      hintText: hint ?? l10n.common_search,
      leading: const Icon(Icons.search),
      trailing: [
        if (controller != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller!.clear();
              onChanged?.call('');
            },
          ),
      ],
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          color: scheme.onSurface,
        ),
      ),
      hintStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      backgroundColor: WidgetStatePropertyAll(scheme.surface),
      elevation: const WidgetStatePropertyAll(1),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
