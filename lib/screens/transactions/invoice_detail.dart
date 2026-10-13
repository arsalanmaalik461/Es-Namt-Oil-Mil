import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/payment.dart' show PaymentMethod;
import 'package:namt_oil_mil/models/sales_invoice.dart' show InvoiceStatus;
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/services/accounting_service.dart'
    show ReturnLineInput;
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

// ===========================================================================
// Generic sale/purchase detail screen. Concrete modules supply loading,
// payment posting, returns and labels.
// ===========================================================================

abstract class InvoiceDetailModule {
  String title(AppLocalizations l10n);
  String lineItemsLabel(AppLocalizations l10n);
  String paymentsLabel(AppLocalizations l10n);
  String recordPaymentLabel(AppLocalizations l10n);
  String returnLabel(AppLocalizations l10n);
  String pdfLabel(AppLocalizations l10n);
  String shareLabel(AppLocalizations l10n);
  String returnTitle(AppLocalizations l10n);
  String noReturnableMessage(AppLocalizations l10n);
  String paymentSavedMessage(AppLocalizations l10n);
  String returnPostedMessage(AppLocalizations l10n);
  String statusLabel(AppLocalizations l10n, InvoiceStatus status);

  /// Document name for the Agent F report route, e.g. 'saleInvoice'.
  String get documentName;

  String shareText(AppLocalizations l10n, InvoiceDetailData data);

  Future<InvoiceDetailData> load(int id);
  Future<List<InvoicePaymentData>> loadPayments(int invoiceId);
  Future<List<ReturnItemDraft>> returnableItems(int invoiceId);
  Future<void> recordPayment({
    required int partyId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    required PaymentMethod method,
    required int invoiceId,
    String? reference,
    String? notes,
  });
  Future<void> postReturn({
    required int? invoiceId,
    required int partyId,
    required DateTime date,
    required List<ReturnLineInput> lines,
    String? reason,
  });

  /// Posts a saved draft (no-ops are impossible: drafts carry no effects).
  Future<PostedInvoice> postDraft(int draftId);

  /// Deletes a saved draft.
  Future<void> deleteDraft(int draftId);

