import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/bottom_cta_button.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/entrance_animation.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'khata_providers.dart';
import 'party_form_sheet.dart';

/// Khata home in the v2 "soft khata" style.
///
/// Business header, TOTAL BALANCE with pastel lene/dene cards, a reminders
/// row, party search, a Customers/Suppliers toggle with the party list,
/// and a black "Add customer / Add supplier" CTA — the same workflow as
/// the reference screens, with original Namt Oil Mil branding.
class KhataHubScreen extends ConsumerStatefulWidget {
  const KhataHubScreen({super.key});

  @override
  ConsumerState<KhataHubScreen> createState() => _KhataHubScreenState();
}

class _KhataHubScreenState extends ConsumerState<KhataHubScreen> {
  bool _showSuppliers = false;
  final _searchController = TextEditingController();
  String _search = '';

  /// Whether this tab was visible at the last dependency change. The hub
  /// lives in the shell's IndexedStack, which keeps it mounted while other
  /// tabs are shown and wraps hidden tabs in TickerMode(enabled: false) —
  /// so a false -> true flip is the "user came back to this tab" signal.
  bool _wasVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Posting flows on OTHER tabs (sales, purchases, payments) do not
    // invalidate khataSummaryProvider, and this screen is never rebuilt on
    // a tab switch — without this, the TOTAL BALANCE cards could keep
    // showing stale figures until a manual pull-to-refresh.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_wasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(khataSummaryProvider);
      });
    }
    _wasVisible = visible;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(khataSummaryProvider);
    final query = PartyListQuery(search: _search);
    final listAsync = _showSuppliers
        ? ref.watch(supplierListProvider(query))
        : ref.watch(customerListProvider(query));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(khataSummaryProvider);
            setState(() {});
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: summaryAsync.when(
                  data: (s) => _buildBalance(context, s),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: summaryAsync.when(
                  data: (s) => _buildRemindersRow(context, s),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(child: _buildSearch(context)),
              SliverToBoxAdapter(child: _buildToggle(context)),
              listAsync.when(
                data: (parties) => _buildPartySliver(context, parties),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: LoadingState(),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(
                    message: l10n.error_generic,
                    onRetry: () => setState(() {}),
                  ),
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
          label:
              _showSuppliers ? t.khata_addSupplierBtn : t.khata_addCustomerBtn,
          onPressed: () async {
            final saved = await showPartyFormSheet(
              context,
              ref,
              kind: _showSuppliers ? PartyKind.supplier : PartyKind.customer,
            );
            if (saved && mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.khata_businessName.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance(BuildContext context, KhataSummary s) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.khata_totalBalance,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.remove_red_eye_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniBalanceCard(
                  amount: formatPkr(s.receivablePaisa),
                  caption: t.khata_maineLeneHain,
                  background: AppColors.pastelPink,
                  foreground: AppColors.pastelPinkText,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniBalanceCard(
                  amount: formatPkr(s.payablePaisa),
                  caption: t.khata_maineDeneHain,
                  background: AppColors.pastelGreen,
                  foreground: AppColors.pastelGreenText,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersRow(BuildContext context, KhataSummary s) {
    final t = FragmentStrings.of(context);
    final overdue = s.receivableCount + s.payableCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showRemindersDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_outlined, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.khata_remindersCount(count: '$overdue'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
      child: AppSearchBar(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v.trim()),
        hint: _showSuppliers ? t.khata_searchSupplier : t.khata_searchCustomer,
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      // Label stacked ABOVE the segmented control: side-by-side, the label
      // was squeezed into "CUSTOM..." next to the control on 360px phones.
      // Full-width rows keep both always fully readable.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (_showSuppliers ? t.khata_suppliers : t.khata_customers)
                .toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              ButtonSegment(
                value: false,
                label: Text(t.khata_customers),
                icon: const Icon(Icons.people_outline, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text(t.khata_suppliers),
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
              ),
            ],
            selected: {_showSuppliers},
            onSelectionChanged: (sel) =>
                setState(() => _showSuppliers = sel.first),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySliver(BuildContext context, List<dynamic> parties) {
    final t = FragmentStrings.of(context);
    if (parties.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.people_outline,
            title: _showSuppliers
                ? t.customers_noSuppliers
                : t.customers_noCustomers,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: parties.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = parties[index];
          final name = p.name as String;
          final balance = p.balancePaisa as int;
          final updated = p.updatedAt as DateTime?;
          final dateLabel = updated == null
              ? ''
              : t.khata_lastTransacted(
                  // Compact date ("Oct 25, 26"): the long form pushed the
                  // subtitle into "last transacted on Oct ..." truncation.
                  date: DateFormat('MMM d, yy',
                          Localizations.localeOf(context).toLanguageTag())
                      .format(updated));
          return StaggerEntrance(
            // Staggered entrance per row; capped at 300ms so long lists
            // stay snappy. Runs on first load only.
            delay: Duration(milliseconds: (index * 40).clamp(0, 300).toInt()),
            child: _PartyRow(
              name: name,
              subtitle: dateLabel,
              balancePaisa: balance,
              isSupplier: _showSuppliers,
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  _showSuppliers
                      ? Routes.supplierDetail
                      : Routes.customerDetail,
                  arguments: p.id as int,
                );
                // Refresh on return: anything posted inside the detail
                // flow (payments, corrections, buy-from-customer, ...)
                // must be reflected in the totals and list immediately.
                if (!mounted) return;
                ref.invalidate(khataSummaryProvider);
                ref.invalidate(customerListProvider);
                ref.invalidate(supplierListProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRemindersDialog(BuildContext context) async {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final query = const PartyListQuery(filter: PartyBalanceFilter.positive);
    final customers = await ref.read(customerListProvider(query).future);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.khata_remindersCount(count: '${customers.length}')),
        content: SizedBox(
          width: double.maxFinite,
          child: customers.isEmpty
              ? Text(t.khata_hisaabClear)
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    return ListTile(
                      dense: true,
                      title: Text(c.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                formatPkr(c.balancePaisa),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pastelPinkText,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: t.customers_copyText,
                            onPressed: () async {
                              final en = buildReminderEn(
                                  partyName: c.name,
                                  balancePaisa: c.balancePaisa);
                              final ur = buildReminderUr(
                                  partyName: c.name,
                                  balancePaisa: c.balancePaisa);
                              await Clipboard.setData(
                                  ClipboardData(text: '$en\n\n$ur'));
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(t.customers_copied)),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        Navigator.of(dialogContext).pop();
                        await Navigator.pushNamed(
                          context,
                          Routes.customerDetail,
                          arguments: c.id,
                        );
                        if (!mounted) return;
                        ref.invalidate(khataSummaryProvider);
                        ref.invalidate(customerListProvider);
                        ref.invalidate(supplierListProvider);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

class _MiniBalanceCard extends StatelessWidget {
  final String amount;
  final String caption;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _MiniBalanceCard({
    required this.amount,
    required this.caption,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full amount on one line, scaled to fit — never
                // "Rs 1,100...." truncation.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: foreground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                // Caption also scales to fit instead of "Maine lene h...".
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    caption,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: foreground.withValues(alpha: 0.9)),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final int balancePaisa;
  final bool isSupplier;
  final VoidCallback onTap;

  const _PartyRow({
    required this.name,
    required this.subtitle,
    required this.balancePaisa,
    required this.isSupplier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // For customers: +balance = they owe us (pink). For suppliers the
    // payable side is mirrored so "dene hain" stays pink as well.
    final owesUs = isSupplier ? balancePaisa < 0 : balancePaisa > 0;
    final color = balancePaisa == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (owesUs ? AppColors.pastelPinkText : AppColors.pastelGreenText);
    final prefix = balancePaisa == 0 ? '' : (owesUs ? '- ' : '+ ');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    // Scales down to fit the full line — the "last
                    // transacted on ..." line must never ellipsize.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Balance scales down to fit its share of the row instead of
            // squeezing the name/subtitle or colliding with them.
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '$prefix${formatPkr(balancePaisa.abs())}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
