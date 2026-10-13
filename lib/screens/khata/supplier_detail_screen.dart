import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
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
            onTap: () => Navigator.pushNamed(
              context,
              Routes.reportDetail,
              arguments: {'report': 'supplierStatement', 'partyId': id},
            ),
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
          if (s.phone != null || s.address != null) ...[
            const SizedBox(height: 8),
            _InfoCard(data: data),
          ],
        ],
      ),
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