  /// Labels for the draft actions.
  String postDraftLabel(AppLocalizations l10n);
  String deleteDraftLabel(AppLocalizations l10n);
  String draftPostedMessage(AppLocalizations l10n, String invoiceNo);
  String draftDeletedMessage(AppLocalizations l10n);
  String confirmDeleteDraftMessage(AppLocalizations l10n);
}

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final InvoiceDetailModule module;
  final int id;

  const InvoiceDetailScreen({
    super.key,
    required this.module,
    required this.id,
  });

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Future<InvoiceDetailData>? _future;
  Future<List<InvoicePaymentData>>? _paymentsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = widget.module.load(widget.id);
      _paymentsFuture = widget.module.loadPayments(widget.id);
    });
  }

  Future<void> _recordPayment(InvoiceDetailData data) async {
    final l10n = AppLocalizations.of(context);
    if (_busy || data.duePaisa <= 0) return;
    setState(() => _busy = true);
    try {
      final accounts = await loadActiveAccounts(ref);
      if (!mounted) return;
      if (accounts.isEmpty) {
        showErrorSnack(context, const AppException('error.accountNotFound'));
        return;
      }
      final result = await showPaymentSheet(
        context,
        duePaisa: data.duePaisa,
        accounts: accounts,
      );
      if (result == null || !mounted) return;
      setState(() => _busy = true);
      await widget.module.recordPayment(
        partyId: data.partyId,
        accountId: result.accountId,
        amountPaisa: result.amountPaisa,
        date: DateTime.now(),
        method: result.method,
        invoiceId: data.id,
        reference: result.reference,
        notes: result.notes,
      );
      if (!mounted) return;
      showInfoSnack(context, widget.module.paymentSavedMessage(l10n));
      _reload();
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _postReturn(InvoiceDetailData data) async {
    final l10n = AppLocalizations.of(context);
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final items = await widget.module.returnableItems(data.id);
      if (!mounted) return;
      if (items.isEmpty) {
        showInfoSnack(context, widget.module.noReturnableMessage(l10n));
        return;
      }
      final result = await showReturnSheet(
        context,
        title: widget.module.returnTitle(l10n),
        items: items,
      );
      if (result == null || !mounted) return;
      setState(() => _busy = true);
      await widget.module.postReturn(
        invoiceId: data.id,
        partyId: data.partyId,
        date: DateTime.now(),
        lines: result.lines,
        reason: result.reason,
      );
      if (!mounted) return;
      showInfoSnack(context, widget.module.returnPostedMessage(l10n));
      _reload();
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openPdf() {
    Navigator.of(context).pushNamed(
      Routes.reportDetail,
      arguments: {
        'document': widget.module.documentName,
        'id': widget.id,
      },
    );
  }

  Future<void> _postDraft(InvoiceDetailData data) async {
    final l10n = AppLocalizations.of(context);
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final posted = await widget.module.postDraft(data.id);
      if (!mounted) return;
      showInfoSnack(
          context, widget.module.draftPostedMessage(l10n, posted.invoiceNo));
      _reload();
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDraft(InvoiceDetailData data) async {
    final l10n = AppLocalizations.of(context);
    if (_busy) return;
    final confirmed = await showConfirmDialog(
      context,
      title: widget.module.deleteDraftLabel(l10n),
      message: widget.module.confirmDeleteDraftMessage(l10n),
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.module.deleteDraft(data.id);
      if (!mounted) return;
      showInfoSnack(context, widget.module.draftDeletedMessage(l10n));
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText(InvoiceDetailData data) async {
    final l10n = AppLocalizations.of(context);
    final text = widget.module.shareText(l10n, data);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final module = widget.module;
    return Scaffold(
      appBar: AppBar(title: Text(module.title(l10n))),
      body: FutureBuilder<InvoiceDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final e = snapshot.error;
            return ErrorState(
              message: e is AppException
                  ? errorText(context, e)
                  : l10n.error_generic,
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final isDraft = data.status == InvoiceStatus.draft;
          final canPay = !isDraft &&
              data.status != InvoiceStatus.cancelled &&
              data.duePaisa > 0;
          final canReturn = !isDraft && data.status != InvoiceStatus.cancelled;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _HeaderCard(data: data, module: module),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isDraft) ...[
                      AppButton(
                        label: module.postDraftLabel(l10n),
                        icon: Icons.check_circle_outline,
                        onPressed: _busy ? null : () => _postDraft(data),
                      ),
                      AppButton(
                        label: module.deleteDraftLabel(l10n),
                        icon: Icons.delete_outline,
                        variant: AppButtonVariant.danger,
                        onPressed: _busy ? null : () => _deleteDraft(data),
                      ),
                    ] else ...[
                      AppButton(
                        label: module.recordPaymentLabel(l10n),
                        icon: Icons.payments_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: (canPay && !_busy)
                            ? () => _recordPayment(data)
                            : null,
                      ),
                      AppButton(
                        label: module.returnLabel(l10n),
                        icon: Icons.keyboard_return_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: (canReturn && !_busy)
                            ? () => _postReturn(data)
                            : null,
                      ),
                    ],
                    AppButton(
                      label: module.pdfLabel(l10n),
                      icon: Icons.picture_as_pdf_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _openPdf,
                    ),
                    AppButton(
                      label: module.shareLabel(l10n),
                      icon: Icons.share_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _shareText(data),
                    ),
                  ],
                ),
              ),
              SectionHeader(title: module.lineItemsLabel(l10n)),
              for (final item in data.items) _ItemRow(item: item),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _TotalRow(
                        label: l10n.transactions_subtotal,
                        paisa: data.subtotalPaisa),
                    _TotalRow(
                        label: l10n.transactions_discount,
                        paisa: data.discountPaisa),
                    _TotalRow(
                        label: l10n.transactions_tax, paisa: data.taxPaisa),
                    const Divider(),
                    _TotalRow(
                      label: l10n.transactions_total,
                      paisa: data.totalPaisa,
                      bold: true,
                    ),
                    _TotalRow(
                        label: l10n.transactions_paidAmount,
                        paisa: data.paidPaisa),
                    _TotalRow(
                      label: l10n.transactions_due,
                      paisa: data.duePaisa,
                      bold: true,
                    ),
                    if (data.notes != null && data.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${l10n.transactions_notes}: ${data.notes}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SectionHeader(title: module.paymentsLabel(l10n)),
              FutureBuilder<List<InvoicePaymentData>>(
                future: _paymentsFuture,
                builder: (context, paySnap) {
                  if (paySnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final pays = paySnap.data ?? const <InvoicePaymentData>[];
                  if (pays.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyState(
                        icon: Icons.payments_outlined,
                        message: l10n.empty_default,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in pays)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payments_outlined, size: 20),
                          ),
                          title: Text(p.accountName),
                          subtitle: Text(
                            '${formatDate(context, p.date)}'
                            '${p.reference == null ? '' : ' · ${p.reference}'}',
                          ),
                          trailing: AmountText(
                            paisa: p.amountPaisa,
                            positive: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final InvoiceDetailData data;
  final InvoiceDetailModule module;

  const _HeaderCard({required this.data, required this.module});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.invoiceNo,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                InvoiceStatusChip(
                  status: data.status,
                  label: module.statusLabel(l10n, data.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.partyName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              formatDate(context, data.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InvoiceItemData item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text(
        '${item.qty.toStringAsFixed(2)} ${item.unitSymbol} × '
        '${formatPkr(item.unitPricePaisa)}'
        '${item.discountPercent > 0 ? ' (−${item.discountPercent.toStringAsFixed(1)}%)' : ''}',
        textDirection: TextDirection.ltr,
      ),
      trailing: AmountText(
        paisa: item.lineTotalPaisa,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final int paisa;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.paisa,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : null,
                  ),
            ),
          ),
          AmountText(
            paisa: paisa,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : null,
                ),
          ),
        ],
      ),
    );
  }
}
