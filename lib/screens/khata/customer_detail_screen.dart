import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/screens/purchases/buy_from_customer_sheet.dart';
import 'package:namt_oil_mil/screens/reports/document_data.dart';
import 'package:namt_oil_mil/screens/reports/report_definitions.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/services/pdf/pdf_service.dart';
import 'package:namt_oil_mil/services/reminder_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/services/sms_service.dart';
import 'package:namt_oil_mil/services/whatsapp_service.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/balance_banner.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
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
          SliverToBoxAdapter(
            child: statementAsync.maybeWhen(
              data: (statement) => _buildTotals(context, statement),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(child: _buildActions(context, data)),
          SliverToBoxAdapter(child: _buildSearch(context, data)),
          SliverToBoxAdapter(child: _buildColumnHeader(context)),
          statementAsync.when(
            data: (statement) => _buildTxnSliver(context, statement),
            loading: () => const SliverToBoxAdapter(
              child:
                  Padding(padding: EdgeInsets.all(32), child: LoadingState()),
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
            date: DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag())
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                value: 'buy',
                child: Text(
                    AppLocalizations.of(context).purchases_newPurchase),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(AppLocalizations.of(context).common_edit),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(
                    c.isArchived ? t.customers_unarchive : t.customers_archive),
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

  /// Both gross totals for THIS customer (user-requested 2026-10-25): the
  /// banner above shows only the net balance, so the detail screen also
  /// shows total "Mainey Diye" (Σ ledger debits — udhaar + credit sales)
  /// and total "Mainey Liye" (Σ ledger credits — payments received) side
  /// by side. Summed from the same authoritative statement lines the list
  /// below renders; voided entries never count toward totals.
  Widget _buildTotals(BuildContext context, LedgerStatement statement) {
    final t = FragmentStrings.of(context);
    var diye = 0;
    var liye = 0;
    for (final line in statement.lines) {
      if (line.entry.voided) continue;
      diye += line.entry.debitPaisa;
      liye += line.entry.creditPaisa;
    }
    if (diye == 0 && liye == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _TotalChip(
              label: t.khata_maineyDiye,
              amountText: formatPkr(diye),
              background: AppColors.pastelPink,
              foreground: AppColors.pastelPinkText,
              icon: Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TotalChip(
              label: t.khata_maineyLiye,
              amountText: formatPkr(liye),
              background: AppColors.pastelGreen,
              foreground: AppColors.pastelGreenText,
              icon: Icons.arrow_downward,
            ),
          ),
        ],
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
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
              hint: t.customers_searchLedgerHint,
            ),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: Icons.picture_as_pdf_outlined,
            tooltip: t.customers_statement,
            onTap: () => _openStatement(context, data.customer.id!),
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      Flexible(
                        // Scale the label down to fit instead of
                        // ellipsizing it ("Mainey D...") on small phones
                        // — same treatment as the shared BottomCtaButton.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.khata_maineyDiye,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
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
                      Flexible(
                        // Scale the label down to fit instead of
                        // ellipsizing it ("Mainey L...") on small phones
                        // — same treatment as the shared BottomCtaButton.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.khata_maineyLiye,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
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

  /// Opens the customer statement (PDF preview with Save/Share/Print).
  ///
  /// BUG FIX (2026-10-25): this used to navigate with
  /// `{'report': 'customerStatement', 'partyId': id}`. But
  /// 'customerStatement' is a DOCUMENT key, not an analytical report key:
  /// the report screen's loader has no case for it and always returned an
  /// empty result, so the screen showed date filters over a permanent
  /// "no data" state — picking a date range never showed the ledger.
  /// Statements are documents: pick the period here, then navigate in
  /// document mode with an explicit [from, to) window; the statement
  /// builder renders exactly those entries plus the opening balance.
  Future<void> _openStatement(BuildContext context, int id) async {
    final t = FragmentStrings.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive_outlined),
              title: Text(t.reports_all),
              onTap: () => Navigator.of(sheetContext).pop('all'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(t.dashboard_thisMonth),
              onTap: () => Navigator.of(sheetContext).pop('month'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(t.customers_customRange),
              onTap: () => Navigator.of(sheetContext).pop('custom'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final now = DateTime.now();
    final DateTime from;
    final DateTime to;
    switch (choice) {
      case 'month':
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 1);
      case 'custom':
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 5, 12, 31),
        );
        if (picked == null || !context.mounted) return;
        from = DateTime(
            picked.start.year, picked.start.month, picked.start.day);
        final end = picked.end;
        to = DateTime(end.year, end.month, end.day + 1);
      default: // 'all' — explicit wide window (builder defaults to 90 days)
        from = DateTime(2000, 1, 1);
        to = DateTime(2100, 1, 1);
    }
    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      Routes.reportDetail,
      arguments: {
        'document': 'customerStatement',
        'id': id,
        'from': from,
        'to': to,
      },
    );
  }

  Future<void> _onMenu(
      BuildContext context, CustomerDetailData data, String value) async {
    final id = data.customer.id!;
    switch (value) {
      case 'statement':
        _openStatement(context, id);
      case 'buy':
        // Buy goods FROM this customer: posts the payable onto this
        // customer's own ledger via postPurchaseFromCustomer.
        final posted = await showBuyFromCustomerSheet(
          context,
          ref,
          customer: data.customer,
        );
        if (posted) ref.invalidate(customerDetailProvider(id));
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _shareWhatsApp(context, data);
            },
            child: Text(t.khata_whatsapp),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _shareSms(context, data);
            },
            child: Text(t.khata_sms),
          ),
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

  /// The customer's FULL ledger statement PDF bytes (every entry): the
  /// statement builder defaults to the last 90 days, so an explicit
  /// 2000→2100 window is passed — same as [_openStatement]'s "All".
  Future<Uint8List> _statementPdfBytes(CustomerDetailData data) async {
    final t = FragmentStrings.of(context);
    final business = ref.read(businessProfileProvider);
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    String fmt(DateTime d) => DateFormat.yMMMd(localeCode).format(d);
    final doc = await buildDocumentData(
      ref: ref,
      documentType: DocumentKeys.customerStatement,
      id: data.customer.id!,
      t: t,
      business: business,
      formatDate: fmt,
      from: DateTime(2000, 1, 1),
      to: DateTime(2100, 1, 1),
    );
    return ref.read(pdfServiceProvider).buildPdf(document: doc, l10n: l10n);
  }

  /// After an SMS reminder, offers the customer's FULL statement PDF and
  /// shares it through the system share sheet when accepted.
  Future<void> _offerStatementPdf(
      BuildContext context, CustomerDetailData data,
      {String? text}) async {
    final t = FragmentStrings.of(context);
    final share = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.customers_statement),
        content:
            Text('${data.customer.name} • ${formatPkr(data.balancePaisa)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.reminders_send),
          ),
        ],
      ),
    );
    if (share != true || !context.mounted) return;
    try {
      final bytes = await _statementPdfBytes(data);
      if (!context.mounted) return;
      final safeName =
          data.customer.name.replaceAll(RegExp(r'[^\w\- ]'), '_');
      await SmsService.shareStatementPdf(
        pdfBytes: bytes,
        fileName: 'namt-oil-mil-statement-$safeName.pdf',
        text: text,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? errorText(context, e)
                : AppLocalizations.of(context).error_generic)),
      );
    }
  }

  Future<void> _shareSms(BuildContext context, CustomerDetailData data) async {
    final t = FragmentStrings.of(context);
    final phone = data.customer.phone;
    if (phone == null || phone.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.khata_noPhone)),
      );
      return;
    }
    final isUr = Localizations.localeOf(context).languageCode == 'ur';
    final base = isUr
        ? buildReminderUr(
            partyName: data.customer.name, balancePaisa: data.balancePaisa)
        : buildReminderEn(
            partyName: data.customer.name, balancePaisa: data.balancePaisa);
    try {
      // SMS cannot attach files: the body carries the compact ledger
      // summary, and the full statement PDF is offered right after.
      final body = await ReminderService.smsTextWithLedgerSummary(
        customerId: data.customer.id!,
        reminderText: base,
        balancePaisa: data.balancePaisa,
        script: isUr ? 'ur' : 'en',
      );
      // Prefer direct send; fall back to the SMS app.
      final direct = await SmsService.canSendDirect();
      bool ok;
      if (direct) {
        try {
          ok = await SmsService.sendDirect(phoneNumber: phone, message: body);
        } on SmsException {
          ok = await SmsService.openSmsApp(phoneNumber: phone, message: body);
        }
      } else {
        ok = await SmsService.openSmsApp(phoneNumber: phone, message: body);
      }
      if (!context.mounted) return;
      if (ok) await _offerStatementPdf(context, data, text: body);
    } on SmsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? errorText(context, e)
                : AppLocalizations.of(context).error_generic)),
      );
    }
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
    try {
      // The reminder goes WITH the customer's full ledger statement PDF
      // (user-requested 2026-10-25): wa.me links cannot attach files, so
      // the PDF and the reminder text travel together through the share
      // sheet and the user picks the customer's WhatsApp chat.
      final bytes = await _statementPdfBytes(data);
      if (!context.mounted) return;
      await ref.read(whatsAppServiceProvider).shareReminderWithStatement(
            pdfBytes: bytes,
            customerName: data.customer.name,
            message: '$en\n\n$ur',
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? errorText(context, e)
                : AppLocalizations.of(context).error_generic)),
      );
    }
  }
}

