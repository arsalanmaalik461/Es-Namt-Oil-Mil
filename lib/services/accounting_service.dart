import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';
import '../db/audit_log.dart';
import '../db/database.dart';
import '../models/account_transfer.dart';
import '../models/cash_account.dart';
import '../models/customer.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/inventory_movement.dart';
import '../models/ledger_entry.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/production_batch.dart';
import '../models/purchase_invoice.dart';
import '../models/purchase_return.dart';
import '../models/sales_invoice.dart';
import '../models/sales_return.dart';
import '../models/supplier.dart';
import '../repositories/cash_account_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/document_number_service.dart';
import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/production_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/repo_utils.dart' as repo;
import '../repositories/return_repository.dart';
import '../repositories/sales_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/unit_repository.dart';
import '../utils/keys.dart';
import '../utils/money.dart';
import '../utils/time.dart';

// ===========================================================================
// INPUT / RESULT TYPES (pure Dart)
// ===========================================================================

/// One line of a new sale.
class SaleLineInput {
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final double discountPercent;
  const SaleLineInput({
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    this.discountPercent = 0,
  });
}

/// One line of a new purchase.
class PurchaseLineInput {
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final double discountPercent;
  const PurchaseLineInput({
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    this.discountPercent = 0,
  });
}

/// One line of a sales/purchase return.
class ReturnLineInput {
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  const ReturnLineInput({
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
  });
}

/// Allocation of a payment to one invoice.
class PaymentAllocationInput {
  final int invoiceId;
  final int amountPaisa;
  const PaymentAllocationInput({
    required this.invoiceId,
    required this.amountPaisa,
  });
}

/// Raw material consumed by a production batch.
class BatchInputInput {
  final int productId;
  final double qty;
  final int unitId;
  const BatchInputInput({
    required this.productId,
    required this.qty,
    required this.unitId,
  });
}

/// One output of a production batch.
class BatchOutputInput {
  final int productId;
  final double qty;
  final int unitId;
  final OutputType outputType;
  const BatchOutputInput({
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.outputType,
  });
}

/// One cached-vs-ledger balance mismatch found by [verifyBalances].
class BalanceMismatch {
  final AccountType accountType;
  final int accountId;
  final String? accountName;
  final int cachedPaisa;
  final int ledgerPaisa;
  const BalanceMismatch({
    required this.accountType,
    required this.accountId,
    this.accountName,
    required this.cachedPaisa,
    required this.ledgerPaisa,
  });
}

/// Totals for one business day (from document tables, not the ledger).
class DailySummary {
  final DateTime date;
  final int salesPaisa;
  final int purchasesPaisa;
  final int receivedPaisa;
  final int paidPaisa;
  final int expensesPaisa;
  final int incomePaisa;
  const DailySummary({
    required this.date,
    required this.salesPaisa,
    required this.purchasesPaisa,
    required this.receivedPaisa,
    required this.paidPaisa,
    required this.expensesPaisa,
    required this.incomePaisa,
  });
}

/// Totals for one calendar month.
class MonthlySummary {
  final int year;
  final int month;
  final int salesPaisa;
  final int purchasesPaisa;
  final int receivedPaisa;
  final int paidPaisa;
  final int expensesPaisa;
  final int incomePaisa;
  final int salesCount;
  final int purchaseCount;
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.salesPaisa,
    required this.purchasesPaisa,
    required this.receivedPaisa,
    required this.paidPaisa,
    required this.expensesPaisa,
    required this.incomePaisa,
    required this.salesCount,
    required this.purchaseCount,
  });
}

/// One ledger entry with its running balance after applying the entry.
class LedgerLine {
  final LedgerEntry entry;
  final int runningBalancePaisa;
  const LedgerLine({required this.entry, required this.runningBalancePaisa});
}

/// A full account statement: opening balance, running-balance lines, closing.
class LedgerStatement {
  final AccountType accountType;
  final int accountId;
  final int openingBalancePaisa;
  final List<LedgerLine> lines;
  const LedgerStatement({
    required this.accountType,
    required this.accountId,
    required this.openingBalancePaisa,
    required this.lines,
  });

  int get closingBalancePaisa =>
      lines.isEmpty ? openingBalancePaisa : lines.last.runningBalancePaisa;
}

// ===========================================================================
// ACCOUNTING SERVICE — THE ledger authority
// ===========================================================================
//
// UI RULE (read this before calling anything else):
//   Anything that affects a balance — sales, purchases, payments, expenses,
//   income, transfers, production, returns, adjustments, reversals — MUST go
//   through AccountingService. Repositories are CRUD-only and never compute
//   balances. Screens must never compute balances ad hoc either; call the
//   getters below.
//
// BALANCE SEMANTICS (single source of truth, enforced here):
//   customer balance > 0  => customer OWES the business (receivable)
//   customer balance < 0  => customer paid in advance
//   supplier balance > 0  => business OWES the supplier (payable)
//   supplier balance < 0  => business paid the supplier in advance
//   cash/bank balance     => on-hand money (always >= 0 in practice)
//
// Every posting runs in ONE database transaction: document rows + line items
// + inventory movements + stock/avg-cost caches + ledger entries + balance
// caches are written atomically. Any failure rolls everything back and the
// method throws — postings never half-succeed.
class AccountingService {
  AccountingService(this._helper);
  final DatabaseHelper _helper;

  /// Canonical income account id for sales (no income_accounts table;
  /// accountId 0 = "Sales revenue"). Documented, not magic.
  static const int salesIncomeAccountId = 0;

  /// Canonical expense account id for purchases (accountId 0, category
  /// 'purchase' / 'purchase_returns').
  static const int purchaseExpenseAccountId = 0;

  // ------------------------------------------------------------------ math
  // The ONLY place balance formulas live.

  /// Signed effect of one entry on its account's balance, in paisa.
  static int signedEffect(AccountType type, int debitPaisa, int creditPaisa) {
    switch (type) {
      case AccountType.customer:
        return debitPaisa - creditPaisa;
      case AccountType.supplier:
        return creditPaisa - debitPaisa;
      case AccountType.cash:
      case AccountType.bank:
        return debitPaisa - creditPaisa;
      case AccountType.expense:
      case AccountType.income:
        return 0; // no cached balance for P&L accounts
    }
  }

