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
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/ledger_row.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'khata_providers.dart';
import 'party_form_sheet.dart';
import 'party_txn_sheet.dart';

/// Supplier detail (`/supplier-detail`, args: supplier id).
///
/// Payable semantics: balance > 0 means the business owes the supplier.
class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({super.key});

  int _idOf(BuildContext context) =>
      ModalRoute.of(context)!.settings.arguments as int;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = _idOf(context);
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(supplierDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(t.customers_supplierTitle)),
      body: dataAsync.when(
        data: (data) => _buildBody(context, ref, data),
        loading: () => const LoadingState(),
        error: (e, _) => e is AppException
            ? ErrorState(
                message: errorText(context, e),
                onRetry: () => ref.invalidate(supplierDetailProvider(id)),
              )
            : ErrorState(
                message: l10n.error_generic,
                onRetry: () => ref.invalidate(supplierDetailProvider(id)),
              ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, SupplierDetailData data) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final s = data.supplier;
    final id = s.id!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(supplierDetailProvider(id));
        ref.invalidate(supplierLedgerProvider(LedgerQuery(partyId: id)));
        await ref.read(supplierDetailProvider(id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HeaderCard(data: data),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(t.customers_recordPurchase),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.purchases,
                    arguments: {'supplierId': id},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(t.customers_makePayment),
                  onPressed: () async {
                    final posted = await showPartyTxnSheet(
                      context,
                      ref,
                      isCustomer: false,
                      partyId: id,
                      kind: PartyTxnKind.pay,
                    );
                    if (posted) {
                      ref.invalidate(supplierDetailProvider(id));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: t.customers_viewLedger,
            onTap: () => Navigator.pushNamed(
              context,
              Routes.supplierLedger,
              arguments: id,
            ),
          ),
          _ActionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: t.customers_statement,
            onTap: () => _openStatement(context, id),
          ),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: t.customers_reminder,
            onTap: () => _showReminder(context, data),
          ),
          _ActionTile(
            icon: Icons.edit_outlined,
            title: l10n.common_edit,
            onTap: () async {
              final saved = await showPartyFormSheet(
                context,
                ref,
                kind: PartyKind.supplier,
                supplier: s,
              );
              if (saved) ref.invalidate(supplierDetailProvider(id));
            },
          ),
          _ActionTile(
            icon: s.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            title: s.isArchived ? t.customers_unarchive : t.customers_archive,
            onTap: () => _toggleArchive(context, ref, data),
          ),
          const SizedBox(height: 16),
          _buildLedgerSection(context, ref, id),
          if (s.phone != null || s.address != null) ...[
            const SizedBox(height: 8),
            _InfoCard(data: data),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------- ledger

  /// Full transaction history for THIS supplier, inline on the detail
  /// screen (user-requested 2026-10-25 — previously the detail screen
  /// only linked out to a separate ledger page, unlike customer detail).
  Widget _buildLedgerSection(BuildContext context, WidgetRef ref, int id) {
    final l10n = AppLocalizations.of(context);
    final statementAsync =
        ref.watch(supplierLedgerProvider(LedgerQuery(partyId: id)));
    return statementAsync.when(
      data: (statement) => _buildLedger(context, statement),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: LoadingState(),
      ),
      error: (e, _) => ErrorState(
        message: e is AppException ? errorText(context, e) : l10n.error_generic,
        onRetry: () =>
            ref.invalidate(supplierLedgerProvider(LedgerQuery(partyId: id))),
      ),
    );
  }

  Widget _buildLedger(BuildContext context, LedgerStatement statement) {
    final t = FragmentStrings.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    // Both gross totals for THIS supplier (user-requested 2026-10-25):
    // total "Mainey Diye" (Σ debits — payments made to the supplier) and
    // total "Mainey Liye" (Σ credits — purchases/udhaar taken), not just
    // the net balance. Voided entries never count toward totals.
    var diye = 0;
    var liye = 0;
    for (final line in statement.lines) {
      if (line.entry.voided) continue;
      diye += line.entry.debitPaisa;
      liye += line.entry.creditPaisa;
    }

    // Newest first, like the customer ledger.
    final ordered = statement.lines.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.customers_ledgerTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (diye != 0 || liye != 0) ...[
          const SizedBox(height: 12),
          Row(
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
        ],
        const SizedBox(height: 12),
        if (ordered.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: t.customers_noEntries,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < ordered.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _supplierLedgerRow(context, ordered[i].entry,
                      ordered[i].runningBalancePaisa, localeTag),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _supplierLedgerRow(BuildContext context, LedgerEntry entry,
      int runningBalancePaisa, String localeTag) {
    final desc = entry.description?.trim();
    final title = (desc != null && desc.isNotEmpty)
        ? desc
        : (entry.referenceType?.isNotEmpty == true
            ? entry.referenceType!
            : entry.entryNo);
    // Date AND time on every row (user-requested 2026-10-25).
    final dateLabel =
        '${DateFormat.yMMMd(localeTag).format(entry.date)} · ${DateFormat.jm(localeTag).format(entry.date)}';
    return LedgerRow(
      title: title,
      dateLabel: dateLabel,
      paisa: entry.debitPaisa > 0 ? entry.debitPaisa : entry.creditPaisa,
      // Supplier semantics (same as PartyLedgerView): a credit entry is
      // what increases the payable balance.
      isDebit: entry.creditPaisa > 0,
      runningBalancePaisa: runningBalancePaisa,
    );
  }

  // ------------------------------------------------------------ statement

  /// Opens the supplier statement (PDF preview with Save/Share/Print).
  ///
  /// BUG FIX (2026-10-25): same routing bug as customer detail — this
  /// used to navigate with `{'report': 'supplierStatement', ...}`, but
  /// 'supplierStatement' is a DOCUMENT key: the report screen's loader
  /// has no case for it, so any date selection showed an empty ledger.
  /// Pick the period here, then navigate in document mode.
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
        'document': 'supplierStatement',
        'id': id,
        'from': from,
        'to': to,
      },
    );
  }

  Future<void> _toggleArchive(
      BuildContext context, WidgetRef ref, SupplierDetailData data) async {
    final t = FragmentStrings.of(context);
    final id = data.supplier.id!;
    if (!data.supplier.isArchived) {
      final confirmed = await showConfirmDialog(
        context,
        title: t.customers_archiveTitle(name: data.supplier.name),
        message: t.customers_archiveMessage,
        confirmLabel: t.customers_archive,
      );
      if (!confirmed) return;
    }
    try {
      final repo = await ref.read(supplierRepositoryProvider.future);
      await repo.setArchived(id, !data.supplier.isArchived);
      ref.invalidate(supplierListProvider);
      ref.invalidate(khataSummaryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data.supplier.isArchived
              ? t.customers_supplierRestored
              : t.customers_supplierArchived),
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
      BuildContext context, SupplierDetailData data) async {
    final t = FragmentStrings.of(context);
    final en = buildReminderEn(
        partyName: data.supplier.name, balancePaisa: data.balancePaisa);
    final ur = buildReminderUr(
        partyName: data.supplier.name, balancePaisa: data.balancePaisa);
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
}

class _HeaderCard extends StatelessWidget {
  final SupplierDetailData data;
  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final balance = data.balancePaisa;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    data.supplier.name.isEmpty
                        ? '?'
                        : data.supplier.name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.supplier.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (data.supplier.businessName != null)
                        Text(data.supplier.businessName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.common_balance,
                style: Theme.of(context).textTheme.labelLarge),
            AmountText(
              paisa: balance,
              positive: balance == 0 ? null : balance < 0,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(height: 24),
            _StatRow(
                label: t.customers_totalPurchases,
                paisa: data.totalPurchasesPaisa),
            _StatRow(label: t.customers_totalPaid, paisa: data.totalPaidPaisa),
            if (data.supplier.openingBalancePaisa != 0)
              _StatRow(
                label: t.customers_openingBalanceLabel,
                paisa: data.supplier.openingBalancePaisa,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int paisa;
  const _StatRow({required this.label, required this.paisa});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(formatPkr(paisa),
              style: Theme.of(context).textTheme.bodyMedium,
              textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final SupplierDetailData data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final s = data.supplier;
    return Card(
      child: Column(
        children: [
          if (s.phone != null)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(s.phone!),
              subtitle: Text(t.customers_phone),
            ),
          if (s.address != null)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(s.address!),
              subtitle: Text(t.customers_address),
            ),
          if (s.notes != null)
            ListTile(
              leading: const Icon(Icons.note_outlined),
              title: Text(s.notes!),
              subtitle: Text(t.customers_notes),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
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
          // Half-width chip: scale the amount down instead of ellipsizing
          // it mid-number.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              amountText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
