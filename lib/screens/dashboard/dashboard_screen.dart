import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/supplier.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';
import 'package:namt_oil_mil/widgets/summary_card.dart';
import 'package:namt_oil_mil/widgets/txn_row.dart';
import '../khata/khata_providers.dart';
import '../khata/party_txn_sheet.dart';
import '../khata/udhaar_sheet.dart';

/// Business dashboard: outstanding dues, today's and this month's figures,
/// cash/bank balances, low-stock alerts, recent activity and quick actions.
///
/// Every figure comes from a real DB query via [dashboardDataProvider]
/// (which delegates all balance math to [AccountingService]). Figures
/// drill into the relevant list / report / ledger routes.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboard_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardDataProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
          await ref.read(dashboardDataProvider.future);
        },
        child: dataAsync.when(
          data: (data) => _buildBody(context, ref, data),
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message: l10n.error_generic,
            onRetry: () => ref.invalidate(dashboardDataProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DashboardData data) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _OutstandingSection(data: data),
        _TodaySection(data: data),
        _AccountsSection(data: data),
        _MonthSection(data: data),
        _QuickActionsSection(ref: ref),
        _LowStockSection(data: data),
        _RecentActivitySection(data: data),
      ],
    );
  }
}

/// Outstanding receivable / payable cards.
class _OutstandingSection extends StatelessWidget {
  final DashboardData data;
  const _OutstandingSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.khata_title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                SummaryCard(
                  label: t.dashboard_totalReceivable,
                  paisa: data.totalReceivablePaisa,
                  icon: Icons.arrow_downward,
                  positive: true,
                  onTap: () => Navigator.pushNamed(context, Routes.customers),
                ),
                SummaryCard(
                  label: t.dashboard_totalPayable,
                  paisa: data.totalPayablePaisa,
                  icon: Icons.arrow_upward,
                  positive: false,
                  onTap: () => Navigator.pushNamed(context, Routes.suppliers),
                ),
              ];
              if (constraints.maxWidth > 420) {
                return Row(children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ]);
              }
              return Column(children: [
                cards[0],
                const SizedBox(height: 12),
                cards[1],
              ]);
            },
          ),
        ),
      ],
    );
  }
}

/// Today's sales / purchases / received / paid.
class _TodaySection extends StatelessWidget {
  final DashboardData data;
  const _TodaySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final now = DateTime.now();
    final dayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final cards = [
      _MiniCard(
        label: t.dashboard_todaySales,
        paisa: data.today.salesPaisa,
        icon: Icons.shopping_cart_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.sales),
      ),
      _MiniCard(
        label: t.dashboard_todayPurchases,
        paisa: data.today.purchasesPaisa,
        icon: Icons.inventory_2_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.purchases),
      ),
      _MiniCard(
        label: t.dashboard_receivedToday,
        paisa: data.today.receivedPaisa,
        icon: Icons.arrow_downward,
        onTap: () => Navigator.pushNamed(
          context,
          Routes.reportDetail,
          arguments: {
            'report': 'paymentsReceived',
            'date': dayStart,
          },
        ),
      ),
      _MiniCard(
        label: t.dashboard_paidToday,
        paisa: data.today.paidPaisa,
        icon: Icons.arrow_upward,
        onTap: () => Navigator.pushNamed(
          context,
          Routes.reportDetail,
          arguments: {
            'report': 'paymentsMade',
            'date': dayStart,
          },
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.dashboard_today),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: cards,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final int paisa;
  final IconData icon;
  final VoidCallback? onTap;
  const _MiniCard({
    required this.label,
    required this.paisa,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: 6),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              AmountText(paisa: paisa),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cash + bank accounts with live ledger balances.
class _AccountsSection extends StatelessWidget {
  final DashboardData data;
  const _AccountsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final total = data.accounts.fold(0, (s, a) => s + a.balancePaisa);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: t.dashboard_totalBalance,
          action: TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.cashbook),
            child: Text(t.dashboard_viewAll),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final ab in data.accounts)
                ListTile(
                  leading: Icon(
                    ab.account.type.dbValue == 'bank'
                        ? Icons.account_balance_outlined
                        : Icons.money_outlined,
                  ),
                  title: Text(ab.account.name),
                  trailing: AmountText(paisa: ab.balancePaisa),
                  onTap: () => Navigator.pushNamed(context, Routes.cashbook),
                ),
              const Divider(height: 1),
              ListTile(
                title: Text(t.dashboard_totalBalance,
                    style: Theme.of(context).textTheme.titleSmall),
                trailing: AmountText(
                  paisa: total,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// This month's income vs expenses.
class _MonthSection extends StatelessWidget {
  final DashboardData data;
  const _MonthSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.dashboard_thisMonth),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                SummaryCard(
                  label: t.dashboard_monthIncome,
                  paisa: data.month.incomePaisa,
                  icon: Icons.trending_up,
                  positive: true,
                  onTap: () => Navigator.pushNamed(context, Routes.reports),
                ),
                SummaryCard(
                  label: t.dashboard_monthExpense,
                  paisa: data.month.expensesPaisa,
                  icon: Icons.trending_down,
                  positive: false,
                  onTap: () => Navigator.pushNamed(context, Routes.reports),
                ),
              ];
              if (constraints.maxWidth > 420) {
                return Row(children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ]);
              }
              return Column(children: [
                cards[0],
                const SizedBox(height: 12),
                cards[1],
              ]);
            },
          ),
        ),
      ],
    );
  }
}

