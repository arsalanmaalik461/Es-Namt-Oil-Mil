import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/expense_entry.dart';
import 'package:namt_oil_mil/models/income_entry.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/purchase_invoice.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/models/supplier.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';

/// Module-local providers for the khata + dashboard UI (Agent C).
///
/// These compose the data-layer providers from `db_providers.dart` into
/// screen-ready aggregates. Balance math stays in [AccountingService];
/// these providers only aggregate or pass through authoritative figures.

// ------------------------------------------------------------------ khata hub

/// Outstanding totals for the khata hub.
class KhataSummary {
  final int receivablePaisa;
  final int payablePaisa;
  final int receivableCount;
  final int payableCount;
  const KhataSummary({
    required this.receivablePaisa,
    required this.payablePaisa,
    required this.receivableCount,
    required this.payableCount,
  });
}

final khataSummaryProvider = FutureProvider<KhataSummary>((ref) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  final results = await Future.wait([
    accounting.receivables(),
    accounting.payables(),
  ]);
  final receivables = results[0] as List<Customer>;
  final payables = results[1] as List<Supplier>;
  return KhataSummary(
    receivablePaisa: receivables.fold(0, (sum, c) => sum + c.balancePaisa),
    payablePaisa: payables.fold(0, (sum, s) => sum + s.balancePaisa),
    receivableCount: receivables.length,
    payableCount: payables.length,
  );
});

// ------------------------------------------------------------ party lists

/// Balance filter for the customer / supplier list screens.
enum PartyBalanceFilter { all, positive, negative }

/// Query object for the paged party search (family argument).
class PartyListQuery {
  final String search;
  final PartyBalanceFilter filter;
  const PartyListQuery(
      {this.search = '', this.filter = PartyBalanceFilter.all});

  @override
  bool operator ==(Object other) =>
      other is PartyListQuery &&
      other.search == search &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(search, filter);
}

final customerListProvider = FutureProvider.autoDispose
    .family<List<Customer>, PartyListQuery>((ref, query) async {
  final repo = await ref.watch(customerRepositoryProvider.future);
  final all = await repo.search(query: query.search, limit: 200);
  return switch (query.filter) {
    PartyBalanceFilter.all => all,
    PartyBalanceFilter.positive =>
      all.where((c) => c.balancePaisa > 0).toList(),
    PartyBalanceFilter.negative =>
      all.where((c) => c.balancePaisa < 0).toList(),
  };
});

final supplierListProvider = FutureProvider.autoDispose
    .family<List<Supplier>, PartyListQuery>((ref, query) async {
  final repo = await ref.watch(supplierRepositoryProvider.future);
  final all = await repo.search(query: query.search, limit: 200);
  return switch (query.filter) {
    PartyBalanceFilter.all => all,
    PartyBalanceFilter.positive =>
      all.where((s) => s.balancePaisa > 0).toList(),
    PartyBalanceFilter.negative =>
      all.where((s) => s.balancePaisa < 0).toList(),
  };
});

// ------------------------------------------------------------ party detail

/// Everything the customer detail header needs.
class CustomerDetailData {
  final Customer customer;
  final int balancePaisa;
  final int totalCreditPaisa;
  final int totalReceivedPaisa;
  const CustomerDetailData({
    required this.customer,
    required this.balancePaisa,
    required this.totalCreditPaisa,
    required this.totalReceivedPaisa,
  });
}

final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetailData, int>((ref, id) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  final customerRepo = await ref.watch(customerRepositoryProvider.future);
  final salesRepo = await ref.watch(salesRepositoryProvider.future);
  final paymentRepo = await ref.watch(paymentRepositoryProvider.future);

  final customer = await customerRepo.getById(id);
  if (customer == null) {
    throw const AppException('error.customerNotFound');
  }
  final results = await Future.wait([
    accounting.getCustomerBalancePaisa(id),
    salesRepo.list(customerId: id, limit: 1000),
    paymentRepo.list(partyType: PartyType.customer, partyId: id, limit: 1000),
  ]);
  final sales = results[1] as List<SalesInvoice>;
  final payments = results[2] as List<Payment>;
  return CustomerDetailData(
    customer: customer,
    balancePaisa: results[0] as int,
    totalCreditPaisa: sales.fold(0, (sum, i) => sum + i.totalPaisa),
    totalReceivedPaisa: payments
        .where((p) => p.direction == PaymentDirection.received)
        .fold(0, (sum, p) => sum + p.amountPaisa),
  );
});

