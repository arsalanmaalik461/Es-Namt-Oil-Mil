import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/sales/sale_form_screen.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/bottom_cta_button.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/entrance_animation.dart';
import 'package:namt_oil_mil/widgets/pastel_stat_card.dart';

/// Sales dashboard (`/sales`) in the v2 "soft khata" style.
///
/// Hafta / Maheena / Apni marzi period tabs, pastel KULL SALES / ORDERS /
/// NAQAD / UDHAAR stat cards, an "Items manage karein" entry card, search,
/// the HAALI SALES list, and a black "Sale darj karein" CTA — the same
/// workflow as the reference screens, with original Namt Oil Mil branding.
class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

enum _Period { hafta, maheena, custom }

class _SalesRow {
  final int id;
  final String invoiceNo;
  final String customerName;
  final DateTime date;
  final int totalPaisa;
  final int paidPaisa;
  const _SalesRow({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.date,
    required this.totalPaisa,
    required this.paidPaisa,
  });
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  _Period _period = _Period.maheena;
  DateTimeRange? _customRange;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime get _from {
    final now = DateTime.now();
    return switch (_period) {
      _Period.hafta => DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6)),
      _Period.maheena => DateTime(now.year, now.month, 1),
      _Period.custom => _customRange == null
          ? DateTime(now.year, now.month, 1)
          : DateTime(_customRange!.start.year, _customRange!.start.month,
              _customRange!.start.day),
    };
  }

  DateTime get _to {
    final now = DateTime.now();
    return switch (_period) {
      _Period.hafta =>
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      _Period.maheena => DateTime(now.year, now.month + 1, 1),
      _Period.custom => _customRange == null
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(_customRange!.end.year, _customRange!.end.month,
                  _customRange!.end.day)
              .add(const Duration(days: 1)),
    };
  }

  String _periodLabel(FragmentStrings t) => switch (_period) {
        _Period.hafta => t.sales_periodHafta,
        _Period.maheena => t.sales_periodMaheena,
        _Period.custom => t.sales_periodCustom,
      };

  Future<List<_SalesRow>> _loadRows() async {
    final db = await ref.read(databaseProvider.future);
    final from = _from.millisecondsSinceEpoch;
    final to = _to.millisecondsSinceEpoch;
    final where = <String>['i.date >= ?', 'i.date < ?'];
    final args = <Object?>[from, to];
    if (_search.isNotEmpty) {
      where.add('(i.invoice_no LIKE ? OR c.name LIKE ?)');
      args.add('%$_search%');
      args.add('%$_search%');
    }
    final rows = await db.rawQuery(
      'SELECT i.id, i.invoice_no, i.date, i.total_paisa, i.paid_paisa, '
      'c.name AS customer_name '
      'FROM sales_invoices i '
      'LEFT JOIN customers c ON c.id = i.customer_id '
      'WHERE ${where.join(' AND ')} '
      "AND i.status != 'cancelled' "
      'ORDER BY i.date DESC, i.id DESC LIMIT 100',
      args,
    );
    return [
      for (final r in rows)
        _SalesRow(
          id: r['id'] as int,
          invoiceNo: (r['invoice_no'] as String?) ?? '',
          customerName: (r['customer_name'] as String?) ?? '—',
          date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
          totalPaisa: (r['total_paisa'] as num).toInt(),
          paidPaisa: (r['paid_paisa'] as num).toInt(),
        ),
    ];
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
      setState(() {
        _customRange = picked;
        _period = _Period.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildPeriodTabs(context)),
              SliverToBoxAdapter(
                child: FutureBuilder<List<_SalesRow>>(
                  future: _loadRows(),
                  builder: (context, snapshot) {
                    final rows = snapshot.data ?? const <_SalesRow>[];
                    return _buildStats(context, rows);
                  },
                ),
              ),
              SliverToBoxAdapter(child: _buildItemsCard(context)),
              SliverToBoxAdapter(child: _buildSearch(context)),
              SliverToBoxAdapter(
                child: FutureBuilder<List<_SalesRow>>(
                  future: _loadRows(),
                  builder: (context, snapshot) {
                    final rows = snapshot.data ?? const <_SalesRow>[];
                    return _buildRecentList(context, rows);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BottomCtaButton(
          icon: Icons.add,
          label: t.sales_saleDarjKarein,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SaleFormScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.sales_title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            t.khata_businessName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<_Period>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(value: _Period.hafta, label: Text(t.sales_hafta)),
                ButtonSegment(
                    value: _Period.maheena, label: Text(t.sales_maheena)),
              ],
              selected: {
                if (_period != _Period.custom) _period else _Period.maheena
              },
              onSelectionChanged: (sel) => setState(() {
                _period = sel.first;
                _customRange = null;
              }),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(t.sales_apniMarzi, maxLines: 1, softWrap: false),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  _period == _Period.custom ? AppColors.pastelBlue : null,
            ),
            onPressed: _pickCustomRange,
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<_SalesRow> rows) {
    final t = FragmentStrings.of(context);
    final periodLabel = _periodLabel(t);
    final totalSales = rows.fold(0, (s, r) => s + r.totalPaisa);
    final totalNaqad = rows.fold(0, (s, r) => s + r.paidPaisa);
    final totalUdhaar = totalSales - totalNaqad;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StaggerEntrance(
                  child: PastelStatCard(
                    label: t.sales_kullSales,
                    value: formatPkr(totalSales),
                    sublabel: periodLabel,
                    background: Theme.of(context).colorScheme.surface,
                    valueColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StaggerEntrance(
                  delay: const Duration(milliseconds: 70),
                  child: PastelStatCard(
                    label: t.sales_kullOrders,
                    value: '${rows.length}',
                    sublabel: periodLabel,
                    background: Theme.of(context).colorScheme.surface,
                    valueColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StaggerEntrance(
                  delay: const Duration(milliseconds: 140),
                  child: PastelStatCard(
                    label: t.sales_kullNaqad,
                    value: formatPkr(totalNaqad),
                    sublabel: periodLabel,
                    background: AppColors.pastelGreen,
                    valueColor: AppColors.pastelGreenText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StaggerEntrance(
                  delay: const Duration(milliseconds: 210),
                  child: PastelStatCard(
                    label: t.sales_kullUdhaar,
                    value: formatPkr(totalUdhaar),
                    sublabel: periodLabel,
                    background: AppColors.pastelPink,
                    valueColor: AppColors.pastelPinkText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, Routes.inventory),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pastelBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: AppColors.pastelBlueText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.sales_itemsManage,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      t.sales_itemsManageHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: AppSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.trim()),
              hint: t.sales_searchSales,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Icon(Icons.filter_list,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(BuildContext context, List<_SalesRow> rows) {
    final t = FragmentStrings.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  t.sales_haaliSales,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                t.sales_nataij(count: '${rows.length}'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: t.sales_noSalesPeriod,
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = rows[index];
                  final due = r.totalPaisa - r.paidPaisa;
                  return StaggerEntrance(
                    // Staggered entrance per row; capped at 300ms.
                    delay: Duration(milliseconds: (index * 35).clamp(0, 300)),
                    child: ListTile(
                      title: Text(
                        r.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${r.invoiceNo} • ${DateFormat.yMMMd(localeTag).format(r.date)}',
                        textDirection: TextDirection.ltr,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatPkr(r.totalPaisa),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              textDirection: TextDirection.ltr,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          if (due > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                formatPkr(due),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.pastelPinkText,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        Routes.saleDetail,
                        arguments: r.id,
                      ),
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