  Future<int> _ledgerBalance(
      DatabaseExecutor db, AccountType type, int accountId) {
    return repo.guard('ledger_entries', () async {
      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(debit_paisa), 0) AS d, '
        'COALESCE(SUM(credit_paisa), 0) AS c '
        'FROM ledger_entries WHERE account_type = ? AND account_id = ?',
        [type.dbValue, accountId],
      );
      final d = ((rows.first['d'] as num?) ?? 0).toInt();
      final c = ((rows.first['c'] as num?) ?? 0).toInt();
      return signedEffect(type, d, c);
    });
  }

  /// Customer balance from the ledger. > 0 = customer owes the business.
  Future<int> getCustomerBalancePaisa(int customerId) async {
    final db = await _helper.database;
    return _ledgerBalance(db, AccountType.customer, customerId);
  }

  /// Supplier balance from the ledger. > 0 = business owes the supplier.
  Future<int> getSupplierBalancePaisa(int supplierId) async {
    final db = await _helper.database;
    return _ledgerBalance(db, AccountType.supplier, supplierId);
  }

  /// Cash/bank account balance from the ledger.
  Future<int> getAccountBalancePaisa(int accountId) async {
    final db = await _helper.database;
    final account = await CashAccountRepository(db).getById(accountId);
    if (account == null) {
      throw ValidationException('error.accountNotFound', {'id': accountId});
    }
    final type = account.type == CashAccountType.cash
        ? AccountType.cash
        : AccountType.bank;
    return _ledgerBalance(db, type, accountId);
  }

  /// Cached stock of a product in its base unit.
  Future<double> getProductStockBase(int productId) async {
    final db = await _helper.database;
    final product = await ProductRepository(db).getById(productId);
    if (product == null) {
      throw ValidationException('error.productNotFound', {'id': productId});
    }
    return product.stockQty;
  }

  /// Quantity conversion (delegates to [UnitRepository]).
  Future<double> convertQty(double qty, int fromUnitId, int toUnitId) async {
    final db = await _helper.database;
    return UnitRepository(db).convertQty(qty, fromUnitId, toUnitId);
  }

  // ---------------------------------------------------------- journal core

  /// Applies one entry's signed effect to the cached balance row.
  Future<void> _applyCacheDelta(
    Transaction txn,
    AccountType type,
    int accountId,
    int debitPaisa,
    int creditPaisa,
  ) async {
    final delta = signedEffect(type, debitPaisa, creditPaisa);
    if (delta == 0) return;
    switch (type) {
      case AccountType.customer:
        await CustomerRepository(txn).adjustBalance(txn, accountId, delta);
      case AccountType.supplier:
        await SupplierRepository(txn).adjustBalance(txn, accountId, delta);
      case AccountType.cash:
      case AccountType.bank:
        await CashAccountRepository(txn).adjustBalance(txn, accountId, delta);
      case AccountType.expense:
      case AccountType.income:
        break;
    }
  }

  Future<int> _insertLedgerEntry(
    Transaction txn,
    LedgerEntry entry,
  ) {
    return repo.guard('ledger_entries', () async {
      final id = await txn.insert(
        'ledger_entries',
        entry.toMap()
          ..remove('id')
          ..['created_at'] = nowMillis(),
      );
      await _applyCacheDelta(txn, entry.accountType, entry.accountId,
          entry.debitPaisa, entry.creditPaisa);
      return id;
    });
  }

  /// Writes a balanced journal: inserts entries (one `LE-…` number each),
  /// updates balance caches, writes one audit row. Throws
  /// [ValidationException] when the journal does not balance.
  Future<String> _postJournal(
    Transaction txn, {
    required DateTime date,
    required List<_JournalLine> lines,
    String? journalKey,
    String auditAction = 'post',
    String auditEntity = 'ledger_entries',
  }) async {
    if (lines.isEmpty) {
      throw ValidationException('error.emptyJournal');
    }
    var totalDebit = 0;
    var totalCredit = 0;
    for (final line in lines) {
      final valid = (line.debitPaisa > 0 && line.creditPaisa == 0) ||
          (line.creditPaisa > 0 && line.debitPaisa == 0);
      if (!valid) {
        throw ValidationException('error.invalidJournalLine');
      }
      totalDebit += line.debitPaisa;
      totalCredit += line.creditPaisa;
    }
    if (totalDebit != totalCredit) {
      throw ValidationException('error.unbalancedJournal',
          {'debit': totalDebit, 'credit': totalCredit});
    }
    final key = journalKey ?? newJournalKey();
    final docs = DocumentNumberService();
    for (final line in lines) {
      final entryNo = await docs.next(txn, DocumentNumberService.ledgerEntry);
      await _insertLedgerEntry(
        txn,
        LedgerEntry(
          entryNo: entryNo,
          journalKey: key,
          date: date,
          accountType: line.accountType,
          accountId: line.accountId,
          debitPaisa: line.debitPaisa,
          creditPaisa: line.creditPaisa,
          category: line.category,
          referenceType: line.referenceType,
          referenceId: line.referenceId,
          description: line.description,
        ),
      );
    }
    await AuditLog.log(txn,
        action: auditAction, entity: auditEntity, entityId: key);
    return key;
  }

  Future<LedgerEntry?> _getLedgerEntry(DatabaseExecutor db, int id) async {
    final rows = await db.query('ledger_entries',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return LedgerEntry.fromMap(rows.first);
  }

  Future<List<LedgerEntry>> _getJournalEntries(
      DatabaseExecutor db, String journalKey) async {
    final rows = await db.query('ledger_entries',
        where: 'journal_key = ?', whereArgs: [journalKey], orderBy: 'id ASC');
    return rows.map(LedgerEntry.fromMap).toList();
  }

  // ------------------------------------------------------------------ sales

  Future<SalesInvoice> _postSaleInTxn(
    Transaction txn, {
    required int customerId,
    required DateTime date,
    required List<SaleLineInput> lines,
    num discountPercent = 0,
    int? discountPaisaOverride,
    int taxPaisa = 0,
    String? notes,
    String? idempotencyKey,
    String? invoiceNoOverride,
  }) async {
    final customers = CustomerRepository(txn);
    final products = ProductRepository(txn);
    final units = UnitRepository(txn);
    final sales = SalesRepository(txn);
    final inventory = InventoryRepository(txn);
    final docs = DocumentNumberService();

    if (lines.isEmpty) throw ValidationException('error.emptyInvoice');
    if (taxPaisa < 0) throw ValidationException('error.negativeTax');

    final customer = await customers.getById(customerId);
    if (customer == null) {
      throw ValidationException('error.customerNotFound', {'id': customerId});
    }
    if (customer.isArchived) {
      throw ValidationException(
          'error.customerArchived', {'name': customer.name});
    }

    // Validate lines, check stock, compute totals.
    final calcs = <_SaleLineCalc>[];
    var subtotal = 0;
    for (final line in lines) {
      if (line.qty <= 0) {
        throw ValidationException('error.invalidQty', {'qty': line.qty});
      }
      if (line.unitPricePaisa < 0) {
        throw ValidationException('error.negativePrice');
      }
      final product = await products.getById(line.productId);
      if (product == null) {
        throw ValidationException(
            'error.productNotFound', {'id': line.productId});
      }
      if (product.isArchived) {
        throw ValidationException(
            'error.productArchived', {'name': product.name});
      }
      final unit = await units.getById(line.unitId);
      if (unit == null) {
        throw ValidationException('error.unitNotFound', {'id': line.unitId});
      }
      final qtyBase =
          await units.convertQty(line.qty, line.unitId, product.baseUnitId);
      if (product.stockQty + 1e-9 < qtyBase) {
        throw ValidationException('error.insufficientStock', {
          'product': product.name,
          'available': product.stockQty,
          'needed': qtyBase,
        });
      }
      final lineTotal = lineTotalPaisa(
        unitPricePaisa: line.unitPricePaisa,
        qty: line.qty,
        discountPercent: line.discountPercent,
      );
      subtotal += lineTotal;
      calcs.add(_SaleLineCalc(
          input: line,
          product: product,
          qtyBase: qtyBase,
          lineTotalPaisa: lineTotal));
    }
    final discountPaisa =
        discountPaisaOverride ?? percentOf(subtotal, discountPercent);
    final total = subtotal - discountPaisa + taxPaisa;
    if (total < 0) throw ValidationException('error.negativeTotal');

    final invoiceNo = invoiceNoOverride ??
        await docs.next(txn, DocumentNumberService.salesInvoice);
    final journalKey = newJournalKey();

    var invoice = SalesInvoice(
      invoiceNo: invoiceNo,
      customerId: customerId,
      date: date,
      status: total == 0 ? InvoiceStatus.paid : InvoiceStatus.unpaid,
      subtotalPaisa: subtotal,
      discountPaisa: discountPaisa,
      taxPaisa: taxPaisa,
      totalPaisa: total,
      paidPaisa: 0,
      idempotencyKey: idempotencyKey,
      notes: notes,
    );
    final items = calcs
        .map((c) => SalesInvoiceItem(
              productId: c.input.productId,
              qty: c.input.qty,
              unitId: c.input.unitId,
              unitPricePaisa: c.input.unitPricePaisa,
              discountPercent: c.input.discountPercent,
              lineTotalPaisa: c.lineTotalPaisa,
            ))
        .toList();
    invoice = await sales.insertInvoice(txn, invoice, items);

    // Stock out.
    for (final c in calcs) {
      await inventory.insertMovement(InventoryMovement(
        date: date,
        productId: c.input.productId,
        qtyChange: -c.input.qty,
        qtyChangeBase: -c.qtyBase,
        unitId: c.input.unitId,
        movementType: MovementTypes.sale,
        referenceType: ReferenceTypes.sale,
        referenceId: invoice.id,
        notes: 'Sale $invoiceNo',
      ));
      await products.adjustStockAndCost(
          txn, c.input.productId, -c.qtyBase, null);
    }

    // Ledger: debit customer / credit income(sales). Skip when total is 0
    // (nothing owed, nothing earned).
    if (total > 0) {
      await _postJournal(
        txn,
        date: date,
        journalKey: journalKey,
        auditEntity: 'sales_invoices',
        lines: [
          _JournalLine(
            accountType: AccountType.customer,
            accountId: customerId,
            debitPaisa: total,
            category: 'sales',
            referenceType: ReferenceTypes.sale,
            referenceId: invoice.id,
            description: 'Sale $invoiceNo to ${customer.name}',
          ),
          _JournalLine(
            accountType: AccountType.income,
            accountId: salesIncomeAccountId,
            creditPaisa: total,
            category: 'sales',
            referenceType: ReferenceTypes.sale,
            referenceId: invoice.id,
            description: 'Sale $invoiceNo',
          ),
        ],
      );
    }
    return invoice;
  }

  /// Posts a sales invoice: validates stock, writes invoice + items +
  /// inventory movements + ledger journal + balance caches, in ONE transaction.
  ///
  /// Idempotent: when [idempotencyKey] was already posted, the existing
  /// invoice is returned and nothing is posted again.
  Future<SalesInvoice> postSale({
    required int customerId,
    required DateTime date,
    required List<SaleLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? notes,
    String? idempotencyKey,
  }) {
    return repo.guard('sales_invoices', () async {
      if (idempotencyKey != null) {
        final existing = await SalesRepository(await _helper.database)
            .findByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing =
              await SalesRepository(txn).findByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        return _postSaleInTxn(
          txn,
          customerId: customerId,
          date: date,
          lines: lines,
          discountPercent: discountPercent,
          taxPaisa: taxPaisa,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
      });
    });
  }

  /// Reserves an invoice number and stores an editable draft (no ledger,
  /// stock or balance effects). Post it later with [postDraftSale].
  Future<SalesInvoice> createSalesDraft({
    required int customerId,
    required DateTime date,
    required List<SaleLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? notes,
  }) {
    return repo.guard('sales_invoices', () async {
      if (lines.isEmpty) throw ValidationException('error.emptyInvoice');
      final db = await _helper.database;
      final units = UnitRepository(db);
      var subtotal = 0;
      final items = <SalesInvoiceItem>[];
      for (final line in lines) {
        if (line.qty <= 0) {
          throw ValidationException('error.invalidQty', {'qty': line.qty});
        }
        final lineTotal = lineTotalPaisa(
          unitPricePaisa: line.unitPricePaisa,
          qty: line.qty,
          discountPercent: line.discountPercent,
        );
        subtotal += lineTotal;
        items.add(SalesInvoiceItem(
          productId: line.productId,
          qty: line.qty,
          unitId: line.unitId,
          unitPricePaisa: line.unitPricePaisa,
          discountPercent: line.discountPercent,
          lineTotalPaisa: lineTotal,
        ));
      }
      // Validate units exist (products are validated at posting time).
      for (final line in lines) {
        final unit = await units.getById(line.unitId);
        if (unit == null) {
          throw ValidationException('error.unitNotFound', {'id': line.unitId});
        }
      }
      final discountPaisa = percentOf(subtotal, discountPercent);
      final total = subtotal - discountPaisa + taxPaisa;
      if (total < 0) throw ValidationException('error.negativeTotal');
      return _helper.transaction((txn) async {
        final invoiceNo = await DocumentNumberService()
            .next(txn, DocumentNumberService.salesInvoice);
        final id = await SalesRepository(txn).createDraft(
          SalesInvoice(
            invoiceNo: invoiceNo,
            customerId: customerId,
            date: date,
            subtotalPaisa: subtotal,
            discountPaisa: discountPaisa,
            taxPaisa: taxPaisa,
            totalPaisa: total,
            notes: notes,
          ),
          items,
        );
        final created = await SalesRepository(txn).getById(id);
        return created!;
      });
    });
  }

  /// Posts a previously created draft. The draft row is deleted and replaced
  /// by the posted invoice reusing the draft's invoice number.
  Future<SalesInvoice> postDraftSale(int draftId) {
    return repo.guard('sales_invoices', () async {
      final db = await _helper.database;
      final sales = SalesRepository(db);
      final draft = await sales.getById(draftId);
      if (draft == null) {
        throw ValidationException('error.invoiceNotFound', {'id': draftId});
      }
      if (draft.status != InvoiceStatus.draft) {
        throw ValidationException(
            'error.notADraft', {'invoiceNo': draft.invoiceNo});
      }
      final items = await sales.getItems(draftId);
      if (items.isEmpty) throw ValidationException('error.emptyInvoice');
      final lines = items
          .map((i) => SaleLineInput(
                productId: i.productId,
                qty: i.qty,
                unitId: i.unitId,
                unitPricePaisa: i.unitPricePaisa,
                discountPercent: i.discountPercent,
              ))
          .toList();
      return _helper.transaction((txn) async {
        // Remove the draft (items cascade); the posted invoice reuses its number.
        await txn.delete('sales_invoices',
            where: "id = ? AND status = 'draft'", whereArgs: [draftId]);
        return _postSaleInTxn(
          txn,
          customerId: draft.customerId,
          date: draft.date,
          lines: lines,
          discountPaisaOverride: draft.discountPaisa,
          taxPaisa: draft.taxPaisa,
          notes: draft.notes,
          invoiceNoOverride: draft.invoiceNo,
        );
      });
    });
  }

  // --------------------------------------------------------------- purchases

  Future<PurchaseInvoice> _postPurchaseInTxn(
    Transaction txn, {
    required int supplierId,
    required DateTime date,
    required List<PurchaseLineInput> lines,
    num discountPercent = 0,
    int? discountPaisaOverride,
    int taxPaisa = 0,
    String? notes,
    String? idempotencyKey,
    String? invoiceNoOverride,
  }) async {
    final suppliers = SupplierRepository(txn);
    final products = ProductRepository(txn);
    final units = UnitRepository(txn);
    final purchases = PurchaseRepository(txn);
    final inventory = InventoryRepository(txn);
    final docs = DocumentNumberService();

    if (lines.isEmpty) throw ValidationException('error.emptyInvoice');
    if (taxPaisa < 0) throw ValidationException('error.negativeTax');

    final supplier = await suppliers.getById(supplierId);
    if (supplier == null) {
      throw ValidationException('error.supplierNotFound', {'id': supplierId});
    }
    if (supplier.isArchived) {
      throw ValidationException(
          'error.supplierArchived', {'name': supplier.name});
    }

    final calcs = <_PurchaseLineCalc>[];
    var subtotal = 0;
    for (final line in lines) {
      if (line.qty <= 0) {
        throw ValidationException('error.invalidQty', {'qty': line.qty});
      }
      if (line.unitPricePaisa < 0) {
        throw ValidationException('error.negativePrice');
      }
      final product = await products.getById(line.productId);
      if (product == null) {
        throw ValidationException(
            'error.productNotFound', {'id': line.productId});
      }
      if (product.isArchived) {
        throw ValidationException(
            'error.productArchived', {'name': product.name});
      }
      final unit = await units.getById(line.unitId);
      if (unit == null) {
        throw ValidationException('error.unitNotFound', {'id': line.unitId});
      }
      final qtyBase =
          await units.convertQty(line.qty, line.unitId, product.baseUnitId);
      final lineTotal = lineTotalPaisa(
        unitPricePaisa: line.unitPricePaisa,
        qty: line.qty,
        discountPercent: line.discountPercent,
      );
      subtotal += lineTotal;
      calcs.add(_PurchaseLineCalc(
          input: line,
          product: product,
          qtyBase: qtyBase,
          lineTotalPaisa: lineTotal));
    }
    final discountPaisa =
        discountPaisaOverride ?? percentOf(subtotal, discountPercent);
    final total = subtotal - discountPaisa + taxPaisa;
    if (total < 0) throw ValidationException('error.negativeTotal');

    // Allocate the invoice-level discount across lines (pro-rata, half-up,
    // last line takes the remainder) so per-line stock cost stays exact.
    final costValues = _allocateProportionally(
        subtotal - discountPaisa, calcs.map((c) => c.lineTotalPaisa).toList());

    final invoiceNo = invoiceNoOverride ??
        await docs.next(txn, DocumentNumberService.purchaseInvoice);
    final journalKey = newJournalKey();

    var invoice = PurchaseInvoice(
      invoiceNo: invoiceNo,
      supplierId: supplierId,
      date: date,
      status: total == 0 ? InvoiceStatus.paid : InvoiceStatus.unpaid,
      subtotalPaisa: subtotal,
      discountPaisa: discountPaisa,
      taxPaisa: taxPaisa,
      totalPaisa: total,
      paidPaisa: 0,
      idempotencyKey: idempotencyKey,
      notes: notes,
    );
    final items = calcs
        .map((c) => PurchaseInvoiceItem(
              productId: c.input.productId,
              qty: c.input.qty,
              unitId: c.input.unitId,
              unitPricePaisa: c.input.unitPricePaisa,
              discountPercent: c.input.discountPercent,
              lineTotalPaisa: c.lineTotalPaisa,
            ))
        .toList();
    invoice = await purchases.insertInvoice(txn, invoice, items);

    // Stock in + weighted-average cost update.
    // NOTE: the product is re-read per line — an earlier line of this same
    // invoice may already have changed the stock/average (multi-line
    // invoices for one product must compound, not restart from stale data).
    for (var i = 0; i < calcs.length; i++) {
      final c = calcs[i];
      await inventory.insertMovement(InventoryMovement(
        date: date,
        productId: c.input.productId,
        qtyChange: c.input.qty,
        qtyChangeBase: c.qtyBase,
        unitId: c.input.unitId,
        movementType: MovementTypes.purchase,
        referenceType: ReferenceTypes.purchase,
        referenceId: invoice.id,
        notes: 'Purchase $invoiceNo',
      ));
      final current = await products.getById(c.input.productId);
      final newAvg = weightedAverageCostPaisa(
        oldQtyBase: current?.stockQty ?? c.product.stockQty,
        oldAvgCostPaisa: current?.avgCostPaisa ?? c.product.avgCostPaisa,
        addedQtyBase: c.qtyBase,
        addedValuePaisa: costValues[i],
      );
      await products.adjustStockAndCost(
          txn, c.input.productId, c.qtyBase, newAvg);
    }

    // Ledger: debit expense(purchases) / credit supplier.
    if (total > 0) {
      await _postJournal(
        txn,
        date: date,
        journalKey: journalKey,
        auditEntity: 'purchase_invoices',
        lines: [
          _JournalLine(
            accountType: AccountType.expense,
            accountId: purchaseExpenseAccountId,
            debitPaisa: total,
            category: 'purchase',
            referenceType: ReferenceTypes.purchase,
            referenceId: invoice.id,
            description: 'Purchase $invoiceNo from ${supplier.name}',
          ),
          _JournalLine(
            accountType: AccountType.supplier,
            accountId: supplierId,
            creditPaisa: total,
            category: 'purchase',
            referenceType: ReferenceTypes.purchase,
            referenceId: invoice.id,
            description: 'Purchase $invoiceNo from ${supplier.name}',
          ),
        ],
      );
    }
    return invoice;
  }

  /// Posts a purchase invoice: stock in at weighted-average cost, supplier
  /// payable up, in ONE transaction. Idempotent via [idempotencyKey].
  Future<PurchaseInvoice> postPurchase({
    required int supplierId,
    required DateTime date,
    required List<PurchaseLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? notes,
    String? idempotencyKey,
  }) {
    return repo.guard('purchase_invoices', () async {
      if (idempotencyKey != null) {
        final existing = await PurchaseRepository(await _helper.database)
            .findByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing = await PurchaseRepository(txn)
              .findByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        return _postPurchaseInTxn(
          txn,
          supplierId: supplierId,
          date: date,
          lines: lines,
          discountPercent: discountPercent,
          taxPaisa: taxPaisa,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
      });
    });
  }

  /// Reserves an invoice number and stores an editable purchase draft.
  Future<PurchaseInvoice> createPurchaseDraft({
    required int supplierId,
    required DateTime date,
    required List<PurchaseLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? notes,
  }) {
    return repo.guard('purchase_invoices', () async {
      if (lines.isEmpty) throw ValidationException('error.emptyInvoice');
      final db = await _helper.database;
      final units = UnitRepository(db);
      var subtotal = 0;
      final items = <PurchaseInvoiceItem>[];
      for (final line in lines) {
        if (line.qty <= 0) {
          throw ValidationException('error.invalidQty', {'qty': line.qty});
        }
        final lineTotal = lineTotalPaisa(
          unitPricePaisa: line.unitPricePaisa,
          qty: line.qty,
          discountPercent: line.discountPercent,
        );
        subtotal += lineTotal;
        items.add(PurchaseInvoiceItem(
          productId: line.productId,
          qty: line.qty,
          unitId: line.unitId,
          unitPricePaisa: line.unitPricePaisa,
          discountPercent: line.discountPercent,
          lineTotalPaisa: lineTotal,
        ));
      }
      for (final line in lines) {
        final unit = await units.getById(line.unitId);
        if (unit == null) {
          throw ValidationException('error.unitNotFound', {'id': line.unitId});
        }
      }
      final discountPaisa = percentOf(subtotal, discountPercent);
      final total = subtotal - discountPaisa + taxPaisa;
      if (total < 0) throw ValidationException('error.negativeTotal');
      return _helper.transaction((txn) async {
        final invoiceNo = await DocumentNumberService()
            .next(txn, DocumentNumberService.purchaseInvoice);
        final id = await PurchaseRepository(txn).createDraft(
          PurchaseInvoice(
            invoiceNo: invoiceNo,
            supplierId: supplierId,
            date: date,
            subtotalPaisa: subtotal,
            discountPaisa: discountPaisa,
            taxPaisa: taxPaisa,
            totalPaisa: total,
            notes: notes,
          ),
          items,
        );
        return (await PurchaseRepository(txn).getById(id))!;
      });
    });
  }

  /// Posts a previously created purchase draft (draft row replaced, number reused).
  Future<PurchaseInvoice> postDraftPurchase(int draftId) {
    return repo.guard('purchase_invoices', () async {
      final db = await _helper.database;
      final purchases = PurchaseRepository(db);
      final draft = await purchases.getById(draftId);
      if (draft == null) {
        throw ValidationException('error.invoiceNotFound', {'id': draftId});
      }
      if (draft.status != InvoiceStatus.draft) {
        throw ValidationException(
            'error.notADraft', {'invoiceNo': draft.invoiceNo});
      }
      final items = await purchases.getItems(draftId);
      if (items.isEmpty) throw ValidationException('error.emptyInvoice');
      final lines = items
          .map((i) => PurchaseLineInput(
                productId: i.productId,
                qty: i.qty,
                unitId: i.unitId,
                unitPricePaisa: i.unitPricePaisa,
                discountPercent: i.discountPercent,
              ))
          .toList();
      return _helper.transaction((txn) async {
        await txn.delete('purchase_invoices',
            where: "id = ? AND status = 'draft'", whereArgs: [draftId]);
        return _postPurchaseInTxn(
          txn,
          supplierId: draft.supplierId,
          date: draft.date,
          lines: lines,
          discountPaisaOverride: draft.discountPaisa,
          taxPaisa: draft.taxPaisa,
          notes: draft.notes,
          invoiceNoOverride: draft.invoiceNo,
        );
      });
    });
  }

  // ---------------------------------------------------------------- payments

  Future<Payment> _postPaymentInTxn(
    Transaction txn, {
    required DateTime date,
    required PartyType partyType,
    required int partyId,
    required int amountPaisa,
    required PaymentDirection direction,
    required PaymentMethod method,
    required int accountId,
    required List<PaymentAllocationInput> allocations,
    required String invoiceType, // 'sale' | 'purchase'
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) async {
    final payments = PaymentRepository(txn);
    final accounts = CashAccountRepository(txn);

    if (amountPaisa <= 0) throw ValidationException('error.invalidAmount');

    final account = await accounts.getById(accountId);
    if (account == null) {
      throw ValidationException('error.accountNotFound', {'id': accountId});
    }
    if (!account.isActive) {
      throw ValidationException(
          'error.accountInactive', {'name': account.name});
    }
    final methodMatchesAccount = (method == PaymentMethod.cash) ==
        (account.type == CashAccountType.cash);
    if (!methodMatchesAccount) {
      throw ValidationException('error.methodAccountMismatch', {
        'method': method.dbValue,
        'account': account.name,
      });
    }
    final cashType = account.type == CashAccountType.cash
        ? AccountType.cash
        : AccountType.bank;

    final isCustomer = partyType == PartyType.customer;
    final String partyName;
    if (isCustomer) {
      final party = await CustomerRepository(txn).getById(partyId);
      if (party == null) {
        throw ValidationException('error.customerNotFound', {'id': partyId});
      }
      if (party.isArchived) {
        throw ValidationException(
            'error.customerArchived', {'name': party.name});
      }
      partyName = party.name;
    } else {
      final party = await SupplierRepository(txn).getById(partyId);
      if (party == null) {
        throw ValidationException('error.supplierNotFound', {'id': partyId});
      }
      if (party.isArchived) {
        throw ValidationException(
            'error.supplierArchived', {'name': party.name});
      }
      partyName = party.name;
    }

    // Validate allocations.
    var allocatedSum = 0;
    for (final a in allocations) {
      if (a.amountPaisa <= 0) throw ValidationException('error.invalidAmount');
      allocatedSum += a.amountPaisa;
      if (invoiceType == 'sale') {
        final inv = await SalesRepository(txn).getById(a.invoiceId);
        if (inv == null ||
            inv.customerId != partyId ||
            inv.status == InvoiceStatus.draft ||
            inv.status == InvoiceStatus.cancelled) {
          throw ValidationException(
              'error.invoiceNotFound', {'id': a.invoiceId});
        }
        final already =
            await payments.allocatedTotalForInvoice('sale', a.invoiceId);
        if (already + a.amountPaisa > inv.totalPaisa) {
          throw ValidationException(
              'error.overAllocatedInvoice', {'invoiceNo': inv.invoiceNo});
        }
      } else {
        final inv = await PurchaseRepository(txn).getById(a.invoiceId);
        if (inv == null ||
            inv.supplierId != partyId ||
            inv.status == InvoiceStatus.draft ||
            inv.status == InvoiceStatus.cancelled) {
          throw ValidationException(
              'error.invoiceNotFound', {'id': a.invoiceId});
        }
        final already =
            await payments.allocatedTotalForInvoice('purchase', a.invoiceId);
        if (already + a.amountPaisa > inv.totalPaisa) {
          throw ValidationException(
              'error.overAllocatedInvoice', {'invoiceNo': inv.invoiceNo});
        }
      }
    }
    if (allocatedSum > amountPaisa) {
      throw ValidationException('error.overAllocated',
          {'allocated': allocatedSum, 'amount': amountPaisa});
    }

    final journalKey = newJournalKey();
    var payment = Payment(
      date: date,
      partyType: partyType,
      partyId: partyId,
      amountPaisa: amountPaisa,
      direction: direction,
      method: method,
      accountId: accountId,
      reference: reference,
      idempotencyKey: idempotencyKey,
      notes: notes,
    );
    payment = await payments.insert(txn, payment);

    // Apply allocations to invoices.
    for (final a in allocations) {
      await payments.insertAllocation(
        txn,
        PaymentAllocation(
          paymentId: payment.id,
          invoiceType: invoiceType,
          invoiceId: a.invoiceId,
          amountPaisa: a.amountPaisa,
        ),
      );
      if (invoiceType == 'sale') {
        final sales = SalesRepository(txn);
        final inv = (await sales.getById(a.invoiceId))!;
        final newPaid = inv.paidPaisa + a.amountPaisa;
        await sales.updatePaid(
            txn, inv.id!, newPaid, _paidStatus(newPaid, inv.totalPaisa));
      } else {
        final purchases = PurchaseRepository(txn);
        final inv = (await purchases.getById(a.invoiceId))!;
        final newPaid = inv.paidPaisa + a.amountPaisa;
        await purchases.updatePaid(
            txn, inv.id!, newPaid, _paidStatus(newPaid, inv.totalPaisa));
      }
    }

    // Ledger: customer payment => credit customer / debit cash|bank.
    //         supplier payment => debit supplier / credit cash|bank.
    final partyAccountType =
        isCustomer ? AccountType.customer : AccountType.supplier;
    final description = isCustomer
        ? 'Payment received from $partyName'
        : 'Payment paid to $partyName';
    await _postJournal(
      txn,
      date: date,
      journalKey: journalKey,
      auditEntity: 'payments',
      lines: isCustomer
          ? [
              _JournalLine(
                accountType: partyAccountType,
                accountId: partyId,
                creditPaisa: amountPaisa,
                category: 'payment',
                referenceType: ReferenceTypes.payment,
                referenceId: payment.id,
                description: description,
              ),
              _JournalLine(
                accountType: cashType,
                accountId: accountId,
                debitPaisa: amountPaisa,
                category: 'payment',
                referenceType: ReferenceTypes.payment,
                referenceId: payment.id,
                description: description,
              ),
            ]
          : [
              _JournalLine(
                accountType: partyAccountType,
                accountId: partyId,
                debitPaisa: amountPaisa,
                category: 'payment',
                referenceType: ReferenceTypes.payment,
                referenceId: payment.id,
                description: description,
              ),
              _JournalLine(
                accountType: cashType,
                accountId: accountId,
                creditPaisa: amountPaisa,
                category: 'payment',
                referenceType: ReferenceTypes.payment,
                referenceId: payment.id,
                description: description,
              ),
            ],
    );
    return payment;
  }

  static InvoiceStatus _paidStatus(int paidPaisa, int totalPaisa) {
    if (paidPaisa >= totalPaisa) return InvoiceStatus.paid;
    if (paidPaisa > 0) return InvoiceStatus.partial;
    return InvoiceStatus.unpaid;
  }

  /// Records money RECEIVED from a customer: reduces their receivable,
  /// increases the cash/bank balance, allocates to invoices. Idempotent via
  /// [idempotencyKey].
  Future<Payment> postCustomerPayment({
    required int customerId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    PaymentMethod method = PaymentMethod.cash,
    List<PaymentAllocationInput> allocations = const [],
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) {
    return repo.guard('payments', () async {
      if (idempotencyKey != null) {
        final existing = await PaymentRepository(await _helper.database)
            .findByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing =
              await PaymentRepository(txn).findByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        return _postPaymentInTxn(
          txn,
          date: date,
          partyType: PartyType.customer,
          partyId: customerId,
          amountPaisa: amountPaisa,
          direction: PaymentDirection.received,
          method: method,
          accountId: accountId,
          allocations: allocations,
          invoiceType: 'sale',
          reference: reference,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
      });
    });
  }

  /// Records money PAID to a supplier: reduces the payable, decreases the
  /// cash/bank balance, allocates to purchase invoices. Idempotent via
  /// [idempotencyKey].
  Future<Payment> postSupplierPayment({
    required int supplierId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    PaymentMethod method = PaymentMethod.cash,
    List<PaymentAllocationInput> allocations = const [],
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) {
    return repo.guard('payments', () async {
      if (idempotencyKey != null) {
        final existing = await PaymentRepository(await _helper.database)
            .findByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing =
              await PaymentRepository(txn).findByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        return _postPaymentInTxn(
          txn,
          date: date,
          partyType: PartyType.supplier,
          partyId: supplierId,
          amountPaisa: amountPaisa,
          direction: PaymentDirection.paid,
          method: method,
          accountId: accountId,
          allocations: allocations,
          invoiceType: 'purchase',
          reference: reference,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
      });
    });
  }

  // ------------------------------------------------------- expense / income

  /// Posts a cash/bank udhaar (loan given) to a customer in ONE transaction:
  /// Dr Customer (receivable up) / Cr Cash|Bank (cash down).
  ///
  /// This is the sanctioned path for "Give Udhaar" — pure cash advanced on
  /// credit, NOT a goods sale. Balance caches are updated inside the same
  /// transaction by [_postJournal]; the journal key is returned as the
  /// document id. Idempotent via [idempotencyKey]: re-posting with the same
  /// key returns the existing journal key without writing duplicates.
  Future<String> postCustomerUdhaar({
    required int customerId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    String? note,
    String? idempotencyKey,
  }) {
    return repo.guard('ledger_entries', () async {
      if (amountPaisa <= 0) throw ValidationException('error.invalidAmount');
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing = await txn.query(
            'ledger_entries',
            columns: ['journal_key'],
            where: "category = 'udhaar' AND idempotency_key = ?",
            whereArgs: [idempotencyKey],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            return existing.first['journal_key'] as String;
          }
        }
        final customer = await CustomerRepository(txn).getById(customerId);
        if (customer == null) {
          throw ValidationException(
              'error.customerNotFound', {'id': customerId});
        }
        if (customer.isArchived) {
          throw ValidationException(
              'error.customerArchived', {'name': customer.name});
        }
        final account = await CashAccountRepository(txn).getById(accountId);
        if (account == null || !account.isActive) {
          throw ValidationException('error.accountNotFound', {'id': accountId});
        }
        final cashType = account.type == CashAccountType.cash
            ? AccountType.cash
            : AccountType.bank;
        final description = note ?? 'Udhaar to ${customer.name}';
        final journalKey = await _postJournal(
          txn,
          date: date,
          auditAction: 'post',
          auditEntity: 'ledger_entries',
          lines: [
            _JournalLine(
              accountType: AccountType.customer,
              accountId: customerId,
              debitPaisa: amountPaisa,
              category: 'udhaar',
              referenceType: ReferenceTypes.udhaar,
              description: description,
            ),
            _JournalLine(
              accountType: cashType,
              accountId: accountId,
              creditPaisa: amountPaisa,
              category: 'udhaar',
              referenceType: ReferenceTypes.udhaar,
              description: description,
            ),
          ],
        );
        if (idempotencyKey != null) {
          // Stamp the key on the customer (debit) leg only: the column is
          // UNIQUE, so one marked leg per journal is enough to recognise a
          // re-post, and the journal key on that leg identifies the document.
          await txn.update(
            'ledger_entries',
            {'idempotency_key': idempotencyKey},
            where: 'journal_key = ? AND account_type = ? AND debit_paisa > 0',
            whereArgs: [journalKey, AccountType.customer.dbValue],
          );
        }
        return journalKey;
      });
    });
  }

  /// Posts an expense: debit expense(category) / credit cash|bank.
  Future<ExpenseEntry> postExpense({
    required int categoryId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    String? description,
    String? reference,
  }) {
    return repo.guard('expenses', () async {
      if (amountPaisa <= 0) throw ValidationException('error.invalidAmount');
      return _helper.transaction((txn) async {
        final expenses = ExpenseRepository(txn);
        final category = await expenses.getCategoryById(categoryId);
        if (category == null) {
          throw ValidationException(
              'error.categoryNotFound', {'id': categoryId});
        }
        if (!category.isActive) {
          throw ValidationException(
              'error.categoryInactive', {'name': category.name});
        }
        final account = await CashAccountRepository(txn).getById(accountId);
        if (account == null || !account.isActive) {
          throw ValidationException('error.accountNotFound', {'id': accountId});
        }
        final journalKey = newJournalKey();
        final entry = await expenses.insert(
          txn,
          ExpenseEntry(
            date: date,
            categoryId: categoryId,
            amountPaisa: amountPaisa,
            accountId: accountId,
            description: description,
            reference: reference,
            journalKey: journalKey,
          ),
        );
        final cashType = account.type == CashAccountType.cash
            ? AccountType.cash
            : AccountType.bank;
        await _postJournal(
          txn,
          date: date,
          journalKey: journalKey,
          auditEntity: 'expenses',
          lines: [
            _JournalLine(
              accountType: AccountType.expense,
              accountId: categoryId,
              debitPaisa: amountPaisa,
              category: category.name,
              referenceType: ReferenceTypes.expense,
              referenceId: entry.id,
              description: description ?? 'Expense: ${category.name}',
            ),
            _JournalLine(
              accountType: cashType,
              accountId: accountId,
              creditPaisa: amountPaisa,
              category: category.name,
              referenceType: ReferenceTypes.expense,
              referenceId: entry.id,
              description: description ?? 'Expense: ${category.name}',
            ),
          ],
        );
        return entry;
      });
    });
  }

  /// Posts other income: debit cash|bank / credit income.
  Future<IncomeEntry> postIncome({
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    String? category,
    String? description,
    String? reference,
  }) {
    return repo.guard('income_entries', () async {
      if (amountPaisa <= 0) throw ValidationException('error.invalidAmount');
      return _helper.transaction((txn) async {
        final incomes = IncomeRepository(txn);
        final account = await CashAccountRepository(txn).getById(accountId);
        if (account == null || !account.isActive) {
          throw ValidationException('error.accountNotFound', {'id': accountId});
        }
        final journalKey = newJournalKey();
        final entry = await incomes.insert(
          txn,
          IncomeEntry(
            date: date,
            category: category,
            amountPaisa: amountPaisa,
            accountId: accountId,
            description: description,
            reference: reference,
            journalKey: journalKey,
          ),
        );
        final cashType = account.type == CashAccountType.cash
            ? AccountType.cash
            : AccountType.bank;
        await _postJournal(
          txn,
          date: date,
          journalKey: journalKey,
          auditEntity: 'income_entries',
          lines: [
            _JournalLine(
              accountType: cashType,
              accountId: accountId,
              debitPaisa: amountPaisa,
              category: category ?? 'other',
              referenceType: ReferenceTypes.income,
              referenceId: entry.id,
              description: description ?? 'Income',
            ),
            _JournalLine(
              accountType: AccountType.income,
              accountId: salesIncomeAccountId,
              creditPaisa: amountPaisa,
              category: category ?? 'other',
              referenceType: ReferenceTypes.income,
              referenceId: entry.id,
              description: description ?? 'Income',
            ),
          ],
        );
        return entry;
      });
    });
  }

  /// Moves money between two cash/bank accounts. NOT income/expense:
  /// debit(to) / credit(from).
  Future<AccountTransfer> postTransfer({
    required int fromAccountId,
    required int toAccountId,
    required int amountPaisa,
    required DateTime date,
    String? notes,
  }) {
    return repo.guard('account_transfers', () async {
      if (amountPaisa <= 0) throw ValidationException('error.invalidAmount');
      if (fromAccountId == toAccountId) {
        throw ValidationException('error.transferSameAccount');
      }
      return _helper.transaction((txn) async {
        final accounts = CashAccountRepository(txn);
        final from = await accounts.getById(fromAccountId);
        final to = await accounts.getById(toAccountId);
        if (from == null || !from.isActive) {
          throw ValidationException(
              'error.accountNotFound', {'id': fromAccountId});
        }
        if (to == null || !to.isActive) {
          throw ValidationException(
              'error.accountNotFound', {'id': toAccountId});
        }
        final journalKey = newJournalKey();
        final id = await txn.insert('account_transfers', {
          'date': toEpochMillis(date),
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'amount_paisa': amountPaisa,
          'journal_key': journalKey,
          'notes': notes,
          'created_at': nowMillis(),
        });
        await AuditLog.log(txn,
            action: 'post',
            entity: 'account_transfers',
            entityId: id,
            details: '${from.name} -> ${to.name}');
        await _postJournal(
          txn,
          date: date,
          journalKey: journalKey,
          auditEntity: 'account_transfers',
          lines: [
            _JournalLine(
              accountType: to.type == CashAccountType.cash
                  ? AccountType.cash
                  : AccountType.bank,
              accountId: toAccountId,
              debitPaisa: amountPaisa,
              category: 'transfer',
              referenceType: ReferenceTypes.transfer,
              referenceId: id,
              description: 'Transfer ${from.name} -> ${to.name}',
            ),
            _JournalLine(
              accountType: from.type == CashAccountType.cash
                  ? AccountType.cash
                  : AccountType.bank,
              accountId: fromAccountId,
              creditPaisa: amountPaisa,
              category: 'transfer',
              referenceType: ReferenceTypes.transfer,
              referenceId: id,
              description: 'Transfer ${from.name} -> ${to.name}',
            ),
          ],
        );
        final rows = await txn.query('account_transfers',
            where: 'id = ?', whereArgs: [id], limit: 1);
        return AccountTransfer.fromMap(rows.first);
      });
    });
  }

  // -------------------------------------------------------------- production

  /// Posts a production batch in ONE transaction:
  /// validates input availability, consumes inputs (at moving-average cost),
  /// adds outputs, capitalises the full batch cost into finished-oil outputs'
  /// average cost (pro-rata), computes yield %.
  ///
  /// Cost allocation basis: finished-oil output quantities in kg when every
  /// oil output converts to kg; otherwise in the shared base unit when all
  /// oil outputs share one; otherwise throws `error.oilCostAllocation`.
  /// Oil-cake/by-product outputs are added at zero additional cost.
  ///
  /// When [costCashAccountId] is given, the labour/electricity/other cost
  /// components are ALSO posted as expense vs that cash account (cash paid
  /// out for the batch). When null, the components stay informational on the
  /// batch row — record the actual cash outflow separately via [postExpense].
  Future<ProductionBatch> postProductionBatch({
    required DateTime date,
    required List<BatchInputInput> inputs,
    required List<BatchOutputInput> outputs,
    int labourCostPaisa = 0,
    int electricityCostPaisa = 0,
    int otherCostPaisa = 0,
    int? costCashAccountId,
    String? notes,
  }) {
    return repo.guard('production_batches', () async {
      if (inputs.isEmpty) throw ValidationException('error.emptyBatchInputs');
      if (outputs.isEmpty) throw ValidationException('error.emptyBatchOutputs');
      if (labourCostPaisa < 0 ||
          electricityCostPaisa < 0 ||
          otherCostPaisa < 0) {
        throw ValidationException('error.negativeCost');
      }
      return _helper.transaction((txn) async {
        final products = ProductRepository(txn);
        final units = UnitRepository(txn);
        final production = ProductionRepository(txn);
        final inventory = InventoryRepository(txn);
        final docs = DocumentNumberService();

        CashAccount? costAccount;
        if (costCashAccountId != null) {
          costAccount =
              await CashAccountRepository(txn).getById(costCashAccountId);
          if (costAccount == null || !costAccount.isActive) {
            throw ValidationException(
                'error.accountNotFound', {'id': costCashAccountId});
          }
        }

        // --- inputs: validate, consume, accumulate material cost ---
        final inputCalcs = <_BatchInputCalc>[];
        var materialCostPaisa = 0;
        var inputKgTotal = 0.0;
        var inputKgOk = true;
        for (final input in inputs) {
          if (input.qty <= 0) {
            throw ValidationException('error.invalidQty', {'qty': input.qty});
          }
          final product = await products.getById(input.productId);
          if (product == null) {
            throw ValidationException(
                'error.productNotFound', {'id': input.productId});
          }
          if (product.isArchived) {
            throw ValidationException(
                'error.productArchived', {'name': product.name});
          }
          final unit = await units.getById(input.unitId);
          if (unit == null) {
            throw ValidationException(
                'error.unitNotFound', {'id': input.unitId});
          }
          final qtyBase = await units.convertQty(
              input.qty, input.unitId, product.baseUnitId);
          if (product.stockQty + 1e-9 < qtyBase) {
            throw ValidationException('error.insufficientStock', {
              'product': product.name,
              'available': product.stockQty,
              'needed': qtyBase,
            });
          }
          materialCostPaisa += (qtyBase * product.avgCostPaisa).round();
          inputCalcs.add(_BatchInputCalc(
              input: input, product: product, qtyBase: qtyBase));
          final kg = await _tryConvertToKg(units, input.qty, input.unitId);
          if (kg == null) {
            inputKgOk = false;
          } else {
            inputKgTotal += kg;
          }
        }

        // --- outputs: validate ---
        final outputCalcs = <_BatchOutputCalc>[];
        for (final output in outputs) {
          if (output.qty <= 0) {
            throw ValidationException('error.invalidQty', {'qty': output.qty});
          }
          final product = await products.getById(output.productId);
          if (product == null) {
            throw ValidationException(
                'error.productNotFound', {'id': output.productId});
          }
          if (product.isArchived) {
            throw ValidationException(
                'error.productArchived', {'name': product.name});
          }
          final unit = await units.getById(output.unitId);
          if (unit == null) {
            throw ValidationException(
                'error.unitNotFound', {'id': output.unitId});
          }
          final qtyBase = await units.convertQty(
              output.qty, output.unitId, product.baseUnitId);
          outputCalcs.add(_BatchOutputCalc(
              input: output, product: product, qtyBase: qtyBase));
        }

        final totalCostPaisa = materialCostPaisa +
            labourCostPaisa +
            electricityCostPaisa +
            otherCostPaisa;

        // --- cost allocation weights for finished-oil outputs ---
        final oilCalcs = outputCalcs
            .where((c) => c.input.outputType == OutputType.finishedOil)
            .toList();
        final oilCostShares = _allocateProportionallyDouble(
          totalCostPaisa,
          await _oilAllocationWeights(units, oilCalcs),
        );

        // --- yield % (kg basis) ---
        double? yieldPct;
        if (inputKgOk && inputKgTotal > 0) {
          var oilKgTotal = 0.0;
          var oilKgOk = true;
          for (final c in oilCalcs) {
            final kg =
                await _tryConvertToKg(units, c.input.qty, c.input.unitId);
            if (kg == null) {
              oilKgOk = false;
              break;
            }
            oilKgTotal += kg;
          }
          if (oilKgOk) yieldPct = oilKgTotal / inputKgTotal * 100;
        }

        // --- persist batch + lines ---
        final batchNo =
            await docs.next(txn, DocumentNumberService.productionBatch);
        final journalKey = newJournalKey();
        final batch = await production.insertBatch(
          txn,
          ProductionBatch(
            batchNo: batchNo,
            date: date,
            notes: notes,
            labourCostPaisa: labourCostPaisa,
            electricityCostPaisa: electricityCostPaisa,
            otherCostPaisa: otherCostPaisa,
            yieldPct: yieldPct,
            journalKey: journalKey,
          ),
          inputCalcs
              .map((c) => ProductionInput(
                    productId: c.input.productId,
                    qty: c.input.qty,
                    unitId: c.input.unitId,
                  ))
              .toList(),
          outputCalcs
              .map((c) => ProductionOutput(
                    productId: c.input.productId,
                    qty: c.input.qty,
                    unitId: c.input.unitId,
                    outputType: c.input.outputType,
                  ))
              .toList(),
        );

        // --- consume inputs ---
        for (final c in inputCalcs) {
          await inventory.insertMovement(InventoryMovement(
            date: date,
            productId: c.input.productId,
            qtyChange: -c.input.qty,
            qtyChangeBase: -c.qtyBase,
            unitId: c.input.unitId,
            movementType: MovementTypes.productionInput,
            referenceType: ReferenceTypes.production,
            referenceId: batch.id,
            notes: 'Batch $batchNo input',
          ));
          await products.adjustStockAndCost(
              txn, c.input.productId, -c.qtyBase, null);
        }

        // --- add outputs (oil absorbs batch cost pro-rata) ---
        // NOTE: the product is re-read per output — an earlier output of
        // this same batch may already have changed the stock/average.
        var oilIndex = 0;
        for (final c in outputCalcs) {
          await inventory.insertMovement(InventoryMovement(
            date: date,
            productId: c.input.productId,
            qtyChange: c.input.qty,
            qtyChangeBase: c.qtyBase,
            unitId: c.input.unitId,
            movementType: MovementTypes.productionOutput,
            referenceType: ReferenceTypes.production,
            referenceId: batch.id,
            notes: 'Batch $batchNo output',
          ));
          final current = await products.getById(c.input.productId);
          final oldQty = current?.stockQty ?? c.product.stockQty;
          final oldAvg = current?.avgCostPaisa ?? c.product.avgCostPaisa;
          int? newAvg;
          if (c.input.outputType == OutputType.finishedOil) {
            newAvg = weightedAverageCostPaisa(
              oldQtyBase: oldQty,
              oldAvgCostPaisa: oldAvg,
              addedQtyBase: c.qtyBase,
              addedValuePaisa: oilCostShares[oilIndex],
            );
            oilIndex++;
          } else {
            // Cake/by-products: added at zero additional cost.
            newAvg = weightedAverageCostPaisa(
              oldQtyBase: oldQty,
              oldAvgCostPaisa: oldAvg,
              addedQtyBase: c.qtyBase,
              addedValuePaisa: 0,
            );
          }
          await products.adjustStockAndCost(
              txn, c.input.productId, c.qtyBase, newAvg);
        }

        // --- optional cash journal for the cost components ---
        if (costAccount != null) {
          final cashType = costAccount.type == CashAccountType.cash
              ? AccountType.cash
              : AccountType.bank;
          final costLines = <_JournalLine>[];
          void addCostLine(int amount, String category) {
            if (amount <= 0) return;
            costLines.add(_JournalLine(
              accountType: AccountType.expense,
              accountId: purchaseExpenseAccountId,
              debitPaisa: amount,
              category: category,
              referenceType: ReferenceTypes.production,
              referenceId: batch.id,
              description: 'Batch $batchNo $category',
            ));
          }

          addCostLine(labourCostPaisa, 'production_labour');
          addCostLine(electricityCostPaisa, 'production_electricity');
          addCostLine(otherCostPaisa, 'production_other');
          if (costLines.isNotEmpty) {
            final totalCost =
                costLines.fold<int>(0, (sum, l) => sum + l.debitPaisa);
            costLines.add(_JournalLine(
              accountType: cashType,
              accountId: costAccount.id!,
              creditPaisa: totalCost,
              category: 'production',
              referenceType: ReferenceTypes.production,
              referenceId: batch.id,
              description: 'Batch $batchNo costs from ${costAccount.name}',
            ));
            await _postJournal(
              txn,
              date: date,
              journalKey: journalKey,
              auditEntity: 'production_batches',
              lines: costLines,
            );
          }
        }

        return batch;
      });
    });
  }

  /// Finished-oil cost-allocation weights: kg basis when possible, else the
  /// shared base unit. Throws when neither works.
  Future<List<double>> _oilAllocationWeights(
      UnitRepository units, List<_BatchOutputCalc> oilCalcs) async {
    if (oilCalcs.isEmpty) return const [];
    final kgWeights = <double>[];
    var kgOk = true;
    for (final c in oilCalcs) {
      final kg = await _tryConvertToKg(units, c.input.qty, c.input.unitId);
      if (kg == null) {
        kgOk = false;
        break;
      }
      kgWeights.add(kg);
    }
    if (kgOk) return kgWeights;
    final baseUnits = oilCalcs.map((c) => c.product.baseUnitId).toSet();
    if (baseUnits.length == 1) {
      final baseUnitId = baseUnits.first;
      final weights = <double>[];
      for (final c in oilCalcs) {
        weights.add(
            await units.convertQty(c.input.qty, c.input.unitId, baseUnitId));
      }
      return weights;
    }
    throw ValidationException('error.oilCostAllocation');
  }

  Future<double?> _tryConvertToKg(
      UnitRepository units, double qty, int unitId) async {
    final kg = await units.getBySymbol('kg');
    if (kg == null || kg.id == null) return null;
    try {
      return await units.convertQty(qty, unitId, kg.id!);
    } on ValidationException {
      return null;
    }
  }

  // -------------------------------------------------------- stock adjustment

  /// Manual stock correction with a mandatory reason. Adjusts stock only —
  /// no ledger entries (an adjustment is not a sale, purchase or payment).
  Future<InventoryMovement> postStockAdjustment({
    required int productId,
    required double qty,
    required int unitId,
    required String reason,
    DateTime? date,
  }) {
    return repo.guard('inventory_movements', () async {
      if (qty == 0) throw ValidationException('error.invalidQty');
      if (reason.trim().isEmpty) {
        throw ValidationException('error.reasonRequired');
      }
      final d = date ?? DateTime.now();
      return _helper.transaction((txn) async {
        final products = ProductRepository(txn);
        final units = UnitRepository(txn);
        final inventory = InventoryRepository(txn);
        final product = await products.getById(productId);
        if (product == null) {
          throw ValidationException('error.productNotFound', {'id': productId});
        }
        final unit = await units.getById(unitId);
        if (unit == null) {
          throw ValidationException('error.unitNotFound', {'id': unitId});
        }
        final qtyBase = await units.convertQty(qty, unitId, product.baseUnitId);
        if (qtyBase < 0 && product.stockQty + 1e-9 < -qtyBase) {
          throw ValidationException('error.insufficientStock', {
            'product': product.name,
            'available': product.stockQty,
            'needed': -qtyBase,
          });
        }
        final movement = InventoryMovement(
          date: d,
          productId: productId,
          qtyChange: qty,
          qtyChangeBase: qtyBase,
          unitId: unitId,
          movementType: MovementTypes.adjustment,
          referenceType: ReferenceTypes.adjustment,
          notes: reason,
        );
        final id = await inventory.insertMovement(movement);
        await products.adjustStockAndCost(txn, productId, qtyBase, null);
        await AuditLog.log(txn,
            action: 'post',
            entity: 'inventory_movements',
            entityId: id,
            details: 'Stock adjustment: $reason');
        return movement.copyWith(id: id);
      });
    });
  }

  // ----------------------------------------------------------------- returns

  /// Posts a sales return: restocks goods, reduces the customer receivable
  /// (credit customer / debit income). The original invoice is untouched
  /// except that its status becomes `returned` on full return.
  Future<SalesReturn> postSalesReturn({
    int? invoiceId,
    required int customerId,
    required DateTime date,
    required List<ReturnLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? reason,
    String? idempotencyKey,
  }) {
    return repo.guard('sales_returns', () async {
      if (idempotencyKey != null) {
        final existing = await ReturnRepository(await _helper.database)
            .findSalesReturnByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing = await ReturnRepository(txn)
              .findSalesReturnByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        final customers = CustomerRepository(txn);
        final products = ProductRepository(txn);
        final units = UnitRepository(txn);
        final sales = SalesRepository(txn);
        final returns = ReturnRepository(txn);
        final inventory = InventoryRepository(txn);
        final docs = DocumentNumberService();

        if (lines.isEmpty) throw ValidationException('error.emptyReturn');
        final customer = await customers.getById(customerId);
        if (customer == null) {
          throw ValidationException(
              'error.customerNotFound', {'id': customerId});
        }
        if (customer.isArchived) {
          throw ValidationException(
              'error.customerArchived', {'name': customer.name});
        }
        SalesInvoice? invoice;
        if (invoiceId != null) {
          invoice = await sales.getById(invoiceId);
          if (invoice == null ||
              invoice.customerId != customerId ||
              invoice.status == InvoiceStatus.draft ||
              invoice.status == InvoiceStatus.cancelled) {
            throw ValidationException(
                'error.invoiceNotFound', {'id': invoiceId});
          }
        }

        final calcs = <_ReturnLineCalc>[];
        var subtotal = 0;
        for (final line in lines) {
          if (line.qty <= 0) {
            throw ValidationException('error.invalidQty', {'qty': line.qty});
          }
          if (line.unitPricePaisa < 0) {
            throw ValidationException('error.negativePrice');
          }
          final product = await products.getById(line.productId);
          if (product == null) {
            throw ValidationException(
                'error.productNotFound', {'id': line.productId});
          }
          final unit = await units.getById(line.unitId);
          if (unit == null) {
            throw ValidationException(
                'error.unitNotFound', {'id': line.unitId});
          }
          final qtyBase =
              await units.convertQty(line.qty, line.unitId, product.baseUnitId);
          if (invoice != null) {
            final soldItems = await sales.getItems(invoice.id!);
            var soldBase = 0.0;
            for (final si in soldItems) {
              if (si.productId == line.productId) {
                soldBase += await units.convertQty(
                    si.qty, si.unitId, product.baseUnitId);
              }
            }
            final priorItems = await returns.itemsForSalesInvoiceProduct(
                invoice.id!, line.productId);
            var priorBase = 0.0;
            for (final pi in priorItems) {
              priorBase +=
                  await units.convertQty(pi.qty, pi.unitId, product.baseUnitId);
            }
            if (priorBase + qtyBase - 1e-9 > soldBase) {
              throw ValidationException('error.returnExceedsSold', {
                'product': product.name,
                'sold': soldBase,
              });
            }
          }
          final lineTotal = lineTotalPaisa(
              unitPricePaisa: line.unitPricePaisa, qty: line.qty);
          subtotal += lineTotal;
          calcs.add(_ReturnLineCalc(
              input: line, qtyBase: qtyBase, lineTotalPaisa: lineTotal));
        }
        final discountPaisa = percentOf(subtotal, discountPercent);
        final total = subtotal - discountPaisa + taxPaisa;
        if (total < 0) throw ValidationException('error.negativeTotal');

        final returnNo =
            await docs.next(txn, DocumentNumberService.salesReturn);
        final journalKey = newJournalKey();
        var ret = await returns.insertSalesReturn(
          txn,
          SalesReturn(
            returnNo: returnNo,
            date: date,
            invoiceId: invoiceId,
            customerId: customerId,
            subtotalPaisa: subtotal,
            discountPaisa: discountPaisa,
            taxPaisa: taxPaisa,
            totalPaisa: total,
            reason: reason,
            idempotencyKey: idempotencyKey,
            journalKey: journalKey,
          ),
          calcs
              .map((c) => SalesReturnItem(
                    productId: c.input.productId,
                    qty: c.input.qty,
                    unitId: c.input.unitId,
                    unitPricePaisa: c.input.unitPricePaisa,
                    lineTotalPaisa: c.lineTotalPaisa,
                  ))
              .toList(),
        );

        for (final c in calcs) {
          await inventory.insertMovement(InventoryMovement(
            date: date,
            productId: c.input.productId,
            qtyChange: c.input.qty,
            qtyChangeBase: c.qtyBase,
            unitId: c.input.unitId,
            movementType: MovementTypes.salesReturn,
            referenceType: ReferenceTypes.salesReturn,
            referenceId: ret.id,
            notes: 'Sales return $returnNo',
          ));
          await products.adjustStockAndCost(
              txn, c.input.productId, c.qtyBase, null);
        }

        if (total > 0) {
          await _postJournal(
            txn,
            date: date,
            journalKey: journalKey,
            auditEntity: 'sales_returns',
            lines: [
              _JournalLine(
                accountType: AccountType.customer,
                accountId: customerId,
                creditPaisa: total,
                category: 'sales_returns',
                referenceType: ReferenceTypes.salesReturn,
                referenceId: ret.id,
                description: 'Sales return $returnNo from ${customer.name}',
              ),
              _JournalLine(
                accountType: AccountType.income,
                accountId: salesIncomeAccountId,
                debitPaisa: total,
                category: 'sales_returns',
                referenceType: ReferenceTypes.salesReturn,
                referenceId: ret.id,
                description: 'Sales return $returnNo',
              ),
            ],
          );
        }

        if (invoice != null) {
          final totalReturned =
              await returns.totalReturnedForSalesInvoice(invoice.id!);
          if (totalReturned >= invoice.totalPaisa) {
            await sales.updateStatus(txn, invoice.id!, InvoiceStatus.returned);
          }
        }
        return ret;
      });
    });
  }

  /// Posts a purchase return: removes stock, reduces the supplier payable
  /// (debit supplier / credit expense). Original invoice untouched except
  /// status on full return.
  Future<PurchaseReturn> postPurchaseReturn({
    int? invoiceId,
    required int supplierId,
    required DateTime date,
    required List<ReturnLineInput> lines,
    num discountPercent = 0,
    int taxPaisa = 0,
    String? reason,
    String? idempotencyKey,
  }) {
    return repo.guard('purchase_returns', () async {
      if (idempotencyKey != null) {
        final existing = await ReturnRepository(await _helper.database)
            .findPurchaseReturnByIdempotencyKey(idempotencyKey);
        if (existing != null) return existing;
      }
      return _helper.transaction((txn) async {
        if (idempotencyKey != null) {
          final existing = await ReturnRepository(txn)
              .findPurchaseReturnByIdempotencyKey(idempotencyKey);
          if (existing != null) return existing;
        }
        final suppliers = SupplierRepository(txn);
        final products = ProductRepository(txn);
        final units = UnitRepository(txn);
        final purchases = PurchaseRepository(txn);
        final returns = ReturnRepository(txn);
        final inventory = InventoryRepository(txn);
        final docs = DocumentNumberService();

        if (lines.isEmpty) throw ValidationException('error.emptyReturn');
        final supplier = await suppliers.getById(supplierId);
        if (supplier == null) {
          throw ValidationException(
              'error.supplierNotFound', {'id': supplierId});
        }
        if (supplier.isArchived) {
          throw ValidationException(
              'error.supplierArchived', {'name': supplier.name});
        }
        PurchaseInvoice? invoice;
        if (invoiceId != null) {
          invoice = await purchases.getById(invoiceId);
          if (invoice == null ||
              invoice.supplierId != supplierId ||
              invoice.status == InvoiceStatus.draft ||
              invoice.status == InvoiceStatus.cancelled) {
            throw ValidationException(
                'error.invoiceNotFound', {'id': invoiceId});
          }
        }

        final calcs = <_ReturnLineCalc>[];
        var subtotal = 0;
        for (final line in lines) {
          if (line.qty <= 0) {
            throw ValidationException('error.invalidQty', {'qty': line.qty});
          }
          if (line.unitPricePaisa < 0) {
            throw ValidationException('error.negativePrice');
          }
          final product = await products.getById(line.productId);
          if (product == null) {
            throw ValidationException(
                'error.productNotFound', {'id': line.productId});
          }
          final unit = await units.getById(line.unitId);
          if (unit == null) {
            throw ValidationException(
                'error.unitNotFound', {'id': line.unitId});
          }
          final qtyBase =
              await units.convertQty(line.qty, line.unitId, product.baseUnitId);
          if (product.stockQty + 1e-9 < qtyBase) {
            throw ValidationException('error.insufficientStock', {
              'product': product.name,
              'available': product.stockQty,
              'needed': qtyBase,
            });
          }
          if (invoice != null) {
            final boughtItems = await purchases.getItems(invoice.id!);
            var boughtBase = 0.0;
            for (final pi in boughtItems) {
              if (pi.productId == line.productId) {
                boughtBase += await units.convertQty(
                    pi.qty, pi.unitId, product.baseUnitId);
              }
            }
            final priorItems = await returns.itemsForPurchaseInvoiceProduct(
                invoice.id!, line.productId);
            var priorBase = 0.0;
            for (final pri in priorItems) {
              priorBase += await units.convertQty(
                  pri.qty, pri.unitId, product.baseUnitId);
            }
            if (priorBase + qtyBase - 1e-9 > boughtBase) {
              throw ValidationException('error.returnExceedsBought', {
                'product': product.name,
                'bought': boughtBase,
              });
            }
          }
          final lineTotal = lineTotalPaisa(
              unitPricePaisa: line.unitPricePaisa, qty: line.qty);
          subtotal += lineTotal;
          calcs.add(_ReturnLineCalc(
              input: line, qtyBase: qtyBase, lineTotalPaisa: lineTotal));
        }
        final discountPaisa = percentOf(subtotal, discountPercent);
        final total = subtotal - discountPaisa + taxPaisa;
        if (total < 0) throw ValidationException('error.negativeTotal');

        final returnNo =
            await docs.next(txn, DocumentNumberService.purchaseReturn);
        final journalKey = newJournalKey();
        var ret = await returns.insertPurchaseReturn(
          txn,
          PurchaseReturn(
            returnNo: returnNo,
            date: date,
            invoiceId: invoiceId,
            supplierId: supplierId,
            subtotalPaisa: subtotal,
            discountPaisa: discountPaisa,
            taxPaisa: taxPaisa,
            totalPaisa: total,
            reason: reason,
            idempotencyKey: idempotencyKey,
            journalKey: journalKey,
          ),
          calcs
              .map((c) => PurchaseReturnItem(
                    productId: c.input.productId,
                    qty: c.input.qty,
                    unitId: c.input.unitId,
                    unitPricePaisa: c.input.unitPricePaisa,
                    lineTotalPaisa: c.lineTotalPaisa,
                  ))
              .toList(),
        );

        for (final c in calcs) {
          await inventory.insertMovement(InventoryMovement(
            date: date,
            productId: c.input.productId,
            qtyChange: -c.input.qty,
            qtyChangeBase: -c.qtyBase,
            unitId: c.input.unitId,
            movementType: MovementTypes.purchaseReturn,
            referenceType: ReferenceTypes.purchaseReturn,
            referenceId: ret.id,
            notes: 'Purchase return $returnNo',
          ));
          await products.adjustStockAndCost(
              txn, c.input.productId, -c.qtyBase, null);
        }

        if (total > 0) {
          await _postJournal(
            txn,
            date: date,
            journalKey: journalKey,
            auditEntity: 'purchase_returns',
            lines: [
              _JournalLine(
                accountType: AccountType.supplier,
                accountId: supplierId,
                debitPaisa: total,
                category: 'purchase_returns',
                referenceType: ReferenceTypes.purchaseReturn,
                referenceId: ret.id,
                description: 'Purchase return $returnNo to ${supplier.name}',
              ),
              _JournalLine(
                accountType: AccountType.expense,
                accountId: purchaseExpenseAccountId,
                creditPaisa: total,
                category: 'purchase_returns',
                referenceType: ReferenceTypes.purchaseReturn,
                referenceId: ret.id,
                description: 'Purchase return $returnNo',
              ),
            ],
          );
        }

        if (invoice != null) {
          final totalReturned =
              await returns.totalReturnedForPurchaseInvoice(invoice.id!);
          if (totalReturned >= invoice.totalPaisa) {
            await purchases.updateStatus(
                txn, invoice.id!, InvoiceStatus.returned);
          }
        }
        return ret;
      });
    });
  }

  // ---------------------------------------------------------------- reversal

  /// Reverses a whole journal: creates offsetting entries (debit<->credit
  /// swapped) for EVERY entry sharing the original entry's [journalKey].
  /// Each reversal entry carries `reversedById` = the original entry's id;
  /// original rows are never updated or deleted.
  ///
  /// WARNING: reversal only corrects the ledger and balance caches. Linked
  /// business records (invoice paid amounts/statuses, stock quantities) are
  /// intentionally left untouched — for those, prefer returns or offsetting
  /// payments. Reversing an already-reversed journal throws.
  Future<List<LedgerEntry>> reverseEntry({
    required int entryId,
    required String reason,
  }) {
    return repo.guard('ledger_entries', () async {
      if (reason.trim().isEmpty) {
        throw ValidationException('error.reasonRequired');
      }
      return _helper.transaction((txn) async {
        final original = await _getLedgerEntry(txn, entryId);
        if (original == null) {
          throw ValidationException('error.entryNotFound', {'id': entryId});
        }
        final journal = await _getJournalEntries(txn, original.journalKey);
        for (final e in journal) {
          final already = await txn.query('ledger_entries',
              columns: ['id'],
              where: 'reversed_by_id = ?',
              whereArgs: [e.id],
              limit: 1);
          if (already.isNotEmpty) {
            throw ValidationException(
                'error.alreadyReversed', {'entryNo': e.entryNo});
          }
        }
        final reversalJournalKey = newJournalKey();
        final docs = DocumentNumberService();
        final now = DateTime.now();
        final reversals = <LedgerEntry>[];
        for (final e in journal) {
          final entryNo =
              await docs.next(txn, DocumentNumberService.ledgerEntry);
          final reversal = LedgerEntry(
            entryNo: entryNo,
            journalKey: reversalJournalKey,
            date: now,
            accountType: e.accountType,
            accountId: e.accountId,
            debitPaisa: e.creditPaisa,
            creditPaisa: e.debitPaisa,
            category: e.category,
            referenceType: e.referenceType,
            referenceId: e.referenceId,
            description: 'Reversal of ${e.entryNo}: $reason',
            reversedById: e.id,
          );
          final id = await _insertLedgerEntry(txn, reversal);
          reversals.add(reversal.copyWith(id: id));
        }
        await AuditLog.log(txn,
            action: 'reverse',
            entity: 'ledger_entries',
            entityId: reversalJournalKey,
            details: 'Reversed journal ${original.journalKey}: $reason');
        return reversals;
      });
    });
  }

  // ------------------------------------------------------- verification

  /// Reconciles every cached balance (customers, suppliers, cash accounts)
  /// against the ledger. Returns the mismatches — empty means healthy.
  Future<List<BalanceMismatch>> verifyBalances() {
    return repo.guard('ledger_entries', () async {
      final db = await _helper.database;
      final mismatches = <BalanceMismatch>[];

      final customers =
          await db.query('customers', columns: ['id', 'name', 'balance_paisa']);
      for (final row in customers) {
        final id = row['id'] as int;
        final cached = (row['balance_paisa'] as int?) ?? 0;
        final ledger = await _ledgerBalance(db, AccountType.customer, id);
        if (cached != ledger) {
          mismatches.add(BalanceMismatch(
            accountType: AccountType.customer,
            accountId: id,
            accountName: row['name'] as String?,
            cachedPaisa: cached,
            ledgerPaisa: ledger,
          ));
        }
      }

      final suppliers =
          await db.query('suppliers', columns: ['id', 'name', 'balance_paisa']);
      for (final row in suppliers) {
        final id = row['id'] as int;
        final cached = (row['balance_paisa'] as int?) ?? 0;
        final ledger = await _ledgerBalance(db, AccountType.supplier, id);
        if (cached != ledger) {
          mismatches.add(BalanceMismatch(
            accountType: AccountType.supplier,
            accountId: id,
            accountName: row['name'] as String?,
            cachedPaisa: cached,
            ledgerPaisa: ledger,
          ));
        }
      }

      final accounts = await db.query('cash_accounts',
          columns: ['id', 'name', 'type', 'balance_paisa']);
      for (final row in accounts) {
        final id = row['id'] as int;
        final cached = (row['balance_paisa'] as int?) ?? 0;
        final type = (row['type'] as String?) == 'bank'
            ? AccountType.bank
            : AccountType.cash;
        final ledger = await _ledgerBalance(db, type, id);
        if (cached != ledger) {
          mismatches.add(BalanceMismatch(
            accountType: type,
            accountId: id,
            accountName: row['name'] as String?,
            cachedPaisa: cached,
            ledgerPaisa: ledger,
          ));
        }
      }
      return mismatches;
    });
  }

  /// Customers who owe the business, largest first.
  Future<List<Customer>> receivables() {
    return repo.guard('customers', () async {
      final db = await _helper.database;
      final rows = await db.query('customers',
          where: 'is_archived = 0 AND balance_paisa > 0',
          orderBy: 'balance_paisa DESC');
      return rows.map(Customer.fromMap).toList();
    });
  }

  /// Suppliers the business owes, largest first.
  Future<List<Supplier>> payables() {
    return repo.guard('suppliers', () async {
      final db = await _helper.database;
      final rows = await db.query('suppliers',
          where: 'is_archived = 0 AND balance_paisa > 0',
          orderBy: 'balance_paisa DESC');
      return rows.map(Supplier.fromMap).toList();
    });
  }

  // ---------------------------------------------------------------- summaries

  Future<int> _sumColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String dateColumn,
    int start,
    int end, {
    String? extraWhere,
    List<Object?> extraArgs = const [],
  }) async {
    final where =
        '$dateColumn >= ? AND $dateColumn < ?${extraWhere == null ? '' : ' AND $extraWhere'}';
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM($column), 0) AS s FROM $table WHERE $where',
      [start, end, ...extraArgs],
    );
    return (rows.first['s'] as int?) ?? 0;
  }

  Future<int> _countWhere(
    DatabaseExecutor db,
    String table,
    String dateColumn,
    int start,
    int end, {
    String? extraWhere,
    List<Object?> extraArgs = const [],
  }) async {
    final where =
        '$dateColumn >= ? AND $dateColumn < ?${extraWhere == null ? '' : ' AND $extraWhere'}';
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table WHERE $where',
      [start, end, ...extraArgs],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  static const _postedInvoiceWhere =
      "status IN ('unpaid','partial','paid','returned')";

  Future<DailySummary> _periodSummary(
      int start, int end, DateTime labelDate) async {
    final db = await _helper.database;
    return DailySummary(
      date: labelDate,
      salesPaisa: await _sumColumn(
          db, 'sales_invoices', 'total_paisa', 'date', start, end,
          extraWhere: _postedInvoiceWhere),
      purchasesPaisa: await _sumColumn(
          db, 'purchase_invoices', 'total_paisa', 'date', start, end,
          extraWhere: _postedInvoiceWhere),
      receivedPaisa: await _sumColumn(
          db, 'payments', 'amount_paisa', 'date', start, end,
          extraWhere: "direction = 'received'"),
      paidPaisa: await _sumColumn(
          db, 'payments', 'amount_paisa', 'date', start, end,
          extraWhere: "direction = 'paid'"),
      expensesPaisa:
          await _sumColumn(db, 'expenses', 'amount_paisa', 'date', start, end),
      // Other income only; invoice income is reported via salesPaisa.
      incomePaisa: await _sumColumn(
          db, 'income_entries', 'amount_paisa', 'date', start, end),
    );
  }

  /// Totals for one business day (local calendar day).
  Future<DailySummary> dailySummary(DateTime date) {
    return repo.guard('daily_summary', () async {
      return _periodSummary(startOfDayMillis(date), endOfDayMillis(date), date);
    });
  }

  /// Totals for one calendar month.
  Future<MonthlySummary> monthlySummary(int year, int month) {
    return repo.guard('monthly_summary', () async {
      final range = monthRangeMillis(year, month);
      final db = await _helper.database;
      final daily = await _periodSummary(
          range.start, range.end, DateTime(year, month, 1));
      return MonthlySummary(
        year: year,
        month: month,
        salesPaisa: daily.salesPaisa,
        purchasesPaisa: daily.purchasesPaisa,
        receivedPaisa: daily.receivedPaisa,
        paidPaisa: daily.paidPaisa,
        expensesPaisa: daily.expensesPaisa,
        incomePaisa: daily.incomePaisa,
        salesCount: await _countWhere(
            db, 'sales_invoices', 'date', range.start, range.end,
            extraWhere: _postedInvoiceWhere),
        purchaseCount: await _countWhere(
            db, 'purchase_invoices', 'date', range.start, range.end,
            extraWhere: _postedInvoiceWhere),
      );
    });
  }

  // ---------------------------------------------------------------- statements

  /// Full account statement with running balances, in chronological order.
  ///
  /// [from]/[to] are an inclusive-start/exclusive-end window; the opening
  /// balance is the signed effect of all earlier entries. Running balances
  /// use the same [signedEffect] formula as every other balance in the app.
  Future<LedgerStatement> ledgerWithRunningBalance({
    required AccountType accountType,
    required int accountId,
    DateTime? from,
    DateTime? to,
  }) {
    return repo.guard('ledger_entries', () async {
      final db = await _helper.database;
      var opening = 0;
      final where = <String>['account_type = ?', 'account_id = ?'];
      final args = <Object?>[accountType.dbValue, accountId];
      if (from != null) {
        final fromMillis = toEpochMillis(from);
        final rows = await db.rawQuery(
          'SELECT COALESCE(SUM(debit_paisa), 0) AS d, '
          'COALESCE(SUM(credit_paisa), 0) AS c '
          'FROM ledger_entries '
          'WHERE account_type = ? AND account_id = ? AND date < ?',
          [accountType.dbValue, accountId, fromMillis],
        );
        opening = signedEffect(
          accountType,
          ((rows.first['d'] as num?) ?? 0).toInt(),
          ((rows.first['c'] as num?) ?? 0).toInt(),
        );
        where.add('date >= ?');
        args.add(fromMillis);
      }
      if (to != null) {
        where.add('date < ?');
        args.add(toEpochMillis(to));
      }
      final rows = await db.query(
        'ledger_entries',
        where: where.join(' AND '),
        whereArgs: args,
        orderBy: 'date ASC, id ASC',
      );
      var running = opening;
      final lines = <LedgerLine>[];
      for (final row in rows) {
        final entry = LedgerEntry.fromMap(row);
        running +=
            signedEffect(accountType, entry.debitPaisa, entry.creditPaisa);
        lines.add(LedgerLine(entry: entry, runningBalancePaisa: running));
      }
      return LedgerStatement(
        accountType: accountType,
        accountId: accountId,
        openingBalancePaisa: opening,
        lines: lines,
      );
    });
  }
}

