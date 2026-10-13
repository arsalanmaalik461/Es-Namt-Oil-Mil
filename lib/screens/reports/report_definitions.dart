import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';

/// The 25 reports owned by the reports module.
///
/// The master spec lists 23 named reports; [trialBalance] and [daybook]
/// are added to reach the 25-report catalogue (both are computable from the
/// existing ReportRepository/AccountingService APIs — no data-layer changes).
class ReportDefinition {
  final String key;
  final IconData icon;

  const ReportDefinition(this.key, this.icon);
}

/// Route-argument values for the `report` mode of `/report-detail`.
class ReportKeys {
  static const String dailySummary = 'dailySummary';
  static const String monthlySummary = 'monthlySummary';
  static const String customerLedger = 'customerLedger';
  static const String supplierLedger = 'supplierLedger';
  static const String receivables = 'receivables';
  static const String payables = 'payables';
  static const String sales = 'sales';
  static const String purchase = 'purchase';
  static const String paymentsReceived = 'paymentsReceived';
  static const String paymentsMade = 'paymentsMade';
  static const String expense = 'expense';
  static const String income = 'income';
  static const String cashbook = 'cashbook';
  static const String cashBankBalances = 'cashBankBalances';
  static const String inventoryValuation = 'inventoryValuation';
  static const String stockMovement = 'stockMovement';
  static const String lowStock = 'lowStock';
  static const String production = 'production';
  static const String yieldReport = 'yield';
  static const String salesReturns = 'salesReturns';
  static const String purchaseReturns = 'purchaseReturns';
  static const String outstandingInvoices = 'outstandingInvoices';
  static const String profitLoss = 'profitLoss';
  static const String trialBalance = 'trialBalance';
  static const String daybook = 'daybook';

  const ReportKeys._();
}

/// Route-argument values for the `document` mode of `/report-detail`.
class DocumentKeys {
  static const String saleInvoice = 'saleInvoice';
  static const String purchaseVoucher = 'purchaseVoucher';
  static const String paymentReceipt = 'paymentReceipt';
  static const String supplierPaymentVoucher = 'supplierPaymentVoucher';
  static const String customerStatement = 'customerStatement';
  static const String supplierStatement = 'supplierStatement';
  static const String cashReceipt = 'cashReceipt';
  static const String expenseVoucher = 'expenseVoucher';
  static const String productionReport = 'productionReport';

  const DocumentKeys._();
}

/// All 25 reports in hub display order.
const List<ReportDefinition> reportDefinitions = [
  ReportDefinition(ReportKeys.dailySummary, Icons.today_outlined),
  ReportDefinition(ReportKeys.monthlySummary, Icons.calendar_month_outlined),
  ReportDefinition(ReportKeys.customerLedger, Icons.book_outlined),
  ReportDefinition(ReportKeys.supplierLedger, Icons.bookmarks_outlined),
  ReportDefinition(ReportKeys.receivables, Icons.trending_up_outlined),
  ReportDefinition(ReportKeys.payables, Icons.trending_down_outlined),
  ReportDefinition(ReportKeys.sales, Icons.point_of_sale_outlined),
  ReportDefinition(ReportKeys.purchase, Icons.shopping_cart_outlined),
  ReportDefinition(
      ReportKeys.paymentsReceived, Icons.arrow_circle_down_outlined),
  ReportDefinition(ReportKeys.paymentsMade, Icons.arrow_circle_up_outlined),
  ReportDefinition(ReportKeys.expense, Icons.money_off_outlined),
  ReportDefinition(ReportKeys.income, Icons.attach_money_outlined),
  ReportDefinition(ReportKeys.cashbook, Icons.account_balance_wallet_outlined),
  ReportDefinition(ReportKeys.cashBankBalances, Icons.account_balance_outlined),
  ReportDefinition(ReportKeys.inventoryValuation, Icons.inventory_2_outlined),
  ReportDefinition(ReportKeys.stockMovement, Icons.swap_horiz_outlined),
  ReportDefinition(ReportKeys.lowStock, Icons.warning_amber_outlined),
  ReportDefinition(ReportKeys.production, Icons.factory_outlined),
  ReportDefinition(ReportKeys.yieldReport, Icons.percent_outlined),
  ReportDefinition(ReportKeys.salesReturns, Icons.assignment_return_outlined),
  ReportDefinition(
      ReportKeys.purchaseReturns, Icons.assignment_returned_outlined),
  ReportDefinition(ReportKeys.outstandingInvoices, Icons.receipt_long_outlined),
  ReportDefinition(ReportKeys.profitLoss, Icons.show_chart_outlined),
  ReportDefinition(ReportKeys.trialBalance, Icons.balance_outlined),
  ReportDefinition(ReportKeys.daybook, Icons.event_note_outlined),
];