/// Everything the supplier detail header needs.
class SupplierDetailData {
  final Supplier supplier;
  final int balancePaisa;
  final int totalPurchasesPaisa;
  final int totalPaidPaisa;
  const SupplierDetailData({
    required this.supplier,
    required this.balancePaisa,
    required this.totalPurchasesPaisa,
    required this.totalPaidPaisa,
  });
}

final supplierDetailProvider =
    FutureProvider.autoDispose.family<SupplierDetailData, int>((ref, id) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  final supplierRepo = await ref.watch(supplierRepositoryProvider.future);
  final purchaseRepo = await ref.watch(purchaseRepositoryProvider.future);
  final paymentRepo = await ref.watch(paymentRepositoryProvider.future);

  final supplier = await supplierRepo.getById(id);
  if (supplier == null) {
    throw const AppException('error.supplierNotFound');
  }
  final results = await Future.wait([
    accounting.getSupplierBalancePaisa(id),
    purchaseRepo.list(supplierId: id, limit: 1000),
    paymentRepo.list(partyType: PartyType.supplier, partyId: id, limit: 1000),
  ]);
  final purchases = results[1] as List<PurchaseInvoice>;
  final payments = results[2] as List<Payment>;
  return SupplierDetailData(
    supplier: supplier,
    balancePaisa: results[0] as int,
    totalPurchasesPaisa: purchases.fold(0, (sum, i) => sum + i.totalPaisa),
    totalPaidPaisa: payments
        .where((p) => p.direction == PaymentDirection.paid)
        .fold(0, (sum, p) => sum + p.amountPaisa),
  );
});

// ------------------------------------------------------------------ ledgers

/// Date-window query for a party ledger (family argument).
class LedgerQuery {
  final int partyId;
  final DateTime? from; // inclusive
  final DateTime? to; // exclusive
  const LedgerQuery({required this.partyId, this.from, this.to});

  @override
  bool operator ==(Object other) =>
      other is LedgerQuery &&
      other.partyId == partyId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(partyId, from, to);
}

final customerLedgerProvider = FutureProvider.autoDispose
    .family<LedgerStatement, LedgerQuery>((ref, query) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  return accounting.ledgerWithRunningBalance(
    accountType: AccountType.customer,
    accountId: query.partyId,
    from: query.from,
    to: query.to,
  );
});

final supplierLedgerProvider = FutureProvider.autoDispose
    .family<LedgerStatement, LedgerQuery>((ref, query) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  return accounting.ledgerWithRunningBalance(
    accountType: AccountType.supplier,
    accountId: query.partyId,
    from: query.from,
    to: query.to,
  );
});

// ----------------------------------------------------------------- dashboard

/// Kind of document behind a dashboard activity row.
enum ActivityKind { sale, purchase, paymentIn, paymentOut, expense, income }

/// One row in the dashboard "recent activity" list.
class ActivityItem {
  final ActivityKind kind;
  final DateTime date;

  /// Invoice / document number when there is one (sales, purchases).
  final String reference;

  /// Database id of the underlying document (sale/purchase invoice).
  final int? refId;
  final String? subtitle;
  final int paisa;
  final bool positive;
  const ActivityItem({
    required this.kind,
    required this.date,
    this.reference = '',
    this.refId,
    this.subtitle,
    required this.paisa,
    required this.positive,
  });
}

/// One cash/bank account with its live balance.
class AccountBalance {
  final CashAccount account;
  final int balancePaisa;
  const AccountBalance({required this.account, required this.balancePaisa});
}

