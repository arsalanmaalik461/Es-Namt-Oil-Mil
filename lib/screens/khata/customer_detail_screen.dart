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
import 'udhaar_sheet.dart';

/// Customer detail (`/customer-detail`, args: customer id).
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key});

  int _idOf(BuildContext context) =>
      ModalRoute.of(context)!.settings.arguments as int;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = _idOf(context);
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(customerDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(t.customers_title)),
      body: dataAsync.when(
        data: (data) => _buildBody(context, ref, data),
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
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, CustomerDetailData data) {
    final t = FragmentStrings.of(context);
    final l10n = AppLocalizations.of(context);
    final c = data.customer;
    final id = c.id!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerDetailProvider(id));
        await ref.read(customerDetailProvider(id).future);
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
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(t.customers_giveUdhaar),
                  // Cash udhaar is NOT a sale: post Dr Customer / Cr Cash|Bank
                  // via the sanctioned postCustomerUdhaar path.
                  onPressed: () async {
                    final posted = await showUdhaarSheet(
                      context,
                      ref,
                      customerId: id,
                    );
                    if (posted) {
                      ref.invalidate(customerDetailProvider(id));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.arrow_downward),
                  label: Text(t.customers_receivePayment),
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
              Routes.customerLedger,
              arguments: id,
            ),
          ),
          _ActionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: t.customers_statement,
            onTap: () => Navigator.pushNamed(
              context,
              Routes.reportDetail,
              arguments: {'report': 'customerStatement', 'partyId': id},
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
                kind: PartyKind.customer,
                customer: c,
              );
              if (saved) ref.invalidate(customerDetailProvider(id));
            },
          ),
          _ActionTile(
            icon: c.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            title: c.isArchived ? t.customers_unarchive : t.customers_archive,
            onTap: () => _toggleArchive(context, ref, data),
          ),
          if (c.phone != null || c.address != null) ...[
            const SizedBox(height: 8),
            _InfoCard(data: data),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleArchive(
      BuildContext context, WidgetRef ref, CustomerDetailData data) async {
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
}

class _HeaderCard extends StatelessWidget {
  final CustomerDetailData data;
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
                    data.customer.name.isEmpty
                        ? '?'
                        : data.customer.name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.customer.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (data.customer.businessName != null)
                        Text(data.customer.businessName!,
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
                label: t.customers_totalCredit, paisa: data.totalCreditPaisa),
            _StatRow(
                label: t.customers_totalReceived,
                paisa: data.totalReceivedPaisa),
            if (data.customer.openingBalancePaisa != 0)
              _StatRow(
                label: t.customers_openingBalanceLabel,
                paisa: data.customer.openingBalancePaisa,
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
  final CustomerDetailData data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final c = data.customer;
    return Card(
      child: Column(
        children: [
          if (c.phone != null)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(c.phone!),
              subtitle: Text(t.customers_phone),
            ),
          if (c.address != null)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(c.address!),
              subtitle: Text(t.customers_address),
            ),
          if (c.notes != null)
            ListTile(
              leading: const Icon(Icons.note_outlined),
              title: Text(c.notes!),
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
