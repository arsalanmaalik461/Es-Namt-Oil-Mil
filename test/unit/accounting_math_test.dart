import 'package:flutter_test/flutter_test.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/repositories/cash_account_repository.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/expense_repository.dart';
import 'package:namt_oil_mil/repositories/report_repository.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';

import '../helpers/test_db.dart';

void main() {
  setUpAll(initFfiDatabase);

  late AccountingService accounting;
  late int customerId;
  late int cashId;
  late int kgId;
  late int oilProductId;

  setUp(() async {
    accounting = await freshAccountingService();
    customerId = await makeCustomer('Math Customer');
    cashId = await seededCashAccountId();
    final db = await DatabaseHelper.instance.database;
    kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
    oilProductId = await makeProduct('Math Oil', ProductCategory.finishedOil);
    // Seed stock via adjustment so sales have something to sell.
    await accounting.postStockAdjustment(
      productId: oilProductId,
      qty: 100,
      unitId: kgId,
      reason: 'test seed',
    );
  });

  SaleLineInput line({double qty = 10, int unitPricePaisa = 45000}) =>
      SaleLineInput(
          productId: oilProductId,
          qty: qty,
          unitId: kgId,
          unitPricePaisa: unitPricePaisa);

  group('invoice math', () {
    test('line discount + invoice discount + tax compose correctly', () async {
      // 10 kg @ Rs 450 with 10% line discount = Rs 4050 line total.
      final invoice = await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 1),
        lines: [
          SaleLineInput(
            productId: oilProductId,
            qty: 10,
            unitId: kgId,
            unitPricePaisa: 45000,
            discountPercent: 10,
          ),
        ],
        discountPercent: 5, // 5% of 405000 = 20250
        taxPaisa: 10000, // + Rs 100
      );
      expect(invoice.subtotalPaisa, 405000);
      expect(invoice.discountPaisa, 20250);
      expect(invoice.taxPaisa, 10000);
      expect(invoice.totalPaisa, 405000 - 20250 + 10000);
      // The customer owes exactly the invoice total.
      expect(await accounting.getCustomerBalancePaisa(customerId),
          invoice.totalPaisa);
    });

    test('partial payments walk the invoice status unpaid -> partial -> paid',
        () async {
      final invoice = await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 2),
        lines: [line(qty: 10)], // Rs 4500 = 450000 paisa
      );
      expect(invoice.status, InvoiceStatus.unpaid);

      final half = invoice.totalPaisa ~/ 2;
      await accounting.postCustomerPayment(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: half,
        date: DateTime(2026, 10, 3),
        allocations: [
          PaymentAllocationInput(invoiceId: invoice.id!, amountPaisa: half),
        ],
      );
      var reloaded = await accounting.getCustomerBalancePaisa(customerId);
      expect(reloaded, invoice.totalPaisa - half);

      await accounting.postCustomerPayment(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: invoice.totalPaisa - half,
        date: DateTime(2026, 10, 4),
        allocations: [
          PaymentAllocationInput(
              invoiceId: invoice.id!, amountPaisa: invoice.totalPaisa - half),
        ],
      );
      reloaded = await accounting.getCustomerBalancePaisa(customerId);
      expect(reloaded, 0);
      expect(
          await accounting.getAccountBalancePaisa(cashId), invoice.totalPaisa);
    });
  });

  group('opening balances', () {
    test('stored on the party row; ledger balance starts at zero', () async {
      final db = await DatabaseHelper.instance.database;
      final id = await CustomerRepository(db).insert(
        Customer(name: 'Opening Customer', openingBalancePaisa: 250000),
      );
      final row = await CustomerRepository(db).getById(id);
      expect(row!.openingBalancePaisa, 250000);
      // Opening balances are informational on the row; nothing is posted
      // to the ledger, so the ledger-derived balance starts at 0.
      expect(await accounting.getCustomerBalancePaisa(id), 0);
    });
  });

  group('running balances', () {
    test('ledgerWithRunningBalance chains opening -> lines -> closing',
        () async {
      await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 5),
        lines: [line(qty: 10)], // 450000
      );
      await accounting.postCustomerPayment(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 150000,
        date: DateTime(2026, 10, 6),
      );
      final stmt = await accounting.ledgerWithRunningBalance(
        accountType: AccountType.customer,
        accountId: customerId,
      );
      expect(stmt.openingBalancePaisa, 0);
      expect(stmt.lines.length, 2);
      expect(stmt.lines[0].runningBalancePaisa, 450000);
      expect(stmt.lines[1].runningBalancePaisa, 300000);
      expect(stmt.closingBalancePaisa, 300000);
    });
  });

  group('receivables / payables', () {
    test('receivables lists owing customers, highest first', () async {
      final rich = await makeCustomer('Rich Owes More');
      final poor = await makeCustomer('Poor Owes Less');
      await accounting.postCustomerUdhaar(
        customerId: rich,
        accountId: cashId,
        amountPaisa: 900000,
        date: DateTime(2026, 10, 7),
      );
      await accounting.postCustomerUdhaar(
        customerId: poor,
        accountId: cashId,
        amountPaisa: 100000,
        date: DateTime(2026, 10, 7),
      );
      final list = await accounting.receivables();
      expect(list.length, 2);
      expect(list.first.name, 'Rich Owes More');
      expect(list.first.balancePaisa, 900000);
    });

    test('supplier credit purchase appears in payables', () async {
      final supplierId = await makeSupplier('Math Supplier');
      final seedId =
          await makeProduct('Math Seed', ProductCategory.rawMaterial);
      await accounting.postPurchase(
        supplierId: supplierId,
        date: DateTime(2026, 10, 8),
        lines: [
          PurchaseLineInput(
              productId: seedId, qty: 40, unitId: kgId, unitPricePaisa: 20000),
        ],
      );
      final payables = await accounting.payables();
      expect(payables.any((s) => s.id == supplierId), isTrue);
      expect(await accounting.getSupplierBalancePaisa(supplierId), 800000);
    });
  });

  group('transfers', () {
    test('cash -> bank transfer is NOT income/expense', () async {
      final db = await DatabaseHelper.instance.database;
      final before = await accounting.getAccountBalancePaisa(cashId);
      // Create a second (bank) account to transfer into.
      final bankId = await _makeBankAccount();
      await accounting.postTransfer(
        fromAccountId: cashId,
        toAccountId: bankId,
        amountPaisa: 50000,
        date: DateTime(2026, 10, 9),
      );
      expect(await accounting.getAccountBalancePaisa(cashId), before - 50000);
      expect(await accounting.getAccountBalancePaisa(bankId), 50000);
      // No income/expense ledger entries may exist anywhere.
      final rows = await db.query(
        'ledger_entries',
        where: "account_type IN ('income','expense')",
        limit: 1,
      );
      expect(rows, isEmpty);
      // P&L sees nothing.
      final pl = await ReportRepository(db, accounting)
          .profitLoss(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
      expect(pl.incomePaisa, 0);
      expect(pl.expensePaisa, 0);
    });

    test('transfer to the same account is rejected', () async {
      expect(
        () => accounting.postTransfer(
          fromAccountId: cashId,
          toAccountId: cashId,
          amountPaisa: 1000,
          date: DateTime(2026, 10, 9),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('unit conversions', () {
    test('maund -> kg uses the seeded 40x factor', () async {
      expect(await accounting.convertQty(2, await _unitId('maund'), kgId), 80);
    });

    test('litre -> kg is deliberately unseeded and throws', () async {
      final litreId = await _unitId('litre');
      expect(
        () => accounting.convertQty(1, litreId, kgId),
        throwsA(isA<AppException>()
            .having((e) => e.messageKey, 'messageKey', 'error.noConversion')),
      );
    });
  });

  group('stock movements', () {
    test('purchase raises stock and sets weighted-average cost', () async {
      final supplierId = await makeSupplier('Stock Supplier');
      final seedId = await makeProduct('Seed A', ProductCategory.rawMaterial);
      await accounting.postPurchase(
        supplierId: supplierId,
        date: DateTime(2026, 10, 10),
        lines: [
          PurchaseLineInput(
              productId: seedId,
              qty: 10,
              unitId: kgId,
              unitPricePaisa: 40000), // Rs 400/kg
          PurchaseLineInput(
              productId: seedId,
              qty: 10,
              unitId: kgId,
              unitPricePaisa: 60000), // Rs 600/kg
        ],
      );
      expect(await accounting.getProductStockBase(seedId), 20);
      final product = await _productById(seedId); // avg cost: Rs 500/kg
      expect(product.avgCostPaisa, 50000);
    });

    test('sale beyond stock throws and changes nothing', () async {
      final before = await accounting.getProductStockBase(oilProductId);
      expect(
        () => accounting.postSale(
          customerId: customerId,
          date: DateTime(2026, 10, 11),
          lines: [line(qty: before + 1)],
        ),
        throwsA(isA<AppException>()),
      );
      expect(await accounting.getProductStockBase(oilProductId), before);
      expect(await accounting.getCustomerBalancePaisa(customerId), 0);
    });
  });

  group('production yield', () {
    test('yield % = oil kg / input kg * 100', () async {
      final seedId = await makeProduct('Seed B', ProductCategory.rawMaterial);
      final cakeId = await makeProduct('Cake B', ProductCategory.oilCake);
      await accounting.postStockAdjustment(
          productId: seedId, qty: 100, unitId: kgId, reason: 'test seed');
      final batch = await accounting.postProductionBatch(
        date: DateTime(2026, 10, 12),
        inputs: [BatchInputInput(productId: seedId, qty: 100, unitId: kgId)],
        outputs: [
          BatchOutputInput(
              productId: oilProductId,
              qty: 40,
              unitId: kgId,
              outputType: OutputType.finishedOil),
          BatchOutputInput(
              productId: cakeId,
              qty: 55,
              unitId: kgId,
              outputType: OutputType.oilCake),
        ],
      );
      expect(batch.yieldPct, closeTo(40.0, 0.001));
      // 100 kg seed consumed, 40 kg oil + 55 kg cake produced.
      expect(await accounting.getProductStockBase(seedId), 0);
      expect(await accounting.getProductStockBase(oilProductId),
          100 + 40); // 100 seeded in setUp
    });
  });

  group('P&L math', () {
    test('sale is income, expense is expense, net = income - expense',
        () async {
      await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 13),
        lines: [line(qty: 10)], // 450000 income
      );
      final db = await DatabaseHelper.instance.database;
      final categories = await ExpenseRepository(db).getCategories();
      expect(categories, isNotEmpty);
      await accounting.postExpense(
        categoryId: categories.first.id!,
        accountId: cashId,
        amountPaisa: 50000,
        date: DateTime(2026, 10, 13),
        description: 'test expense',
      );
      final pl = await ReportRepository(db, accounting)
          .profitLoss(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
      expect(pl.incomePaisa, 450000);
      expect(pl.expensePaisa, 50000);
      expect(pl.netPaisa, 400000);
    });
  });

  group('udhaar posting', () {
    test('raises the receivable, lowers cash, balances verify clean', () async {
      final cashBefore = await accounting.getAccountBalancePaisa(cashId);
      final key = await accounting.postCustomerUdhaar(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 75000,
        date: DateTime(2026, 10, 14),
        note: 'test udhaar',
        idempotencyKey: 'udhaar-test-1',
      );
      expect(key, isNotEmpty);
      expect(await accounting.getCustomerBalancePaisa(customerId), 75000);
      expect(
          await accounting.getAccountBalancePaisa(cashId), cashBefore - 75000);
      // Idempotent re-post returns the same journal key, no duplicates.
      final key2 = await accounting.postCustomerUdhaar(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 75000,
        date: DateTime(2026, 10, 14),
        idempotencyKey: 'udhaar-test-1',
      );
      expect(key2, key);
      expect(await accounting.getCustomerBalancePaisa(customerId), 75000);
      expect(await accounting.verifyBalances(), isEmpty);
    });

    test('rejects non-positive amounts', () async {
      expect(
        () => accounting.postCustomerUdhaar(
          customerId: customerId,
          accountId: cashId,
          amountPaisa: 0,
          date: DateTime(2026, 10, 14),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}

Future<int> _unitId(String symbol) async {
  final db = await DatabaseHelper.instance.database;
  return (await UnitRepository(db).getBySymbol(symbol))!.id!;
}

Future<int> _makeBankAccount() async {
  final db = await DatabaseHelper.instance.database;
  return CashAccountRepository(db).insert(
    const CashAccount(name: 'Test Bank', type: CashAccountType.bank),
  );
}

Future<Product> _productById(int id) async {
  final db = await DatabaseHelper.instance.database;
  final rows =
      await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
  return Product.fromMap(rows.first);
}