// ===========================================================================
// PRIVATE HELPERS
// ===========================================================================

/// One balanced journal line (before entry numbers are assigned).
class _JournalLine {
  final AccountType accountType;
  final int accountId;
  final int debitPaisa;
  final int creditPaisa;
  final String? category;
  final String? referenceType;
  final int? referenceId;
  final String? description;
  const _JournalLine({
    required this.accountType,
    required this.accountId,
    this.debitPaisa = 0,
    this.creditPaisa = 0,
    this.category,
    this.referenceType,
    this.referenceId,
    this.description,
  });
}

class _SaleLineCalc {
  final SaleLineInput input;
  final Product product;
  final double qtyBase;
  final int lineTotalPaisa;
  const _SaleLineCalc({
    required this.input,
    required this.product,
    required this.qtyBase,
    required this.lineTotalPaisa,
  });
}

class _PurchaseLineCalc {
  final PurchaseLineInput input;
  final Product product;
  final double qtyBase;
  final int lineTotalPaisa;
  const _PurchaseLineCalc({
    required this.input,
    required this.product,
    required this.qtyBase,
    required this.lineTotalPaisa,
  });
}

class _ReturnLineCalc {
  final ReturnLineInput input;
  final double qtyBase;
  final int lineTotalPaisa;
  const _ReturnLineCalc({
    required this.input,
    required this.qtyBase,
    required this.lineTotalPaisa,
  });
}