/// Localized hub/detail title for a report key.
String reportTitle(FragmentStrings t, String key) {
  switch (key) {
    case ReportKeys.dailySummary:
      return t.reports_dailySummary;
    case ReportKeys.monthlySummary:
      return t.reports_monthlySummary;
    case ReportKeys.customerLedger:
      return t.reports_customerLedger;
    case ReportKeys.supplierLedger:
      return t.reports_supplierLedger;
    case ReportKeys.receivables:
      return t.reports_receivables;
    case ReportKeys.payables:
      return t.reports_payables;
    case ReportKeys.sales:
      return t.reports_sales;
    case ReportKeys.purchase:
      return t.reports_purchase;
    case ReportKeys.paymentsReceived:
      return t.reports_paymentsReceived;
    case ReportKeys.paymentsMade:
      return t.reports_paymentsMade;
    case ReportKeys.expense:
      return t.reports_expense;
    case ReportKeys.income:
      return t.reports_income;
    case ReportKeys.cashbook:
      return t.reports_cashbook;
    case ReportKeys.cashBankBalances:
      return t.reports_cashBankBalances;
    case ReportKeys.inventoryValuation:
      return t.reports_inventoryValuation;
    case ReportKeys.stockMovement:
      return t.reports_stockMovement;
    case ReportKeys.lowStock:
      return t.reports_lowStock;
    case ReportKeys.production:
      return t.reports_production;
    case ReportKeys.yieldReport:
      return t.reports_yield;
    case ReportKeys.salesReturns:
      return t.reports_salesReturns;
    case ReportKeys.purchaseReturns:
      return t.reports_purchaseReturns;
    case ReportKeys.outstandingInvoices:
      return t.reports_outstandingInvoices;
    case ReportKeys.profitLoss:
      return t.reports_profitLoss;
    case ReportKeys.trialBalance:
      return t.reports_trialBalance;
    case ReportKeys.daybook:
      return t.reports_daybook;
    default:
      return key;
  }
}

/// Localized title for a document type.
String documentTitle(FragmentStrings t, String documentType) {
  switch (documentType) {
    case DocumentKeys.saleInvoice:
      return t.reports_doc_saleInvoice;
    case DocumentKeys.purchaseVoucher:
      return t.reports_doc_purchaseVoucher;
    case DocumentKeys.paymentReceipt:
      return t.reports_doc_paymentReceipt;
    case DocumentKeys.supplierPaymentVoucher:
      return t.reports_doc_supplierPaymentVoucher;
    case DocumentKeys.customerStatement:
      return t.reports_doc_customerStatement;
    case DocumentKeys.supplierStatement:
      return t.reports_doc_supplierStatement;
    case DocumentKeys.cashReceipt:
      return t.reports_doc_cashReceipt;
    case DocumentKeys.expenseVoucher:
      return t.reports_doc_expenseVoucher;
    case DocumentKeys.productionReport:
      return t.reports_doc_productionReport;
    default:
      return documentType;
  }
}
