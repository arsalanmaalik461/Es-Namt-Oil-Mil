import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';
import '../models/ledger_entry.dart';
import '../models/product.dart';
import '../repositories/repo_utils.dart' as repo;
import '../services/accounting_service.dart';
import '../utils/time.dart';

/// Totals for a set of invoices in a period.
class PeriodTotals {
  final int count;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int totalPaisa;
  final int paidPaisa;
  const PeriodTotals({
    required this.count,
    required this.subtotalPaisa,
    required this.discountPaisa,
    required this.taxPaisa,
    required this.totalPaisa,
    required this.paidPaisa,
  });

  int get duePaisa => totalPaisa - paidPaisa;
}

/// Expense totals grouped by category.
class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final int totalPaisa;
  final int count;
  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.totalPaisa,
    required this.count,
  });
}

/// Profit & loss for a period, derived from the ledger (single authority).
class ProfitLoss {
  final int incomePaisa;
  final int expensePaisa;
  const ProfitLoss({required this.incomePaisa, required this.expensePaisa});

  int get netPaisa => incomePaisa - expensePaisa;
}

/// Read-only aggregate queries for reports.
///
/// Balance math (running balances, statements) is delegated to
/// [AccountingService]; this class only does SUM/COUNT aggregations over
/// document tables plus the ledger-based P&L.
class ReportRepository {
  ReportRepository(this._db, this._accounting);
  final DatabaseExecutor _db;
  final AccountingService _accounting;

  static const _postedInvoiceWhere =
      "status IN ('unpaid','partial','paid','returned')";

  // ------------------------------------------------------------- statements

  /// Customer statement with running balance (receivable view).
  Future<LedgerStatement> customerLedger(
    int customerId, {
    DateTime? from,
    DateTime? to,
  }) {
    return _accounting.ledgerWithRunningBalance(
      accountType: AccountType.customer,
      accountId: customerId,
      from: from,
      to: to,
    );
  }

  /// Supplier statement with running balance (payable view).
  Future<LedgerStatement> supplierLedger(
    int supplierId, {
    DateTime? from,
    DateTime? to,
  }) {
    return _accounting.ledgerWithRunningBalance(
      accountType: AccountType.supplier,
      accountId: supplierId,
      from: from,
      to: to,
    );
  }

  /// Cash/bank book with running balance.
  Future<LedgerStatement> cashBook(
    int accountId, {
    DateTime? from,
    DateTime? to,
  }) {
    return repo.guard('ledger_entries', () async {
      final rows = await _db.query('cash_accounts',
          columns: ['type'], where: 'id = ?', whereArgs: [accountId], limit: 1);
      if (rows.isEmpty) {
        throw ValidationException('error.accountNotFound', {'id': accountId});
      }
      final type = (rows.first['type'] as String?) == 'bank'
          ? AccountType.bank
          : AccountType.cash;
      return _accounting.ledgerWithRunningBalance(
        accountType: type,
        accountId: accountId,
        from: from,
        to: to,
      );
    });
  }

  // ---------------------------------------------------------------- summaries

  Future<PeriodTotals> _invoiceTotals(String table, int start, int end) {
    return repo.guard(table, () async {
      final rows = await _db.rawQuery(
        'SELECT COUNT(*) AS c, '
        'COALESCE(SUM(subtotal_paisa), 0) AS sub, '
        'COALESCE(SUM(discount_paisa), 0) AS disc, '
        'COALESCE(SUM(tax_paisa), 0) AS tax, '
        'COALESCE(SUM(total_paisa), 0) AS tot, '
        'COALESCE(SUM(paid_paisa), 0) AS paid '
        'FROM $table WHERE date >= ? AND date < ? AND $_postedInvoiceWhere',
        [start, end],
      );
      final r = rows.first;
      return PeriodTotals(
        count: (r['c'] as int?) ?? 0,
        subtotalPaisa: (r['sub'] as int?) ?? 0,
        discountPaisa: (r['disc'] as int?) ?? 0,
        taxPaisa: (r['tax'] as int?) ?? 0,
        totalPaisa: (r['tot'] as int?) ?? 0,
        paidPaisa: (r['paid'] as int?) ?? 0,
      );
    });
  }