/// 10 quick actions.
class _QuickActionsSection extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActionsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);

    final actions = <_QuickAction>[
      _QuickAction(
        label: t.dashboard_qaAddCustomer,
        icon: Icons.person_add_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.customers,
            arguments: {'new': true}),
      ),
      _QuickAction(
        label: t.dashboard_qaAddSupplier,
        icon: Icons.local_shipping_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.suppliers,
            arguments: {'new': true}),
      ),
      _QuickAction(
        label: t.dashboard_qaGiveUdhaar,
        icon: Icons.arrow_upward,
        onTap: () => _giveUdhaar(context),
      ),
      _QuickAction(
        label: t.dashboard_qaReceivePayment,
        icon: Icons.arrow_downward,
        onTap: () => _receivePayment(context),
      ),
      _QuickAction(
        label: t.dashboard_qaMakePayment,
        icon: Icons.payments_outlined,
        onTap: () => _makePayment(context),
      ),
      _QuickAction(
        label: t.dashboard_qaAddSale,
        icon: Icons.shopping_cart_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.sales),
      ),
      _QuickAction(
        label: t.dashboard_qaAddPurchase,
        icon: Icons.inventory_2_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.purchases),
      ),
      _QuickAction(
        label: t.dashboard_qaAddExpense,
        icon: Icons.money_off_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.expenses),
      ),
      _QuickAction(
        label: t.dashboard_qaRecordProduction,
        icon: Icons.factory_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.production),
      ),
      _QuickAction(
        label: t.dashboard_qaViewReports,
        icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.reports),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.dashboard_quickActions),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: [for (final a in actions) _QuickActionTile(action: a)],
          ),
        ),
      ],
    );
  }

  Future<void> _giveUdhaar(BuildContext context) async {
    // Cash udhaar (Dr Customer / Cr Cash|Bank) — not a goods sale.
    final picked = await Navigator.pushNamed(
      context,
      Routes.customers,
      arguments: {'pick': true},
    );
    if (picked is Customer && context.mounted) {
      await showUdhaarSheet(context, ref, customerId: picked.id!);
    }
  }

  Future<void> _receivePayment(BuildContext context) async {
    final picked = await Navigator.pushNamed(
      context,
      Routes.customers,
      arguments: {'pick': true},
    );
    if (picked is Customer && context.mounted) {
      await showPartyTxnSheet(
        context,
        ref,
        isCustomer: true,
        partyId: picked.id!,
        kind: PartyTxnKind.receive,
      );
    }
  }

  Future<void> _makePayment(BuildContext context) async {
    final picked = await Navigator.pushNamed(
      context,
      Routes.suppliers,
      arguments: {'pick': true},
    );
    if (picked is Supplier && context.mounted) {
      await showPartyTxnSheet(
        context,
        ref,
        isCustomer: false,
        partyId: picked.id!,
        kind: PartyTxnKind.pay,
      );
    }
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.label, required this.icon, required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Icon(action.icon, color: scheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Low-stock alerts from the inventory.
class _LowStockSection extends StatelessWidget {
  final DashboardData data;
  const _LowStockSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: t.dashboard_lowStock,
          action: TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.inventory),
            child: Text(t.dashboard_viewAll),
          ),
        ),
        if (data.lowStock.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading:
                    Icon(Icons.check_circle_outline, color: scheme.primary),
                title: Text(t.dashboard_lowStockOk),
              ),
            ),
          )
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final p in data.lowStock)
                  ListTile(
                    leading:
                        Icon(Icons.warning_amber_outlined, color: scheme.error),
                    title: Text(p.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      t.dashboard_stockLeft(
                        qty: _fmtQty(p.stockQty),
                        unit: data.unitSymbols[p.baseUnitId] ?? '',
                      ),
                    ),
                    onTap: () => Navigator.pushNamed(context, Routes.inventory),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmtQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }
}

