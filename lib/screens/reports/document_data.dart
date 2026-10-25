import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/screens/reports/report_definitions.dart';
import 'package:namt_oil_mil/services/pdf/pdf_service.dart';
import 'package:namt_oil_mil/utils/money.dart';

/// Assembles a [PdfDocumentData] for any of the nine printable document
/// types from the repositories (per docs/API.md — read-only).
///
/// The same data object backs the on-screen preview, Save PDF, Share and
/// Print, so what the user previews is exactly what gets printed.
///
/// Document types (`document` route arg): saleInvoice, purchaseVoucher,
/// paymentReceipt, supplierPaymentVoucher, customerStatement,
/// supplierStatement, cashReceipt (other-income receipt), expenseVoucher,
/// productionReport.
Future<PdfDocumentData> buildDocumentData({
  required WidgetRef ref,
  required String documentType,
  required int id,
  required FragmentStrings t,
  required BusinessProfile business,
  required String Function(DateTime) formatDate,
  DateTime? from,
  DateTime? to,
}) async {
  switch (documentType) {
    case DocumentKeys.saleInvoice:
      return _saleInvoice(ref, id, t, business, formatDate);
    case DocumentKeys.purchaseVoucher:
      return _purchaseVoucher(ref, id, t, business, formatDate);
    case DocumentKeys.paymentReceipt:
      return _paymentReceipt(ref, id, t, business, formatDate);
    case DocumentKeys.supplierPaymentVoucher:
      return _supplierPaymentVoucher(ref, id, t, business, formatDate);
    case DocumentKeys.customerStatement:
      return _customerStatement(ref, id, t, business, formatDate,
          from: from, to: to);
    case DocumentKeys.supplierStatement:
      return _supplierStatement(ref, id, t, business, formatDate,
          from: from, to: to);
    case DocumentKeys.cashReceipt:
      return _cashReceipt(ref, id, t, business, formatDate);
    case DocumentKeys.expenseVoucher:
      return _expenseVoucher(ref, id, t, business, formatDate);
    case DocumentKeys.productionReport:
      return _productionReport(ref, id, t, business, formatDate);
    default:
      throw ValidationException('error.invoiceNotFound', {'id': id});
  }
}

String _fmtQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toStringAsFixed(2);
}

String _invoiceStatus(FragmentStrings t, InvoiceStatus s) {
  switch (s) {
    case InvoiceStatus.paid:
      return t.reports_paid;
    case InvoiceStatus.unpaid:
      return t.reports_unpaid;
    case InvoiceStatus.partial:
      return t.reports_partial;
    default:
      return s.dbValue;
  }
}

String _method(FragmentStrings t, PaymentMethod m) =>
    m == PaymentMethod.cash ? t.reports_doc_cash : t.reports_doc_bank;

PdfDocumentData _branded({
  required String title,
  required BusinessProfile business,
  required List<PdfMetaRow> meta,
  List<String> columns = const [],
  List<List<String>> rows = const [],
  List<PdfMetaRow> totals = const [],
  String? notesTitle,
  String? notes,
  String? footerNote,
}) {
  return PdfDocumentData(
    title: title,
    businessName: business.name,
    businessAddress: business.address,
    businessPhone: business.phone,
    meta: meta,
    columns: columns,
    rows: rows,
    totals: totals,
    notesTitle: notesTitle,
    notes: notes,
    footerNote: footerNote,
  );
}

Future<String> _productLabel(
    WidgetRef ref, int productId, int unitId, double qty) async {
  final products = await ref.read(productRepositoryProvider.future);
  final units = await ref.read(unitRepositoryProvider.future);
  final product = await products.getById(productId);
  final unit = await units.getById(unitId);
  final name = product?.name ?? '#$productId';
  final symbol = unit?.symbol ?? '';
  // ASCII hyphen, not an em dash: the PDF built-in fonts cannot draw
  // U+2014 (see pdfSafeText in pdf_service.dart).
  return '$name - ${_fmtQty(qty)} $symbol'.trim();
}

// ------------------------------------------------------------------ invoices

