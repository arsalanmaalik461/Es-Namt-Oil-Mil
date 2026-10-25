import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/inventory_movement.dart'
    show ReferenceTypes;
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/screens/transactions/journal.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/date_filter_chips.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/txn_row.dart';

/// Unified journal view: every posted business transaction grouped from the
/// ledger (read-only). Owned by Agent D (Module D).
class TransactionCenterScreen extends ConsumerStatefulWidget {
  const TransactionCenterScreen({super.key});

  @override
  ConsumerState<TransactionCenterScreen> createState() =>
      _TransactionCenterScreenState();
}

class _TransactionCenterScreenState
    extends ConsumerState<TransactionCenterScreen> {
  final _searchController = TextEditingController();

  JournalFilter _category = JournalFilter.all;
  DateFilter _dateFilter = DateFilter.month;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _newestFirst = true;
  String _query = '';

  Future<List<JournalGroup>>? _future;

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
    if (_customFrom != null) {
      final to = _customTo == null
          ? null
          : DateTime(_customTo!.year, _customTo!.month, _customTo!.day + 1);
      return (from: _customFrom, to: to);
    }
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
      _future =
          ref.read(databaseProvider.future).then((db) => fetchJournalGroups(
                db,
                from: range.from,
                to: range.to,
              ));
    });
  }

  List<JournalGroup> _applyFilters(List<JournalGroup> groups) {
    final q = _query.trim().toLowerCase();
    var out = groups.where((g) => _category.matches(g));
    if (q.isNotEmpty) {
      out = out.where((g) {
        final haystack = [
          g.description,
          g.entryNo,
          g.journalKey,
          g.referenceLabel,
          g.partyName,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(q);
      });
    }
    final sorted = out.toList()..sort((a, b) => a.date.compareTo(b.date));
    return _newestFirst ? sorted.reversed.toList() : sorted;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDateRange: _customFrom == null
          ? null
          : DateTimeRange(
              start: _customFrom!,
              end: _customTo ?? _customFrom!,
            ),
    );
    if (picked == null) return;
    setState(() {
      _customFrom =
          DateTime(picked.start.year, picked.start.month, picked.start.day);
      _customTo = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
    _reload();
  }

  void _clearCustomRange() {
    setState(() {
      _customFrom = null;
      _customTo = null;
    });
    _reload();
  }

  String _categoryLabel(AppLocalizations l10n, JournalGroup g) {
    final refType = g.referenceType;
    if (refType == ReferenceTypes.payment) {
      return g.moneyIn == false
          ? l10n.transactions_filterPaymentPaid
          : l10n.transactions_filterPaymentReceived;
    }
    return switch (refType) {
      ReferenceTypes.sale => l10n.transactions_sale,
      ReferenceTypes.purchase => l10n.transactions_purchase,
      ReferenceTypes.expense => l10n.transactions_expense,
      ReferenceTypes.income => l10n.transactions_income,
      ReferenceTypes.transfer => l10n.transactions_transfer,
      ReferenceTypes.adjustment => l10n.transactions_adjustment,
      ReferenceTypes.production => l10n.transactions_production,
      ReferenceTypes.salesReturn ||
      ReferenceTypes.purchaseReturn =>
        l10n.transactions_return,
      _ => refType,
    };
  }

  IconData _categoryIcon(JournalGroup g) {
    if (g.referenceType == ReferenceTypes.payment) {
      return g.moneyIn == false ? Icons.arrow_upward : Icons.arrow_downward;
    }
    return switch (g.referenceType) {
      ReferenceTypes.sale => Icons.point_of_sale_outlined,
      ReferenceTypes.purchase => Icons.shopping_bag_outlined,
      ReferenceTypes.expense => Icons.money_off_outlined,
      ReferenceTypes.income => Icons.attach_money_outlined,
      ReferenceTypes.transfer => Icons.swap_horiz_outlined,
      ReferenceTypes.adjustment => Icons.tune_outlined,
      ReferenceTypes.production => Icons.factory_outlined,
      ReferenceTypes.salesReturn ||
      ReferenceTypes.purchaseReturn =>
        Icons.keyboard_return_outlined,
      _ => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactions_title),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort_outlined),
            onSelected: (v) => setState(() => _newestFirst = v),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Text(l10n.transactions_sortNewest),
              ),
              PopupMenuItem(
                value: false,
                child: Text(l10n.transactions_sortOldest),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchBar(
              controller: _searchController,
              hint: l10n.transactions_searchHint,
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          DateFilterChips(
            selected: _dateFilter,
            onSelected: (f) {
              setState(() {
                _dateFilter = f;
                _customFrom = null;
                _customTo = null;
              });
              _reload();
            },
          ),
          _CategoryChips(
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          if (_customFrom != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactions_customRangeHint(
                        formatDate(context, _customFrom!),
                        _customTo == null
                            ? ''
                            : formatDate(context, _customTo!),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearCustomRange,
                    child: Text(l10n.common_cancel),
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(l10n.transactions_customRange),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<JournalGroup>>(
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
                final groups = _applyFilters(snapshot.data ?? const []);
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.swap_horiz_outlined,
                    title: l10n.transactions_emptyTitle,
                    message: l10n.empty_default,
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.transactions_entriesCount(groups.length),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, i) {
                          final g = groups[i];
                          final desc = g.description.isEmpty
                              ? l10n.transactions_noDescription
                              : g.description;
                          final subtitle =
                              '${g.entryNo} · ${formatDate(context, g.date)}'
                              '${g.partyName == null ? '' : ' · ${g.partyName}'}'
                              '${g.isReversed ? ' · ${l10n.transactions_reversed}' : ''}';
                          return TxnRow(
                            icon: _categoryIcon(g),
                            title: '$desc · ${_categoryLabel(l10n, g)}',
                            subtitle: subtitle,
                            paisa: g.totalPaisa,
                            positive: g.moneyIn,
                            onTap: () => _showDetail(g),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(JournalGroup g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JournalDetailSheet(group: g),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final JournalFilter selected;
  final ValueChanged<JournalFilter> onSelected;

  const _CategoryChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <JournalFilter, String>{
      JournalFilter.all: l10n.transactions_filterAll,
      JournalFilter.sale: l10n.transactions_sale,
      JournalFilter.purchase: l10n.transactions_purchase,
      JournalFilter.paymentReceived: l10n.transactions_filterPaymentReceived,
      JournalFilter.paymentPaid: l10n.transactions_filterPaymentPaid,
      JournalFilter.expense: l10n.transactions_expense,
      JournalFilter.income: l10n.transactions_income,
      JournalFilter.transfer: l10n.transactions_transfer,
      JournalFilter.adjustment: l10n.transactions_adjustment,
      JournalFilter.ret: l10n.transactions_return,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: options.entries.map((entry) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _JournalDetailSheet extends StatelessWidget {
  final JournalGroup group;

  const _JournalDetailSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = group;
    // Bill photo attached to this transaction: the posting flows stamp
    // `bill_image_path` on the journal's ledger legs, so the first
    // non-empty path among the entries is the attachment to show.
    String? billPath;
    for (final e in g.entries) {
      final p = e.billImagePath;
      if (p != null && p.isNotEmpty) {
        billPath = p;
        break;
      }
    }
    final refLabel = g.referenceLabel == null
        ? g.referenceType
        : '${g.referenceType} · ${g.referenceLabel}';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.transactions_detailTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: l10n.transactions_date,
            value: formatDate(context, g.date),
          ),
          _DetailRow(
            label: l10n.transactions_category,
            value: _categoryLabelOf(context, g),
          ),
          _DetailRow(
            label: l10n.transactions_reference,
            value: refLabel,
          ),
          _DetailRow(
            label: l10n.transactions_description,
            value: g.description.isEmpty
                ? l10n.transactions_noDescription
                : g.description,
          ),
          _DetailRow(
            label: l10n.transactions_total,
            value: formatPkr(g.totalPaisa),
            fitValue: true,
          ),
          if (g.isReversal || g.isReversed)
            _DetailRow(
              label: l10n.transactions_reversed,
              value: g.isReversal
                  ? l10n.transactions_reversal
                  : l10n.transactions_reversed,
              highlight: true,
            ),
          if (billPath != null) ...[
            const SizedBox(height: 8),
            Text(
              FragmentStrings.of(context).khata_billAttached,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _BillThumbnail(path: billPath),
          ],
          const Divider(height: 24),
          Text(
            l10n.transactions_entryNo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final e in g.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.entryNo,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (e.reversedById != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.transactions_reversal,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _accountLabel(g, e),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DcCell(
                            label: l10n.transactions_debit,
                            paisa: e.debitPaisa,
                          ),
                        ),
                        Expanded(
                          child: _DcCell(
                            label: l10n.transactions_credit,
                            paisa: e.creditPaisa,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _categoryLabelOf(BuildContext context, JournalGroup g) {
    final l10n = AppLocalizations.of(context);
    final refType = g.referenceType;
    if (refType == ReferenceTypes.payment) {
      return g.moneyIn == false
          ? l10n.transactions_filterPaymentPaid
          : l10n.transactions_filterPaymentReceived;
    }
    return switch (refType) {
      ReferenceTypes.sale => l10n.transactions_sale,
      ReferenceTypes.purchase => l10n.transactions_purchase,
      ReferenceTypes.expense => l10n.transactions_expense,
      ReferenceTypes.income => l10n.transactions_income,
      ReferenceTypes.transfer => l10n.transactions_transfer,
      ReferenceTypes.adjustment => l10n.transactions_adjustment,
      ReferenceTypes.production => l10n.transactions_production,
      ReferenceTypes.salesReturn ||
      ReferenceTypes.purchaseReturn =>
        l10n.transactions_return,
      _ => refType,
    };
  }

  String _accountLabel(JournalGroup g, LedgerEntry e) {
    final name = g.accountNames['${e.accountType.dbValue}:${e.accountId}'];
    final typeLabel = e.accountType.dbValue;
    return name == null ? typeLabel : '$typeLabel · $name';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  /// When true, the value is kept on one line and scaled down to fit
  /// (for money totals, which must never wrap mid-number).
  final bool fitValue;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.fitValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueText = Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.w700 : null,
            color: highlight ? scheme.error : null,
          ),
      maxLines: fitValue ? 1 : null,
      softWrap: !fitValue,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: fitValue
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: valueText,
                  )
                : valueText,
          ),
        ],
      ),
    );
  }
}

class _DcCell extends StatelessWidget {
  final String label;
  final int paisa;

  const _DcCell({required this.label, required this.paisa});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        AmountText(
          paisa: paisa,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

/// Thumbnail of a bill photo attached to a journal; tap opens the
/// full-screen viewer. Renders nothing when the file is gone (e.g. the
/// device storage was cleaned), so stale paths never break the detail.
class _BillThumbnail extends StatelessWidget {
  final String path;

  const _BillThumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    if (!File(path).existsSync()) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showBillImageViewer(context, path),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Full-screen bill photo viewer with pinch zoom.
void _showBillImageViewer(BuildContext context, String path) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