class _BatchInputCalc {
  final BatchInputInput input;
  final Product product;
  final double qtyBase;
  const _BatchInputCalc({
    required this.input,
    required this.product,
    required this.qtyBase,
  });
}

class _BatchOutputCalc {
  final BatchOutputInput input;
  final Product product;
  final double qtyBase;
  const _BatchOutputCalc({
    required this.input,
    required this.product,
    required this.qtyBase,
  });
}

/// Splits [total] across [weights] pro-rata, half-up per line, last line
/// taking the remainder so the parts always sum exactly to [total].
List<int> _allocateProportionally(int total, List<int> weights) {
  if (weights.isEmpty) return const [];
  final wSum = weights.fold(0, (a, b) => a + b);
  if (wSum <= 0 || total == 0) return List.filled(weights.length, 0);
  final result = List<int>.filled(weights.length, 0);
  for (var i = 0; i < weights.length - 1; i++) {
    result[i] = ((total * weights[i]) / wSum).round();
  }
  result[weights.length - 1] =
      total - result.sublist(0, weights.length - 1).fold(0, (a, b) => a + b);
  return result;
}

/// Same, with double weights (used for production cost allocation).
List<int> _allocateProportionallyDouble(int total, List<double> weights) {
  if (weights.isEmpty) return const [];
  final wSum = weights.fold(0.0, (a, b) => a + b);
  if (wSum <= 0 || total == 0) return List.filled(weights.length, 0);
  final result = List<int>.filled(weights.length, 0);
  for (var i = 0; i < weights.length - 1; i++) {
    result[i] = ((total * weights[i]) / wSum).round();
  }
  result[weights.length - 1] =
      total - result.sublist(0, weights.length - 1).fold(0, (a, b) => a + b);
  return result;
}