Future<PdfDocumentData> _saleInvoice(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final sales = await ref.read(salesRepositoryProvider.future);
  final inv = await sales.getById(id);
  if (inv == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final customers = await ref.read(customerRepositoryProvider.future);
  final customer = await customers.getById(inv.customerId);
  if (customer == null) {
    throw const ValidationException('error.customerNotFound');
  }
  final items = await sales.getItems(id);
  final rows = <List<String>>[];
  for (final item in items) {
    rows.add([
      await _productLabel(ref, item.productId, item.unitId, item.qty),
      formatPkr(item.unitPricePaisa),
      formatPkr(item.lineTotalPaisa),
    ]);
  }
  return _branded(
    title: t.reports_doc_saleInvoice,
    business: business,
    meta: [
      PdfMetaRow(t.reports_doc_invoiceNo, inv.invoiceNo),
      PdfMetaRow(t.reports_doc_date, formatDate(inv.date)),
      PdfMetaRow(t.reports_doc_status, _invoiceStatus(t, inv.status)),
      PdfMetaRow(t.reports_doc_billTo, customer.name),
      if ((customer.phone ?? '').isNotEmpty)
        PdfMetaRow(t.customers_phone, customer.phone!),
    ],
    columns: [t.reports_doc_item, t.reports_doc_price, t.reports_doc_amount],
    rows: rows,
    totals: [
      PdfMetaRow(t.reports_doc_subtotal, formatPkr(inv.subtotalPaisa)),
      if (inv.discountPaisa > 0)
        PdfMetaRow(t.reports_doc_discount, formatPkr(inv.discountPaisa)),
      if (inv.taxPaisa > 0)
        PdfMetaRow(t.reports_doc_tax, formatPkr(inv.taxPaisa)),
      PdfMetaRow(t.reports_doc_total, formatPkr(inv.totalPaisa)),
      PdfMetaRow(t.reports_doc_paid, formatPkr(inv.paidPaisa)),
      PdfMetaRow(t.reports_doc_due, formatPkr(inv.totalPaisa - inv.paidPaisa)),
    ],
    notesTitle: t.reports_doc_notes,
    notes: inv.notes,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

Future<PdfDocumentData> _purchaseVoucher(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final purchases = await ref.read(purchaseRepositoryProvider.future);
  final inv = await purchases.getById(id);
  if (inv == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final suppliers = await ref.read(supplierRepositoryProvider.future);
  final supplier = await suppliers.getById(inv.supplierId);
  if (supplier == null) {
    throw const ValidationException('error.supplierNotFound');
  }
  final items = await purchases.getItems(id);
  final rows = <List<String>>[];
  for (final item in items) {
    rows.add([
      await _productLabel(ref, item.productId, item.unitId, item.qty),
      formatPkr(item.unitPricePaisa),
      formatPkr(item.lineTotalPaisa),
    ]);
  }
  return _branded(
    title: t.reports_doc_purchaseVoucher,
    business: business,
    meta: [
      PdfMetaRow(t.reports_doc_invoiceNo, inv.invoiceNo),
      PdfMetaRow(t.reports_doc_date, formatDate(inv.date)),
      PdfMetaRow(t.reports_doc_status, _invoiceStatus(t, inv.status)),
      PdfMetaRow(t.reports_doc_supplier, supplier.name),
      if ((supplier.phone ?? '').isNotEmpty)
        PdfMetaRow(t.customers_phone, supplier.phone!),
    ],
    columns: [t.reports_doc_item, t.reports_doc_price, t.reports_doc_amount],
    rows: rows,
    totals: [
      PdfMetaRow(t.reports_doc_subtotal, formatPkr(inv.subtotalPaisa)),
      if (inv.discountPaisa > 0)
        PdfMetaRow(t.reports_doc_discount, formatPkr(inv.discountPaisa)),
      if (inv.taxPaisa > 0)
        PdfMetaRow(t.reports_doc_tax, formatPkr(inv.taxPaisa)),
      PdfMetaRow(t.reports_doc_total, formatPkr(inv.totalPaisa)),
      PdfMetaRow(t.reports_doc_paid, formatPkr(inv.paidPaisa)),
      PdfMetaRow(t.reports_doc_due, formatPkr(inv.totalPaisa - inv.paidPaisa)),
    ],
    notesTitle: t.reports_doc_notes,
    notes: inv.notes,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

// ------------------------------------------------------------------ payments

Future<PdfDocumentData> _paymentDoc({
  required WidgetRef ref,
  required int id,
  required FragmentStrings t,
  required BusinessProfile business,
  required String Function(DateTime) formatDate,
  required String title,
  required String partyLabel,
  required String partyName,
  String? partyPhone,
}) async {
  final payments = await ref.read(paymentRepositoryProvider.future);
  final payment = await payments.getById(id);
  if (payment == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final accounts = await ref.read(cashAccountRepositoryProvider.future);
  final account = await accounts.getById(payment.accountId);
  return _branded(
    title: title,
    business: business,
    meta: [
      PdfMetaRow(t.reports_doc_date, formatDate(payment.date)),
      PdfMetaRow(partyLabel, partyName),
      if ((partyPhone ?? '').isNotEmpty)
        PdfMetaRow(t.customers_phone, partyPhone!),
      PdfMetaRow(
          t.reports_doc_account, account?.name ?? '#${payment.accountId}'),
      PdfMetaRow(t.reports_doc_method, _method(t, payment.method)),
      if ((payment.reference ?? '').isNotEmpty)
        PdfMetaRow(t.reports_doc_reference, payment.reference!),
    ],
    totals: [
      PdfMetaRow(t.reports_doc_amount, formatPkr(payment.amountPaisa)),
    ],
    notesTitle: t.reports_doc_notes,
    notes: payment.notes,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

Future<PdfDocumentData> _paymentReceipt(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final payments = await ref.read(paymentRepositoryProvider.future);
  final payment = await payments.getById(id);
  if (payment == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final customers = await ref.read(customerRepositoryProvider.future);
  final customer = await customers.getById(payment.partyId);
  return _paymentDoc(
    ref: ref,
    id: id,
    t: t,
    business: business,
    formatDate: formatDate,
    title: t.reports_doc_paymentReceipt,
    partyLabel: t.reports_doc_receivedFrom,
    partyName: customer?.name ?? '#${payment.partyId}',
    partyPhone: customer?.phone,
  );
}

Future<PdfDocumentData> _supplierPaymentVoucher(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final payments = await ref.read(paymentRepositoryProvider.future);
  final payment = await payments.getById(id);
  if (payment == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final suppliers = await ref.read(supplierRepositoryProvider.future);
  final supplier = await suppliers.getById(payment.partyId);
  return _paymentDoc(
    ref: ref,
    id: id,
    t: t,
    business: business,
    formatDate: formatDate,
    title: t.reports_doc_supplierPaymentVoucher,
    partyLabel: t.reports_doc_paidTo,
    partyName: supplier?.name ?? '#${payment.partyId}',
    partyPhone: supplier?.phone,
  );
}

// ---------------------------------------------------------------- statements

/// Statement rows carry date AND time (entries record a time of day —
/// user-requested 2026-10-25), e.g. "Oct 22, 2026 · 11:39 AM".
/// [formatDate] stays the caller's locale-aware date format; the time is
/// appended in `h:mm a` form. The `·` separator is U+00B7 — inside the
/// built-in PDF fonts' Latin-1 coverage (byte-verified), so it is safe
/// in the PDF too, unlike dashes (see pdfSafeText in pdf_service.dart).
String _fmtDateTime(String Function(DateTime) formatDate, DateTime d) =>
    '${formatDate(d)} · ${DateFormat.jm().format(d)}';

Future<PdfDocumentData> _statementDoc({
  required WidgetRef ref,
  required int partyId,
  required bool isCustomer,
  required FragmentStrings t,
  required BusinessProfile business,
  required String Function(DateTime) formatDate,
  DateTime? from,
  DateTime? to,
}) async {
  final now = DateTime.now();
  final start = from ??
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 90));
  final end =
      to ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

  final reports = await ref.read(reportRepositoryProvider.future);
  final statement = isCustomer
      ? await reports.customerLedger(partyId, from: start, to: end)
      : await reports.supplierLedger(partyId, from: start, to: end);

  String partyName = '#$partyId';
  String? partyPhone;
  if (isCustomer) {
    final customers = await ref.read(customerRepositoryProvider.future);
    final c = await customers.getById(partyId);
    if (c == null) throw const ValidationException('error.customerNotFound');
    partyName = c.name;
    partyPhone = c.phone;
  } else {
    final suppliers = await ref.read(supplierRepositoryProvider.future);
    final s = await suppliers.getById(partyId);
    if (s == null) throw const ValidationException('error.supplierNotFound');
    partyName = s.name;
    partyPhone = s.phone;
  }

  final rows = <List<String>>[];
  for (final line in statement.lines) {
    final e = line.entry;
    rows.add([
      _fmtDateTime(formatDate, e.date),
      e.description ?? e.entryNo,
      e.debitPaisa > 0 ? formatPkr(e.debitPaisa) : '-',
      e.creditPaisa > 0 ? formatPkr(e.creditPaisa) : '-',
      formatPkr(line.runningBalancePaisa),
    ]);
  }
  return _branded(
    title: isCustomer
        ? t.reports_doc_customerStatement
        : t.reports_doc_supplierStatement,
    business: business,
    meta: [
      PdfMetaRow(isCustomer ? t.reports_doc_customer : t.reports_doc_supplier,
          partyName),
      if ((partyPhone ?? '').isNotEmpty)
        PdfMetaRow(t.customers_phone, partyPhone!),
      // "Jan 1, 2000 to Dec 31, 2099" — an en dash (U+2013) cannot be
      // drawn by the PDF built-in fonts and showed as a broken glyph.
      PdfMetaRow(t.reports_doc_period,
          '${formatDate(start)} to ${formatDate(end.subtract(const Duration(days: 1)))}'),
    ],
    columns: [
      t.reports_doc_date,
      t.reports_doc_description,
      t.reports_doc_debit,
      t.reports_doc_credit,
      t.reports_doc_balance,
    ],
    rows: rows,
    totals: [
      PdfMetaRow(t.reports_doc_openingBalance,
          formatPkr(statement.openingBalancePaisa)),
      PdfMetaRow(t.reports_doc_closingBalance,
          formatPkr(statement.closingBalancePaisa)),
    ],
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

Future<PdfDocumentData> _customerStatement(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate, {
  DateTime? from,
  DateTime? to,
}) =>
    _statementDoc(
      ref: ref,
      partyId: id,
      isCustomer: true,
      t: t,
      business: business,
      formatDate: formatDate,
      from: from,
      to: to,
    );

Future<PdfDocumentData> _supplierStatement(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate, {
  DateTime? from,
  DateTime? to,
}) =>
    _statementDoc(
      ref: ref,
      partyId: id,
      isCustomer: false,
      t: t,
      business: business,
      formatDate: formatDate,
      from: from,
      to: to,
    );

// ------------------------------------------------------- cash/income/expense

/// cashReceipt = receipt for an other-income entry (IncomeEntry).
/// IncomeRepository exposes no getById, so the entry is found via list.
Future<PdfDocumentData> _cashReceipt(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final income = await ref.read(incomeRepositoryProvider.future);
  final entries = await income.list(limit: 100000);
  final entry = entries.where((e) => e.id == id).firstOrNull;
  if (entry == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final accounts = await ref.read(cashAccountRepositoryProvider.future);
  final account = await accounts.getById(entry.accountId);
  return _branded(
    title: t.reports_doc_cashReceipt,
    business: business,
    meta: [
      PdfMetaRow(t.reports_doc_date, formatDate(entry.date)),
      if ((entry.category ?? '').isNotEmpty)
        PdfMetaRow(t.reports_doc_category, entry.category!),
      PdfMetaRow(t.reports_doc_account, account?.name ?? '#${entry.accountId}'),
      if ((entry.reference ?? '').isNotEmpty)
        PdfMetaRow(t.reports_doc_reference, entry.reference!),
    ],
    totals: [
      PdfMetaRow(t.reports_doc_amount, formatPkr(entry.amountPaisa)),
    ],
    notesTitle: t.reports_doc_description,
    notes: entry.description,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

/// ExpenseRepository exposes no getById, so the entry is found via list.
Future<PdfDocumentData> _expenseVoucher(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final expenses = await ref.read(expenseRepositoryProvider.future);
  final entries = await expenses.list(limit: 100000);
  final entry = entries.where((e) => e.id == id).firstOrNull;
  if (entry == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final category = await expenses.getCategoryById(entry.categoryId);
  final accounts = await ref.read(cashAccountRepositoryProvider.future);
  final account = await accounts.getById(entry.accountId);
  return _branded(
    title: t.reports_doc_expenseVoucher,
    business: business,
    meta: [
      PdfMetaRow(t.reports_doc_date, formatDate(entry.date)),
      PdfMetaRow(
          t.reports_doc_category, category?.name ?? '#${entry.categoryId}'),
      PdfMetaRow(t.reports_doc_account, account?.name ?? '#${entry.accountId}'),
      if ((entry.reference ?? '').isNotEmpty)
        PdfMetaRow(t.reports_doc_reference, entry.reference!),
    ],
    totals: [
      PdfMetaRow(t.reports_doc_amount, formatPkr(entry.amountPaisa)),
    ],
    notesTitle: t.reports_doc_description,
    notes: entry.description,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}

// ---------------------------------------------------------------- production

String _outputTypeLabel(FragmentStrings t, OutputType type) {
  switch (type) {
    case OutputType.finishedOil:
      return t.reports_production;
    case OutputType.oilCake:
      return t.reports_doc_oilCake;
    case OutputType.byProduct:
      return t.reports_doc_byProduct;
  }
}

Future<PdfDocumentData> _productionReport(
  WidgetRef ref,
  int id,
  FragmentStrings t,
  BusinessProfile business,
  String Function(DateTime) formatDate,
) async {
  final production = await ref.read(productionRepositoryProvider.future);
  final batch = await production.getBatch(id);
  if (batch == null) {
    throw ValidationException('error.invoiceNotFound', {'id': id});
  }
  final inputs = await production.getInputs(id);
  final outputs = await production.getOutputs(id);

  final inputRows = <List<String>>[];
  for (final i in inputs) {
    inputRows.add([
      await _productLabel(ref, i.productId, i.unitId, i.qty),
    ]);
  }
  final outputRows = <List<String>>[];
  for (final o in outputs) {
    outputRows.add([
      await _productLabel(ref, o.productId, o.unitId, o.qty),
      _outputTypeLabel(t, o.outputType),
    ]);
  }

  final meta = [
    PdfMetaRow(t.reports_doc_batchNo, batch.batchNo),
    PdfMetaRow(t.reports_doc_date, formatDate(batch.date)),
    PdfMetaRow(
        t.reports_doc_yield,
        batch.yieldPct == null
            ? '-'
            : '${batch.yieldPct!.toStringAsFixed(1)}%'),
  ];
  // Inputs and outputs share one table section each via meta rows is not
  // possible, so outputs go in the items table and inputs above as rows.
  final rows = <List<String>>[
    [t.reports_doc_inputs, ''],
    for (final r in inputRows) [r.first, ''],
    [t.reports_doc_outputs, ''],
    for (final r in outputRows) r,
  ];
  return _branded(
    title: t.reports_doc_productionReport,
    business: business,
    meta: meta,
    columns: [t.reports_doc_item, t.reports_doc_description],
    rows: rows,
    totals: [
      if (batch.labourCostPaisa > 0)
        PdfMetaRow(t.reports_doc_labour, formatPkr(batch.labourCostPaisa)),
      if (batch.electricityCostPaisa > 0)
        PdfMetaRow(
            t.reports_doc_electricity, formatPkr(batch.electricityCostPaisa)),
      if (batch.otherCostPaisa > 0)
        PdfMetaRow(t.reports_doc_other, formatPkr(batch.otherCostPaisa)),
    ],
    notesTitle: t.reports_doc_notes,
    notes: batch.notes,
    footerNote: t.reports_doc_generatedOn(date: formatDate(DateTime.now())),
  );
}