/// Recent sales / purchases / payments / expenses / income.
class _RecentActivitySection extends StatelessWidget {
  final DashboardData data;
  const _RecentActivitySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.dashboard_recentActivity),
        if (data.recent.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: t.dashboard_noActivity,
            message: t.dashboard_noActivityHint,
          )
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final item in data.recent)
                  TxnRow(
                    icon: _iconFor(item.kind),
                    title: _titleFor(t, item),
                    subtitle: _subtitleFor(context, item),
                    paisa: item.paisa,
                    positive: item.positive,
                    onTap: _tapFor(context, item),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(ActivityKind kind) => switch (kind) {
        ActivityKind.sale => Icons.shopping_cart_outlined,
        ActivityKind.purchase => Icons.inventory_2_outlined,
        ActivityKind.paymentIn => Icons.arrow_downward,
        ActivityKind.paymentOut => Icons.arrow_upward,
        ActivityKind.expense => Icons.money_off_outlined,
        ActivityKind.income => Icons.attach_money_outlined,
      };

  String _titleFor(FragmentStrings t, ActivityItem item) => switch (item.kind) {
        ActivityKind.sale => t.dashboard_activitySale(no: item.reference),
        ActivityKind.purchase =>
          t.dashboard_activityPurchase(no: item.reference),
        ActivityKind.paymentIn => t.dashboard_activityPaymentIn,
        ActivityKind.paymentOut => t.dashboard_activityPaymentOut,
        ActivityKind.expense => t.dashboard_activityExpense,
        ActivityKind.income => t.dashboard_activityIncome,
      };

  String? _subtitleFor(BuildContext context, ActivityItem item) {
    final dateLabel =
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(item.date);
    if (item.subtitle != null && item.subtitle!.isNotEmpty) {
      return '${item.subtitle} • $dateLabel';
    }
    return dateLabel;
  }

  VoidCallback? _tapFor(BuildContext context, ActivityItem item) {
    switch (item.kind) {
      case ActivityKind.sale:
        if (item.refId == null) return null;
        return () => Navigator.pushNamed(context, Routes.saleDetail,
            arguments: item.refId);
      case ActivityKind.purchase:
        if (item.refId == null) return null;
        return () => Navigator.pushNamed(context, Routes.purchaseDetail,
            arguments: item.refId);
      default:
        return null;
    }
  }
}