/// One gross-total figure (Total Diye / Total Liye) on the detail screen.
class _TotalChip extends StatelessWidget {
  final String label;
  final String amountText;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _TotalChip({
    required this.label,
    required this.amountText,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amountText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
                size: 30,
                color: iconColor ?? Theme.of(context).colorScheme.onSurface),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child:
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final d = entry.date;
    // Every row shows date AND time (user-requested 2026-10-25), e.g.
    // "Oct 22, 2026 · 11:39 AM" — previously only today's rows showed a
    // time and all other days showed the date alone.
    final dateLabel =
        '${DateFormat.yMMMd(localeTag).format(d)} · ${DateFormat.jm(localeTag).format(d)}';

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
                color: isDiye ? AppColors.pastelPink : AppColors.pastelGreen,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
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
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Bill photo attached to this entry (payment/udhaar flows stamp
        // ledger_entries.bill_image_path): small thumbnail under the
        // description; tap opens it full-screen.
        if (entry.billImagePath != null && entry.billImagePath!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 8),
            child: _BillThumb(path: entry.billImagePath!),
          ),
      ],
    );
  }
}

/// Compact bill-photo thumbnail for a ledger row; tap opens the
/// full-screen viewer. Renders nothing when the file no longer exists.
class _BillThumb extends StatelessWidget {
  final String path;

  const _BillThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    if (!File(path).existsSync()) return const SizedBox.shrink();
    final t = FragmentStrings.of(context);
    return InkWell(
      onTap: () => _showBillImageViewer(context, path),
      borderRadius: BorderRadius.circular(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              width: 96,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t.khata_billAttached,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
