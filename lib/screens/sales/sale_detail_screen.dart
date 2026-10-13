import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart' show InvoiceStatus;
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_detail.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/keys.dart';
import 'package:namt_oil_mil/utils/money.dart';

/// Sale detail (/sale-detail, args: invoice id). Owned by Agent D.
class SaleDetailScreen extends ConsumerWidget {
  final int id;

  const SaleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InvoiceDetailScreen(module: _SaleDetailModule(ref), id: id);
  }
}

class _SaleDetailModule extends InvoiceDetailModule {
  _SaleDetailModule(this.ref);
  final WidgetRef ref;

  @override
  String title(AppLocalizations l10n) => l10n.sales_detailTitle;

  @override
  String lineItemsLabel(AppLocalizations l10n) => l10n.sales_lineItems;

  @override
  String paymentsLabel(AppLocalizations l10n) => l10n.sales_payments;

  @override
  String recordPaymentLabel(AppLocalizations l10n) => l10n.sales_recordPayment;

  @override
  String returnLabel(AppLocalizations l10n) => l10n.sales_returnTitle;

  @override
  String pdfLabel(AppLocalizations l10n) => l10n.sales_invoicePdf;

  @override
  String shareLabel(AppLocalizations l10n) => l10n.sales_share;

  @override
  String returnTitle(AppLocalizations l10n) => l10n.sales_returnTitle;

  @override
  String noReturnableMessage(AppLocalizations l10n) => l10n.sales_noItems;

  @override
  String paymentSavedMessage(AppLocalizations l10n) =>
      l10n.transactions_paymentSaved;

  @override
  String returnPostedMessage(AppLocalizations l10n) =>
      l10n.transactions_returnPosted;

  @override
  String postDraftLabel(AppLocalizations l10n) => l10n.sales_postDraft;

  @override
  String deleteDraftLabel(AppLocalizations l10n) => l10n.sales_deleteDraft;

  @override
  String draftPostedMessage(AppLocalizations l10n, String invoiceNo) =>
      l10n.sales_salePosted(invoiceNo);

  @override
  String draftDeletedMessage(AppLocalizations l10n) => l10n.sales_draftDeleted;

  @override
  String confirmDeleteDraftMessage(AppLocalizations l10n) =>
      l10n.sales_deleteDraft;