/// Everything the dashboard needs, fetched in parallel.
class DashboardData {
  final int totalReceivablePaisa;
  final int totalPayablePaisa;
  final DailySummary today;
  final MonthlySummary month;
  final List<AccountBalance> accounts;
  final List<Product> lowStock;
  final Map<int, String> unitSymbols;
  final List<ActivityItem> recent;
  const DashboardData({
    required this.totalReceivablePaisa,
    required this.totalPayablePaisa,
    required this.today,
    required this.month,
    required this.accounts,
    required this.lowStock,
    required this.unitSymbols,
    required this.recent,
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final accounting = await ref.watch(accountingServiceProvider.future);
  final cashRepo = await ref.watch(cashAccountRepositoryProvider.future);
  final productRepo = await ref.watch(productRepositoryProvider.future);
  final unitRepo = await ref.watch(unitRepositoryProvider.future);
  final salesRepo = await ref.watch(salesRepositoryProvider.future);
  final purchaseRepo = await ref.watch(purchaseRepositoryProvider.future);
  final paymentRepo = await ref.watch(paymentRepositoryProvider.future);
  final expenseRepo = await ref.watch(expenseRepositoryProvider.future);
  final incomeRepo = await ref.watch(incomeRepositoryProvider.future);
  final customerRepo = await ref.watch(customerRepositoryProvider.future);
  final supplierRepo = await ref.watch(supplierRepositoryProvider.future);

  final now = DateTime.now();
  final results = await Future.wait([
    accounting.receivables(),
    accounting.payables(),
    accounting.dailySummary(now),
    accounting.monthlySummary(now.year, now.month),
    cashRepo.getAll(),
    productRepo.lowStock(limit: 6),
    unitRepo.getAll(),
    salesRepo.list(limit: 8),
    purchaseRepo.list(limit: 8),
    paymentRepo.list(limit: 10),
    expenseRepo.list(limit: 8),
    incomeRepo.list(limit: 8),
  ]);

  final receivables = results[0] as List<Customer>;
  final payables = results[1] as List<Supplier>;
  final accounts = results[4] as List<CashAccount>;
  final units = results[6] as List<Unit>;
  final unitSymbols = {for (final u in units) u.id!: u.symbol};

  // Live cash/bank balances from the ledger (the authority).
  final balances = await Future.wait(
    accounts.map((a) => accounting.getAccountBalancePaisa(a.id!)),
  );
  final accountBalances = [
    for (var i = 0; i < accounts.length; i++)
      AccountBalance(account: accounts[i], balancePaisa: balances[i]),
  ];

  // Merge recent documents into one chronological feed.
  final sales = results[7] as List<SalesInvoice>;
  final purchases = results[8] as List<PurchaseInvoice>;
  final payments = results[9] as List<Payment>;
  final expenses = results[10] as List<ExpenseEntry>;
  final incomes = results[11] as List<IncomeEntry>;

  final partyNames = <String, String>{};
  Future<String?> partyName(PartyType type, int id) async {
    final key = '${type.dbValue}:$id';
    if (partyNames.containsKey(key)) return partyNames[key];
    final name = type == PartyType.customer
        ? (await customerRepo.getById(id))?.name
        : (await supplierRepo.getById(id))?.name;
    if (name != null) partyNames[key] = name;
    return name;
  }

  final items = <ActivityItem>[];
  for (final s in sales) {
    items.add(ActivityItem(
      kind: ActivityKind.sale,
      date: s.date,
      reference: s.invoiceNo,
      refId: s.id,
      subtitle: await partyName(PartyType.customer, s.customerId),
      paisa: s.totalPaisa,
      positive: true,
    ));
  }
  for (final p in purchases) {
    items.add(ActivityItem(
      kind: ActivityKind.purchase,
      date: p.date,
      reference: p.invoiceNo,
      refId: p.id,
      subtitle: await partyName(PartyType.supplier, p.supplierId),
      paisa: p.totalPaisa,
      positive: false,
    ));
  }
  for (final p in payments) {
    final received = p.direction == PaymentDirection.received;
    items.add(ActivityItem(
      kind: received ? ActivityKind.paymentIn : ActivityKind.paymentOut,
      date: p.date,
      subtitle: await partyName(p.partyType, p.partyId) ?? p.notes,
      paisa: p.amountPaisa,
      positive: received,
    ));
  }
  for (final e in expenses) {
    items.add(ActivityItem(
      kind: ActivityKind.expense,
      date: e.date,
      subtitle: e.description,
      paisa: e.amountPaisa,
      positive: false,
    ));
  }
  for (final i in incomes) {
    items.add(ActivityItem(
      kind: ActivityKind.income,
      date: i.date,
      subtitle: i.description ?? i.category,
      paisa: i.amountPaisa,
      positive: true,
    ));
  }
  items.sort((a, b) => b.date.compareTo(a.date));

  return DashboardData(
    totalReceivablePaisa: receivables.fold(0, (sum, c) => sum + c.balancePaisa),
    totalPayablePaisa: payables.fold(0, (sum, s) => sum + s.balancePaisa),
    today: results[2] as DailySummary,
    month: results[3] as MonthlySummary,
    accounts: accountBalances,
    lowStock: results[5] as List<Product>,
    unitSymbols: unitSymbols,
    recent: items.take(8).toList(),
  );
});
