import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart' show InvoiceStatus;
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/date_filter_chips.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/txn_row.dart';

// ===========================================================================
// Generic invoice list (sales / purchases). The concrete module (labels +
// queries + navigation) is supplied by the wrapper screens in
// lib/screens/sales/ and lib/screens/purchases/.
// ===========================================================================

abstract class InvoiceListModule {
  String title(AppLocalizations l10n);
  String searchHint(AppLocalizations l10n);
  String emptyTitle(AppLocalizations l10n);
  String newLabel(AppLocalizations l10n);
  String statusLabel(AppLocalizations l10n, InvoiceStatus status);

  Future<List<InvoiceRowData>> load({
    String? query,
    DateTime? from,
    DateTime? to,
    InvoiceStatus? status,
  });

  void openNew(BuildContext context);
  void openDetail(BuildContext context, int id);
}

class InvoiceListScreen extends ConsumerStatefulWidget {
  final InvoiceListModule module;

  const InvoiceListScreen({super.key, required this.module});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _searchController = TextEditingController();
  DateFilter _dateFilter = DateFilter.month;
  InvoiceStatus? _status;
  String _query = '';
  Future<List<InvoiceRowData>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ({DateTime? from, DateTime? to}) get _range {
    final now = DateTime.now();
    switch (_dateFilter) {
      case DateFilter.today:
        return (
          from: DateTime(now.year, now.month, now.day),
          to: DateTime(now.year, now.month, now.day + 1),
        );
      case DateFilter.week:
        return (from: now.subtract(const Duration(days: 7)), to: null);
      case DateFilter.month:
        return (from: now.subtract(const Duration(days: 30)), to: null);
      case DateFilter.all:
        return (from: null, to: null);
    }
  }

  void _reload() {
    final range = _range;
    setState(() {
      _future = widget.module.load(
        query: _query.trim().isEmpty ? null : _query.trim(),
        from: range.from,
        to: range.to,
        status: _status,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final module = widget.module;
    return Scaffold(
      appBar: AppBar(title: Text(module.title(l10n))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          module.openNew(context);
          // Refresh when returning from the form.
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (mounted) _reload();
        },
        icon: const Icon(Icons.add),
        label: Text(module.newLabel(l10n)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchBar(
              controller: _searchController,
              hint: module.searchHint(l10n),
              onChanged: (q) {
                _query = q;
                _reload();
              },
            ),
          ),
          DateFilterChips(
            selected: _dateFilter,
            onSelected: (f) {
              setState(() => _dateFilter = f);
              _reload();
            },
          ),
          _StatusChips(
            selected: _status,
            labelOf: (s) => module.statusLabel(l10n, s),
            onSelected: (s) {
              setState(() => _status = s);
              _reload();
            },
          ),
          Expanded(
            child: FutureBuilder<List<InvoiceRowData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  final e = snapshot.error;
                  return ErrorState(
                    message: e is AppException
                        ? errorText(context, e)
                        : l10n.error_generic,
                    onRetry: _reload,
                  );
                }
                final rows = snapshot.data ?? const <InvoiceRowData>[];
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: module.emptyTitle(l10n),
                    message: l10n.empty_default,
                    actionLabel: module.newLabel(l10n),
                    onAction: () => module.openNew(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return TxnRow(
                        icon: Icons.receipt_outlined,
                        title: r.invoiceNo,
                        subtitle:
                            '${r.partyName} · ${formatDate(context, r.date)}',
                        paisa: r.totalPaisa,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            InvoiceStatusChip(
                              status: r.status,
                              label: module.statusLabel(l10n, r.status),
                            ),
                          ],
                        ),
                        onTap: () => module.openDetail(context, r.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final InvoiceStatus? selected;
  final String Function(InvoiceStatus) labelOf;
  final ValueChanged<InvoiceStatus?> onSelected;

  const _StatusChips({
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <InvoiceStatus?>[
      null,
      ...InvoiceStatus.values,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: options.map((s) {
          final label = s == null ? l10n.transactions_filterAll : labelOf(s);
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected == s,
              onSelected: (_) => onSelected(s),
            ),
          );
        }).toList(),
      ),
    );
  }
}
