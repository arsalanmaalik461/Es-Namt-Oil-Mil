import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/date_filter_chips.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/ledger_row.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'khata_providers.dart';

/// Shared full-ledger UI for a customer or supplier.
///
/// Reads via [AccountingService.ledgerWithRunningBalance] (the only legal
/// balance source), with a date-range filter (preset chips + custom range)
/// and description search. The running balance comes straight from the
/// statement — never computed in the UI.
class PartyLedgerView extends ConsumerStatefulWidget {
  final int partyId;
  final bool isCustomer;

  const PartyLedgerView({
    super.key,
    required this.partyId,
    required this.isCustomer,
  });

  @override
  ConsumerState<PartyLedgerView> createState() => _PartyLedgerViewState();
}

class _PartyLedgerViewState extends ConsumerState<PartyLedgerView> {
  DateFilter _filter = DateFilter.all;
  DateTimeRange? _customRange;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  LedgerQuery get _query {
    DateTime? from;
    DateTime? to;
    final now = DateTime.now();
    if (_customRange != null) {
      from = DateTime(_customRange!.start.year, _customRange!.start.month,
          _customRange!.start.day);
      final end = _customRange!.end;
      to = DateTime(end.year, end.month, end.day + 1);
    } else {
      switch (_filter) {
        case DateFilter.today:
          from = DateTime(now.year, now.month, now.day);
          to = from.add(const Duration(days: 1));
        case DateFilter.week:
          to = DateTime(now.year, now.month, now.day + 1);
          from = to.subtract(const Duration(days: 7));
        case DateFilter.month:
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 1);
        case DateFilter.all:
          break;
      }
    }
    return LedgerQuery(partyId: widget.partyId, from: from, to: to);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  void _clearCustomRange() => setState(() => _customRange = null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = FragmentStrings.of(context);

    final statementAsync = widget.isCustomer
        ? ref.watch(customerLedgerProvider(_query))
        : ref.watch(supplierLedgerProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(t.customers_ledgerTitle)),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DateFilterChips(
                  selected: _customRange != null ? DateFilter.all : _filter,
                  onSelected: (f) => setState(() {
                    _filter = f;
                    _customRange = null;
                  }),
                ),
              ),
              IconButton(
                tooltip: t.customers_customRange,
                icon: Icon(
                  Icons.date_range_outlined,
                  color: _customRange != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: _pickCustomRange,
              ),
            ],
          ),
          if (_customRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text(
                  '${_fmtDate(context, _customRange!.start)} – ${_fmtDate(context, _customRange!.end)}',
                ),
                onDeleted: _clearCustomRange,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: AppSearchBar(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
              hint: t.customers_searchLedgerHint,
            ),
          ),
          Expanded(
            child: statementAsync.when(
              data: (statement) => _buildList(context, statement),
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: e is AppException
                    ? errorText(context, e)
                    : l10n.error_generic,
                onRetry: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, LedgerStatement statement) {
    final t = FragmentStrings.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    var lines = statement.lines;
    if (_search.isNotEmpty) {
      lines = lines
          .where((l) =>
              (l.entry.description ?? '').toLowerCase().contains(_search))
          .toList();
    }

    if (lines.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: t.customers_noEntries,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        itemCount: lines.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _OpeningRow(
              openingPaisa: statement.openingBalancePaisa,
              isCustomer: widget.isCustomer,
            );
          }
          final line = lines[index - 1];
          final entry = line.entry;
          final isDebit =
              widget.isCustomer ? entry.debitPaisa > 0 : entry.creditPaisa > 0;
          final paisa =
              entry.debitPaisa > 0 ? entry.debitPaisa : entry.creditPaisa;
          final dateLabel = DateFormat.yMMMd(localeTag).format(entry.date);
          return LedgerRow(
            title: _entryTitle(entry),
            dateLabel: dateLabel,
            paisa: paisa,
            isDebit: isDebit,
            runningBalancePaisa: line.runningBalancePaisa,
          );
        },
      ),
    );
  }

  String _entryTitle(LedgerEntry entry) {
    final desc = entry.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final ref = entry.referenceType;
    if (ref != null && ref.isNotEmpty) return ref;
    return entry.entryNo;
  }

  String _fmtDate(BuildContext context, DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(d);
}

class _OpeningRow extends StatelessWidget {
  final int openingPaisa;
  final bool isCustomer;
  const _OpeningRow({required this.openingPaisa, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: ListTile(
        dense: true,
        title: Text(
          t.customers_openingBalanceLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: Text(
          formatPkr(openingPaisa),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}
