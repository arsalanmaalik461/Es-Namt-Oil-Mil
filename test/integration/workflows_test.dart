import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/repositories/cash_account_repository.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/expense_repository.dart';
import 'package:namt_oil_mil/repositories/report_repository.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/services/backup_service.dart';

import '../helpers/test_db.dart';

/// Master end-to-end workflows (A–F): each builds a realistic business
/// story through the public [AccountingService] API and cross-checks every
/// balance, stock figure and ledger total along the way.
void main() {
  setUpAll(initFfiDatabase);

  late AccountingService accounting;
  late int kgId;
  late int cashId;

  setUp(() async {
    accounting = await freshAccountingService();
    final db = await DatabaseHelper.instance.database;
    kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
    cashId = await seededCashAccountId();
  });

  group('A — customer credit lifecycle', () {
    test('opening -> credit sale -> partial payment -> ledger totals',
        () async {
      final db = await DatabaseHelper.instance.database;
      final customerId = await CustomerRepository(db).insert(
        const Customer(name: 'Workflow Customer', openingBalancePaisa: 100000),
      );
      final oilId =
          await makeProduct('Workflow Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: oilId, qty: 100, unitId: kgId, reason: 'seed');

      // Credit sale of Rs 4500.
      final invoice = await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 1),
        lines: [
          SaleLineInput(
              productId: oilId, qty: 10, unitId: kgId, unitPricePaisa: 45000),
        ],
      );
      expect(invoice.totalPaisa, 450000);
      expect(invoice.status, InvoiceStatus.unpaid);
      expect(await accounting.getCustomerBalancePaisa(customerId), 450000);
      expect(await accounting.getProductStockBase(oilId), 90);

      // Partial payment of Rs 1500 against the invoice.
      await accounting.postCustomerPayment(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 150000,
        date: DateTime(2026, 10, 2),
        allocations: [
          PaymentAllocationInput(invoiceId: invoice.id!, amountPaisa: 150000),
        ],
      );
      expect(await accounting.getCustomerBalancePaisa(customerId), 300000);
      expect(await accounting.getAccountBalancePaisa(cashId), 150000);

      // Ledger statement reconciles: Dr 4500, Cr 1500, closing 3000.
      final stmt = await accounting.ledgerWithRunningBalance(
        accountType: AccountType.customer,
        accountId: customerId,
      );
      final debits = stmt.lines.fold<int>(0, (a, l) => a + l.entry.debitPaisa);
      final credits =
          stmt.lines.fold<int>(0, (a, l) => a + l.entry.creditPaisa);
      expect(debits, 450000);
      expect(credits, 150000);
      expect(stmt.closingBalancePaisa, 300000);
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });

  group('B — supplier credit lifecycle', () {
    test('credit purchase -> partial payment -> inventory', () async {
      final supplierId = await makeSupplier('Workflow Supplier');
      final seedId =
          await makeProduct('Workflow Seed', ProductCategory.rawMaterial);

      // Credit purchase: 40 kg @ Rs 200 = Rs 8000.
      final invoice = await accounting.postPurchase(
        supplierId: supplierId,
        date: DateTime(2026, 10, 3),
        lines: [
          PurchaseLineInput(
              productId: seedId, qty: 40, unitId: kgId, unitPricePaisa: 20000),
        ],
      );
      expect(invoice.totalPaisa, 800000);
      expect(await accounting.getSupplierBalancePaisa(supplierId), 800000);
      expect(await accounting.getProductStockBase(seedId), 40);
      // Weighted-average cost = Rs 200/kg.
      final product = await _productById(seedId);
      expect(product.avgCostPaisa, 20000);

      // Partial payment of Rs 3000.
      await accounting.postSupplierPayment(
        supplierId: supplierId,
        accountId: cashId,
        amountPaisa: 300000,
        date: DateTime(2026, 10, 4),
        method: PaymentMethod.cash,
        allocations: [
          PaymentAllocationInput(invoiceId: invoice.id!, amountPaisa: 300000),
        ],
      );
      expect(await accounting.getSupplierBalancePaisa(supplierId), 500000);
      expect(await accounting.getAccountBalancePaisa(cashId), -300000);
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });

  group('C — production', () {
    test('raw material -> batch -> yield and stock', () async {
      final seedId =
          await makeProduct('Mill Seed', ProductCategory.rawMaterial);
      final oilId = await makeProduct('Mill Oil', ProductCategory.finishedOil);
      final cakeId = await makeProduct('Mill Cake', ProductCategory.oilCake);

      // Buy 100 kg seed @ Rs 200/kg.
      final supplierId = await makeSupplier('Mill Supplier');
      await accounting.postPurchase(
        supplierId: supplierId,
        date: DateTime(2026, 10, 5),
        lines: [
          PurchaseLineInput(
              productId: seedId, qty: 100, unitId: kgId, unitPricePaisa: 20000),
        ],
      );

      // Crush into 38 kg oil + 57 kg cake.
      final batch = await accounting.postProductionBatch(
        date: DateTime(2026, 10, 6),
        inputs: [BatchInputInput(productId: seedId, qty: 100, unitId: kgId)],
        outputs: [
          BatchOutputInput(
              productId: oilId,
              qty: 38,
              unitId: kgId,
              outputType: OutputType.finishedOil),
          BatchOutputInput(
              productId: cakeId,
              qty: 57,
              unitId: kgId,
              outputType: OutputType.oilCake),
        ],
        labourCostPaisa: 200000, // Rs 2000 labour capitalised
      );
      expect(batch.yieldPct, closeTo(38.0, 0.001));
      expect(await accounting.getProductStockBase(seedId), 0);
      expect(await accounting.getProductStockBase(oilId), 38);
      expect(await accounting.getProductStockBase(cakeId), 57);
      // Material (100*200=20000 Rs) + labour (2000 Rs) = 22000 Rs over 38 kg.
      final oil = await _productById(oilId);
      expect(oil.avgCostPaisa, (2200000 / 38).round());
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });

  group('D — cashbook', () {
    test('income/expense + cash<->bank transfer reconciles, no double count',
        () async {
      final db = await DatabaseHelper.instance.database;
      final bankId = await CashAccountRepository(db).insert(
        const CashAccount(name: 'Workflow Bank', type: CashAccountType.bank),
      );
      final categories = await ExpenseRepository(db).getCategories();

      // Income Rs 5000 to cash, expense Rs 1200 from cash.
      await accounting.postIncome(
        accountId: cashId,
        amountPaisa: 500000,
        date: DateTime(2026, 10, 7),
        description: 'oil sale cash',
      );
      await accounting.postExpense(
        categoryId: categories.first.id!,
        accountId: cashId,
        amountPaisa: 120000,
        date: DateTime(2026, 10, 7),
        description: 'diesel',
      );
      expect(await accounting.getAccountBalancePaisa(cashId), 380000);

      // Transfer Rs 2000 cash -> bank.
      await accounting.postTransfer(
        fromAccountId: cashId,
        toAccountId: bankId,
        amountPaisa: 200000,
        date: DateTime(2026, 10, 8),
      );
      expect(await accounting.getAccountBalancePaisa(cashId), 180000);
      expect(await accounting.getAccountBalancePaisa(bankId), 200000);

      // Cashbook (ledger) for cash: +5000 -1200 -2000 = +1800 Rs.
      final cashbook = await accounting.ledgerWithRunningBalance(
        accountType: AccountType.cash,
        accountId: cashId,
      );
      expect(cashbook.closingBalancePaisa, 180000);

      // The transfer must not be double-counted as income/expense:
      // P&L for the period sees exactly the one income and one expense.
      final pl = await ReportRepository(db, accounting)
          .profitLoss(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
      expect(pl.incomePaisa, 500000);
      expect(pl.expensePaisa, 120000);
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });

  group('E — backup and restore', () {
    test('full business state survives export -> wipe -> import', () async {
      final customerId = await makeCustomer('E2E Customer');
      final oilId = await makeProduct('E2E Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: oilId, qty: 20, unitId: kgId, reason: 'seed');
      await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 9),
        lines: [
          SaleLineInput(
              productId: oilId, qty: 4, unitId: kgId, unitPricePaisa: 45000),
        ],
      );
      await accounting.postCustomerUdhaar(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 50000,
        date: DateTime(2026, 10, 9),
      );
      final balanceBefore =
          await accounting.getCustomerBalancePaisa(customerId);
      final stockBefore = await accounting.getProductStockBase(oilId);

      final service = BackupService(DatabaseHelper.instance);
      final payload = await service.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

      await DatabaseHelper.instance.resetForTesting();
      expect(await accounting.getCustomerBalancePaisa(customerId), 0);

      await service.restoreBackup(bytes);

      final db2 = await DatabaseHelper.instance.database;
      final rows = await db2.query('customers',
          where: 'name = ?', whereArgs: ['E2E Customer'], limit: 1);
      final restoredId = rows.first['id'] as int;
      expect(
          await accounting.getCustomerBalancePaisa(restoredId), balanceBefore);
      final oilRows = await db2.query('products',
          where: 'name = ?', whereArgs: ['E2E Oil'], limit: 1);
      expect((oilRows.first['stock_qty'] as num).toDouble(), stockBefore);
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });

  group('F — udhaar', () {
    test('cash advance raises the receivable and lowers cash', () async {
      final customerId = await makeCustomer('Udhaar Customer');
      final cashBefore = await accounting.getAccountBalancePaisa(cashId);

      final docId = await accounting.postCustomerUdhaar(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 250000,
        date: DateTime(2026, 10, 10),
        note: 'advance for next purchase',
      );
      expect(docId, isNotEmpty);
      expect(await accounting.getCustomerBalancePaisa(customerId), 250000);
      expect(
          await accounting.getAccountBalancePaisa(cashId), cashBefore - 250000);

      // The journal legs carry the udhaar category.
      final db = await DatabaseHelper.instance.database;
      final legs = await db.query(
        'ledger_entries',
        where: 'journal_key = ?',
        whereArgs: [docId],
      );
      expect(legs.length, 2);
      expect(legs.every((l) => l['category'] == 'udhaar'), isTrue);

      // Repayment via a normal customer payment clears it.
      await accounting.postCustomerPayment(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 250000,
        date: DateTime(2026, 10, 11),
      );
      expect(await accounting.getCustomerBalancePaisa(customerId), 0);
      expect(await accounting.verifyBalances(), isEmpty);
    });
  });
}

Future<Product> _productById(int id) async {
  final db = await DatabaseHelper.instance.database;
  final rows =
      await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
  return Product.fromMap(rows.first);
}