  @override
  String statusLabel(AppLocalizations l10n, InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.draft => l10n.sales_statusDraft,
      InvoiceStatus.unpaid => l10n.sales_statusUnpaid,
      InvoiceStatus.partial => l10n.sales_statusPartial,
      InvoiceStatus.paid => l10n.sales_statusPaid,
      InvoiceStatus.returned => l10n.sales_statusReturned,
      InvoiceStatus.cancelled => l10n.sales_statusCancelled,
    };
  }

  @override
  String get documentName => 'saleInvoice';

  @override
  String shareText(AppLocalizations l10n, InvoiceDetailData d) {
    final buf = StringBuffer()
      ..writeln('${l10n.sales_title}: ${d.invoiceNo}')
      ..writeln('${l10n.sales_customer}: ${d.partyName}');
    for (final item in d.items) {
      buf.writeln(
          '• ${item.productName}: ${item.qty.toStringAsFixed(2)} ${item.unitSymbol} × ${formatPkr(item.unitPricePaisa)} = ${formatPkr(item.lineTotalPaisa)}');
    }
    buf
      ..writeln('${l10n.transactions_subtotal}: ${formatPkr(d.subtotalPaisa)}')
      ..writeln('${l10n.transactions_discount}: ${formatPkr(d.discountPaisa)}')
      ..writeln('${l10n.transactions_tax}: ${formatPkr(d.taxPaisa)}')
      ..writeln('${l10n.transactions_total}: ${formatPkr(d.totalPaisa)}')
      ..writeln('${l10n.transactions_paidAmount}: ${formatPkr(d.paidPaisa)}')
      ..writeln('${l10n.transactions_due}: ${formatPkr(d.duePaisa)}');
    return buf.toString();
  }

  @override
  Future<InvoiceDetailData> load(int id) async {
    final sales = await ref.read(salesRepositoryProvider.future);
    final inv = await sales.getById(id);
    if (inv == null) {
      throw AppException('error.invoiceNotFound', {'id': id});
    }
    final customers = await ref.read(customerRepositoryProvider.future);
    final customer = await customers.getById(inv.customerId);
    final items = await sales.getItems(id);
    final products = await ref.read(productRepositoryProvider.future);
    final unitRepo = await ref.read(unitRepositoryProvider.future);
    final units = await unitRepo.getAll();
    final symbols = {for (final u in units) u.id!: u.symbol};
    final itemData = <InvoiceItemData>[];
    for (final it in items) {
      final p = await products.getById(it.productId);
      itemData.add(InvoiceItemData(
        productId: it.productId,
        productName: p?.name ?? '#${it.productId}',
        qty: it.qty,
        unitId: it.unitId,
        unitSymbol: symbols[it.unitId] ?? '',
        unitPricePaisa: it.unitPricePaisa,
        discountPercent: it.discountPercent,
        lineTotalPaisa: it.lineTotalPaisa,
      ));
    }
    return InvoiceDetailData(
      id: inv.id!,
      invoiceNo: inv.invoiceNo,
      partyId: inv.customerId,
      partyName: customer?.name ?? '#${inv.customerId}',
      date: inv.date,
      status: inv.status,
      subtotalPaisa: inv.subtotalPaisa,
      discountPaisa: inv.discountPaisa,
      taxPaisa: inv.taxPaisa,
      totalPaisa: inv.totalPaisa,
      paidPaisa: inv.paidPaisa,
      notes: inv.notes,
      items: itemData,
    );
  }

  @override
  Future<List<InvoicePaymentData>> loadPayments(int invoiceId) async {
    final db = await ref.read(databaseProvider.future);
    final rows = await db.rawQuery(
      'SELECT p.id, p.date, p.amount_paisa, p.reference, '
      'a.name AS account_name '
      'FROM payment_allocations al '
      'JOIN payments p ON p.id = al.payment_id '
      'LEFT JOIN cash_accounts a ON a.id = p.account_id '
      'WHERE al.invoice_type = ? AND al.invoice_id = ? '
      'ORDER BY p.date DESC, p.id DESC',
      ['sale', invoiceId],
    );
    return [
      for (final r in rows)
        InvoicePaymentData(
          id: r['id'] as int,
          date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
          amountPaisa: (r['amount_paisa'] as num).toInt(),
          accountName: (r['account_name'] as String?) ?? '—',
          reference: r['reference'] as String?,
        ),
    ];
  }

  @override
  Future<List<ReturnItemDraft>> returnableItems(int invoiceId) async {
    final data = await load(invoiceId);
    final accounting = await ref.read(accountingServiceProvider.future);
    final returns = await ref.read(returnRepositoryProvider.future);
    final products = await ref.read(productRepositoryProvider.future);

    final returnedBase = <int, double>{};
    final salesReturns = await returns.listSalesReturns(invoiceId: invoiceId);
    for (final r in salesReturns) {
      final rItems = await returns.getSalesReturnItems(r.id!);
      for (final ri in rItems) {
        final prod = await products.getById(ri.productId);
        if (prod == null) continue;
        final base =
            await accounting.convertQty(ri.qty, ri.unitId, prod.baseUnitId);
        returnedBase[ri.productId] = (returnedBase[ri.productId] ?? 0) + base;
      }
    }

    final drafts = <ReturnItemDraft>[];
    for (final item in data.items) {
      final prod = await products.getById(item.productId);
      if (prod == null) continue;
      final soldBase =
          await accounting.convertQty(item.qty, item.unitId, prod.baseUnitId);
      final remainingBase = soldBase - (returnedBase[item.productId] ?? 0);
      if (remainingBase <= 1e-9) continue;
      final maxQty = await accounting.convertQty(
          remainingBase, prod.baseUnitId, item.unitId);
      drafts.add(ReturnItemDraft(
        productId: item.productId,
        productName: item.productName,
        unitId: item.unitId,
        unitSymbol: item.unitSymbol,
        maxQty: maxQty,
        unitPricePaisa: item.unitPricePaisa,
      ));
    }
    return drafts;
  }

  @override
  Future<void> recordPayment({
    required int partyId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    required PaymentMethod method,
    required int invoiceId,
    String? reference,
    String? notes,
  }) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    final sales = await ref.read(salesRepositoryProvider.future);
    final inv = await sales.getById(invoiceId);
    final alloc = amountPaisa.clamp(0, inv?.duePaisa ?? 0);
    await accounting.postCustomerPayment(
      customerId: partyId,
      accountId: accountId,
      amountPaisa: amountPaisa,
      date: date,
      method: method,
      allocations: alloc > 0
          ? [PaymentAllocationInput(invoiceId: invoiceId, amountPaisa: alloc)]
          : const [],
      reference: reference,
      notes: notes,
      idempotencyKey: newIdempotencyKey(),
    );
  }

  @override
  Future<void> postReturn({
    required int? invoiceId,
    required int partyId,
    required DateTime date,
    required List<ReturnLineInput> lines,
    String? reason,
  }) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    await accounting.postSalesReturn(
      invoiceId: invoiceId,
      customerId: partyId,
      date: date,
      lines: lines,
      reason: reason,
      idempotencyKey: newIdempotencyKey(),
    );
  }

  @override
  Future<PostedInvoice> postDraft(int draftId) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    final inv = await accounting.postDraftSale(draftId);
    return PostedInvoice(
      id: inv.id!,
      invoiceNo: inv.invoiceNo,
      totalPaisa: inv.totalPaisa,
    );
  }

  @override
  Future<void> deleteDraft(int draftId) async {
    final sales = await ref.read(salesRepositoryProvider.future);
    await sales.deleteDraft(draftId);
  }
}
