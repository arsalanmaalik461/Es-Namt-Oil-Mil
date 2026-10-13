import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/utils/error_text.dart';

/// Minimal search-and-pick dialogs used by report filters.
///
/// These are deliberately self-contained (Agent C owns the full
/// customer/supplier screens); they only need an id + display name for
/// filtering reports.

/// Shows a customer picker; returns the picked customer id, or null.
Future<int?> pickCustomerId(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _PartyPickerDialog.customer(),
  );
}

/// Shows a supplier picker; returns the picked supplier id, or null.
Future<int?> pickSupplierId(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _PartyPickerDialog.supplier(),
  );
}

/// Shows a product picker; returns the picked product id, or null.
Future<int?> pickProductId(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _ProductPickerDialog(),
  );
}

class _PickResult {
  final int id;
  final String name;
  const _PickResult(this.id, this.name);
}

class _PartyPickerDialog extends ConsumerStatefulWidget {
  final bool isCustomer;

  const _PartyPickerDialog.customer() : isCustomer = true;
  const _PartyPickerDialog.supplier() : isCustomer = false;

  @override
  ConsumerState<_PartyPickerDialog> createState() => _PartyPickerDialogState();
}

class _PartyPickerDialogState extends ConsumerState<_PartyPickerDialog> {
  final _search = TextEditingController();
  List<_PickResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSearch('');
    _search.addListener(() => _runSearch(_search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<_PickResult> out;
      if (widget.isCustomer) {
        final repo = await ref.read(customerRepositoryProvider.future);
        final list = await repo.search(query: query, limit: 50);
        out = [for (final c in list) _PickResult(c.id!, c.name)];
      } else {
        final repo = await ref.read(supplierRepositoryProvider.future);
        final list = await repo.search(query: query, limit: 50);
        out = [for (final s in list) _PickResult(s.id!, s.name)];
      }
      if (mounted) {
        setState(() {
          _results = out;
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(context, e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.isCustomer
          ? t.reports_selectCustomer
          : t.reports_selectSupplier),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.common_search,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? Center(child: Text(l10n.empty_default))
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final r = _results[i];
                                return ListTile(
                                  title: Text(r.name),
                                  onTap: () => Navigator.of(context).pop(r.id),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}

class _ProductPickerDialog extends ConsumerStatefulWidget {
  const _ProductPickerDialog();

  @override
  ConsumerState<_ProductPickerDialog> createState() =>
      _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<_ProductPickerDialog> {
  final _search = TextEditingController();
  List<_PickResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSearch('');
    _search.addListener(() => _runSearch(_search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(productRepositoryProvider.future);
      final list = await repo.search(query: query, limit: 50);
      if (mounted) {
        setState(() {
          _results = [for (final p in list) _PickResult(p.id!, p.name)];
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(context, e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.reports_selectProduct),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.common_search,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? Center(child: Text(l10n.empty_default))
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final r = _results[i];
                                return ListTile(
                                  title: Text(r.name),
                                  onTap: () => Navigator.of(context).pop(r.id),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
