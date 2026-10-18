import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/balance_banner.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/whatsapp_share.dart';
import 'khata_providers.dart';
import 'party_form_sheet.dart';
import 'party_txn_sheet.dart';
import 'udhaar_sheet.dart';

/// Customer detail (`/customer-detail`, args: customer id) in the v2
/// "soft khata" style: name header, pastel balance banner, Tareekh
/// Rakhein / SMS / WhatsApp actions, a TIME / DIYE / LIYE ledger list,
/// and red "Mainey Diye" / green "Mainey Liye" bottom buttons.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  int _idOf(BuildContext context) =>
      ModalRoute.of(context)!.settings.arguments as int;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _idOf(context);
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(customerDetailProvider(id));

    return Scaffold(
      body: SafeArea(
        child: dataAsync.when(
          data: (data) => _buildBody(context, data),
          loading: () => const LoadingState(),
          error: (e, _) => e is AppException
              ? ErrorState(
                  message: errorText(context, e),
                  onRetry: () => ref.invalidate(customerDetailProvider(id)),
                )
              : ErrorState(
                  message: l10n.error_generic,
                  onRetry: () => ref.invalidate(customerDetailProvider(id)),
                ),
        ),
      ),
      bottomNavigationBar: dataAsync.maybeWhen(
        data: (data) => _buildBottomButtons(context, data.customer.id!),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomerDetailData data) {
    final id = data.customer.id!;
    final statementAsync =
        ref.watch(customerLedgerProvider(LedgerQuery(partyId: id)));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerDetailProvider(id));
        ref.invalidate(customerLedgerProvider(LedgerQuery(partyId: id)));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, data)),
          SliverToBoxAdapter(child: _buildBanner(context, data)),
          SliverToBoxAdapter(child: _buildActions(context, data)),
          SliverToBoxAdapter(child: _buildSearch(context, data)),
          SliverToBoxAdapter(child: _buildColumnHeader(context)),
          statementAsync.when(
            data: (statement) => _buildTxnSliver(context, statement),
            loading: () => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(32), child: LoadingState()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(
                message: e is AppException
                    ? errorText(context, e)
                    : AppLocalizations.of(context).error_generic,
                onRetry: () => setState(() {}),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CustomerDetailData data) {
    final t = FragmentStrings.of(context);
    final c = data.customer;
    final since = c.createdAt == null
        ? ''
        : t.khata_customerSince(
            date: DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                .format(c.createdAt!));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (since.isNotEmpty)
                  Text(
                    since,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => _onMenu(context, data, v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'statement',
                child: Text(t.customers_statement),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(AppLocalizations.of(context).common_edit),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(c.isArchived
                    ? t.customers_unarchive
                    : t.customers_archive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, CustomerDetailData data) {
    final t = FragmentStrings.of(context);
    final balance = data.balancePaisa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: balance == 0
          ? BalanceBanner(
              amountText: formatPkr(0),
              caption: t.khata_hisaabClear,
              isReceivable: true,
              neutral: true,
            )
          : BalanceBanner(
              amountText: formatPkr(balance.abs()),
              caption: balance > 0
                  ? t.khata_maineLeneHain
                  : t.customers_filterAdvance,
              isReceivable: balance > 0,
            ),
    );
  }

  Widget _buildActions(BuildContext context, CustomerDetailData data) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.calendar_month_outlined,
            label: t.khata_tareekhRakhein,
            onTap: () => _showReminder(context, data),
          ),
          _ActionButton(
            icon: Icons.sms_outlined,
            label: t.khata_sms,
            iconColor: AppColors.pastelBlueText,
            onTap: () => _shareSms(context, data),
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: t.khata_whatsapp,
            iconColor: const Color(0xFF25D366),
            onTap: () => _shareWhatsApp(context, data),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, CustomerDetailData data) {
    final t = FragmentStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: AppSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              hint: t.customers_searchLedgerHint,
            ),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: Icons.picture_as_pdf_outlined,
            tooltip: t.customers_statement,
            onTap: () => Navigator.pushNamed(
              context,
              Routes.reportDetail,
              arguments: {
                'report': 'customerStatement',
                'partyId': data.customer.id,
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(BuildContext context) {
    final t = FragmentStrings.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(t.khata_time, style: style)),
          Expanded(
            flex: 2,
            child: Text(t.khata_diye, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text(t.khata_liye, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnSliver(BuildContext context, LedgerStatement statement) {
    final t = FragmentStrings.of(context);
    var lines = statement.lines;
    if (_search.isNotEmpty) {
      lines = lines
          .where((l) =>
              (l.entry.description ?? '').toLowerCase().contains(_search))
          .toList();
    }
    if (lines.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: t.customers_noEntries,
          ),
        ),
      );
    }
    // Newest first, like the reference ledger.
    final ordered = lines.reversed.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final line = ordered[index];
          return _TxnRow(
            entry: line.entry,
            runningBalancePaisa: line.runningBalancePaisa,
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, int id) {
    final t = FragmentStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () async {
                    final posted =
                        await showUdhaarSheet(context, ref, customerId: id);
                    if (posted) {
                      ref.invalidate(customerDetailProvider(id));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE85D5D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_upward, size: 20),
                      const SizedBox(width: 6),
                      Text(t.khata_maineyDiye),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () async {
                    final posted = await showPartyTxnSheet(
                      context,
                      ref,
                      isCustomer: true,
                      partyId: id,
                      kind: PartyTxnKind.receive,
                    );
                    if (posted) {
                      ref.invalidate(customerDetailProvider(id));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward, size: 20),
                      const SizedBox(width: 6),
                      Text(t.khata_maineyLiye),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(
      BuildContext context, CustomerDetailData data, String value) async {
    final id = data.customer.id!;
    switch (value) {
      case 'statement':
        Navigator.pushNamed(
          context,
          Routes.reportDetail,
          arguments: {'report': 'customerStatement', 'partyId': id},
        );
      case 'edit':
        final saved = await showPartyFormSheet(
          context,
          ref,
          kind: PartyKind.customer,
          customer: data.customer,
        );
        if (saved) ref.invalidate(customerDetailProvider(id));
      case 'archive':
        _toggleArchive(context, data);
    }
  }

  Future<void> _toggleArchive(
      BuildContext context, CustomerDetailData data) async {
    final t = FragmentStrings.of(context);
    final id = data.customer.id!;
    if (!data.customer.isArchived) {
      final confirmed = await showConfirmDialog(
        context,
        title: t.customers_archiveTitle(name: data.customer.name),
        message: t.customers_archiveMessage,
        confirmLabel: t.customers_archive,
      );
      if (!confirmed) return;
    }
    try {
      final repo = await ref.read(customerRepositoryProvider.future);
      await repo.setArchived(id, !data.customer.isArchived);
      ref.invalidate(customerListProvider);
      ref.invalidate(khataSummaryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data.customer.isArchived
              ? t.customers_customerRestored
              : t.customers_customerArchived),
        ),
      );
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText(context, e))),
      );
    }
  }

  Future<void> _showReminder(
      BuildContext context, CustomerDetailData data) async {
    final t = FragmentStrings.of(context);
    final en = buildReminderEn(
        partyName: data.customer.name, balancePaisa: data.balancePaisa);
    final ur = buildReminderUr(
        partyName: data.customer.name, balancePaisa: data.balancePaisa);
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.customers_reminderTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.customers_englishVersion,
                  style: Theme.of(dialogContext).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(en),
              const SizedBox(height: 12),
              Text(t.customers_urduVersion,
                  style: Theme.of(dialogContext).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(ur, textDirection: TextDirection.rtl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '$en\n\n$ur'));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(t.customers_copied)),
              );
            },
            child: Text(t.customers_copyText),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(dialogContext).common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSms(BuildContext context, CustomerDetailData data) async {
    final en = buildReminderEn(
        partyName: data.customer.name, balancePaisa: data.balancePaisa);
    await SharePlus.instance.share(ShareParams(text: en));
  }

  Future<void> _shareWhatsApp(
      BuildContext context, CustomerDetailData data) async {
    final t = FragmentStrings.of(context);
    final phone = data.customer.phone;
    if (phone == null || phone.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.khata_noPhone)),
      );
      return;
    }
    final en = buildReminderEn(
        partyName: data.customer.name, balancePaisa: data.balancePaisa);
    final ur = buildReminderUr(
        partyName: data.customer.name, balancePaisa: data.balancePaisa);
    // Team 3 upgrades this to open the customer's WhatsApp chat directly;
    // today it shares through the system sheet.
    await WhatsAppShare.shareText('$en\n\n$ur');
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 30, color: iconColor ?? Colors.black87),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  final LedgerEntry entry;
  final int runningBalancePaisa;

  const _TxnRow({
    required this.entry,
    required this.runningBalancePaisa,
  });

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final d = entry.date;
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final dateLabel = isToday
        ? 'Today ${DateFormat.jm(localeTag).format(d)}'
        : DateFormat.yMMMd(localeTag).format(d);

    // For customers: debit = udhaar given (DIYE, red), credit = received (LIYE, green).
    final isDiye = entry.debitPaisa > 0;
    final paisa = isDiye ? entry.debitPaisa : entry.creditPaisa;
    final desc = entry.description?.trim();
    final title = (desc != null && desc.isNotEmpty)
        ? desc
        : (entry.referenceType?.isNotEmpty == true
            ? entry.referenceType!
            : entry.entryNo);

    final amountStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDiye ? AppColors.pastelPinkText : AppColors.pastelGreenText,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDiye
                    ? AppColors.pastelPink
                    : AppColors.pastelGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDiye ? Icons.arrow_upward : Icons.arrow_downward,
                color: isDiye
                    ? AppColors.pastelPinkText
                    : AppColors.pastelGreenText,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black87),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPink.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.khata_balAfter(amount: formatPkr(runningBalancePaisa)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                isDiye ? formatPkr(paisa) : '',
                style: amountStyle,
                textAlign: TextAlign.end,
                textDirection: TextDirection.ltr,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                isDiye ? '' : formatPkr(paisa),
                style: amountStyle,
                textAlign: TextAlign.end,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50, top: 4),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
