import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_form.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/keys.dart';

/// New-sale form. All postings go through [AccountingService]; the form only
/// collects inputs and computes live totals in integer paisa.
class SaleFormScreen extends ConsumerWidget {
  const SaleFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InvoiceFormScreen(module: _SaleFormModule(ref));
  }
}

class _SaleFormModule extends InvoiceFormModule {
  _SaleFormModule(this.ref);
  final WidgetRef ref;

  @override
  String title(AppLocalizations l10n) => l10n.sales_formTitle;

  @override
  String partyLabel(AppLocalizations l10n) => l10n.sales_customer;

  @override
  String selectPartyLabel(AppLocalizations l10n) => l10n.sales_selectCustomer;

  @override
  String searchPartyHint(AppLocalizations l10n) => l10n.sales_searchCustomer;

  @override
  String noPartyMessage(AppLocalizations l10n) => l10n.sales_noCustomerSelected;

  @override
  String noItemsMessage(AppLocalizations l10n) => l10n.sales_noItems;

  @override
  String postLabel(AppLocalizations l10n) => l10n.sales_postSale;

  @override
  String postedMessage(AppLocalizations l10n, String invoiceNo) =>
      l10n.sales_salePosted(invoiceNo);

  @override
  String draftSavedMessage(AppLocalizations l10n, String invoiceNo) =>
      l10n.sales_draftSaved(invoiceNo);

  @override
  String confirmPostMessage(AppLocalizations l10n) => l10n.sales_confirmPost;

  @override
  void openDetail(BuildContext context, int id) {
    Navigator.of(context).pushNamed(Routes.saleDetail, arguments: id);
  }

  @override
  Future<List<PartyRef>> searchParties(String query) async {
    final repo = await ref.read(customerRepositoryProvider.future);
    final list = await repo.search(query: query, limit: 50);
    return [
      for (final c in list)
        PartyRef(
          id: c.id!,
          name: c.name,
          phone: c.phone,
          balancePaisa: c.balancePaisa,
        ),
    ];
  }

  @override
  Future<List<ProductRef>> searchProducts(String query) async {
    final repo = await ref.read(productRepositoryProvider.future);
    final unitRepo = await ref.read(unitRepositoryProvider.future);
    final list = await repo.search(query: query, limit: 50);
    final units = await unitRepo.getAll();
    final symbols = {for (final u in units) u.id!: u.symbol};
    return [
      for (final p in list)
        ProductRef(
          id: p.id!,
          name: p.name,
          sku: p.sku,
          baseUnitId: p.baseUnitId,
          baseUnitSymbol: symbols[p.baseUnitId] ?? '',
          defaultPricePaisa: p.defaultSalePricePaisa,
          stockQty: p.stockQty,
        ),
    ];
  }

  List<SaleLineInput> _toLines(InvoicePostArgs args) => [
        for (final l in args.lines)
          SaleLineInput(
            productId: l.productId,
            qty: l.qty,
            unitId: l.unitId,
            unitPricePaisa: l.unitPricePaisa,
            discountPercent: l.discountPercent,
          ),
      ];

  @override
  Future<PostedInvoice> post(InvoicePostArgs args) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    final inv = await accounting.postSale(
      customerId: args.partyId,
      date: args.date,
      lines: _toLines(args),
      discountPercent: args.discountPercent,
      taxPaisa: args.taxPaisa,
      notes: args.notes,
      idempotencyKey: args.idempotencyKey,
    );
    return PostedInvoice(
      id: inv.id!,
      invoiceNo: inv.invoiceNo,
      totalPaisa: inv.totalPaisa,
    );
  }

  @override
  Future<PostedInvoice> createDraft(InvoicePostArgs args) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    final inv = await accounting.createSalesDraft(
      customerId: args.partyId,
      date: args.date,
      lines: _toLines(args),
      discountPercent: args.discountPercent,
      taxPaisa: args.taxPaisa,
      notes: args.notes,
    );
    return PostedInvoice(
      id: inv.id!,
      invoiceNo: inv.invoiceNo,
      totalPaisa: inv.totalPaisa,
    );
  }

  @override
  Future<void> recordInitialPayment({
    required int partyId,
    required int invoiceId,
    required int amountPaisa,
    required DateTime date,
  }) async {
    final accounting = await ref.read(accountingServiceProvider.future);
    final accounts = await loadActiveAccounts(ref);
    if (accounts.isEmpty) {
      throw const AppException('error.accountNotFound');
    }
    final account = accounts.first;
    final sales = await ref.read(salesRepositoryProvider.future);
    final inv = await sales.getById(invoiceId);
    final alloc = amountPaisa.clamp(0, inv?.duePaisa ?? 0);
    await accounting.postCustomerPayment(
      customerId: partyId,
      accountId: account.id!,
      amountPaisa: amountPaisa,
      date: date,
      method: account.type == CashAccountType.cash
          ? PaymentMethod.cash
          : PaymentMethod.bank,
      allocations: alloc > 0
          ? [PaymentAllocationInput(invoiceId: invoiceId, amountPaisa: alloc)]
          : const [],
      idempotencyKey: newIdempotencyKey(),
    );
  }
}