  /// Posted sales totals in [from] (inclusive) .. [to] (exclusive).
  Future<PeriodTotals> salesSummary(DateTime from, DateTime to) {
    return _invoiceTotals(
        'sales_invoices', toEpochMillis(from), toEpochMillis(to));
  }

  /// Posted purchase totals in [from] (inclusive) .. [to] (exclusive).
  Future<PeriodTotals> purchaseSummary(DateTime from, DateTime to) {
    return _invoiceTotals(
        'purchase_invoices', toEpochMillis(from), toEpochMillis(to));
  }

  /// Expenses grouped by category in the period.
  Future<List<CategoryTotal>> expensesByCategory(DateTime from, DateTime to) {
    return repo.guard('expenses', () async {
      final rows = await _db.rawQuery(
        'SELECT c.id AS id, c.name AS name, COUNT(*) AS cnt, '
        'COALESCE(SUM(e.amount_paisa), 0) AS total '
        'FROM expenses e JOIN expense_categories c ON c.id = e.category_id '
        'WHERE e.date >= ? AND e.date < ? '
        'GROUP BY c.id, c.name ORDER BY total DESC',
        [toEpochMillis(from), toEpochMillis(to)],
      );
      return rows
          .map((r) => CategoryTotal(
                categoryId: (r['id'] as int?) ?? 0,
                categoryName: (r['name'] as String?) ?? '',
                totalPaisa: (r['total'] as int?) ?? 0,
                count: (r['cnt'] as int?) ?? 0,
              ))
          .toList();
    });
  }

  /// Other (non-invoice) income in the period.
  Future<int> otherIncomeTotal(DateTime from, DateTime to) {
    return repo.guard('income_entries', () async {
      final rows = await _db.rawQuery(
        'SELECT COALESCE(SUM(amount_paisa), 0) AS s FROM income_entries '
        'WHERE date >= ? AND date < ?',
        [toEpochMillis(from), toEpochMillis(to)],
      );
      return (rows.first['s'] as int?) ?? 0;
    });
  }

  /// Profit & loss from the ledger (the single authority):
  /// income = Σ(credit) − Σ(debit) on income accounts;
  /// expense = Σ(debit) − Σ(credit) on expense accounts.
  /// This nets sales against sales returns and purchases against purchase
  /// returns automatically.
  Future<ProfitLoss> profitLoss(DateTime from, DateTime to) {
    return repo.guard('ledger_entries', () async {
      final start = toEpochMillis(from);
      final end = toEpochMillis(to);
      Future<int> net(String accountType, bool incomeSide) async {
        final rows = await _db.rawQuery(
          'SELECT COALESCE(SUM(credit_paisa), 0) AS c, '
          'COALESCE(SUM(debit_paisa), 0) AS d '
          'FROM ledger_entries WHERE account_type = ? AND date >= ? AND date < ?',
          [accountType, start, end],
        );
        final c = (rows.first['c'] as int?) ?? 0;
        final d = (rows.first['d'] as num?)?.toInt() ?? 0;
        return incomeSide ? c - d : d - c;
      }

      return ProfitLoss(
        incomePaisa: await net('income', true),
        expensePaisa: await net('expense', false),
      );
    });
  }

  // ------------------------------------------------------------------- stock

  /// All products with their cached stock (for the stock report).
  Future<List<Product>> stockReport({bool includeArchived = false}) {
    return repo.guard('products', () async {
      final rows = await _db.query(
        'products',
        where: includeArchived ? null : 'is_archived = 0',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map(Product.fromMap).toList();
    });
  }

  /// Products at or below reorder level.
  Future<List<Product>> lowStockReport() {
    return repo.guard('products', () async {
      final rows = await _db.query(
        'products',
        where: 'is_archived = 0 AND stock_qty <= reorder_level_qty',
        orderBy: 'stock_qty ASC',
      );
      return rows.map(Product.fromMap).toList();
    });
  }
}
