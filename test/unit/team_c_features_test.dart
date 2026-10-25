import 'package:flutter_test/flutter_test.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/supplier.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/supplier_repository.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';

import '../helpers/test_db.dart';

/// Team C (2026-10-25) feature verification:
/// 1. Auto sequential party codes.
/// 2. Sale ledger lines carry the item summary.
/// 3. postPurchaseFromCustomer posts the payable to the customer's ledger.
void main() {
  setUpAll(initFfiDatabase);

  late AccountingService accounting;

  setUp(() async {
    accounting = await freshAccountingService();
  });

  group('auto party codes', () {
    test('customers get codes 1, 2, 3 in order; manual codes untouched',
        () async {
      final db = await DatabaseHelper.instance.database;
      final repo = CustomerRepository(db);

      final id1 = await repo.insert(const Customer(name: 'First'));
      final id2 = await repo.insert(const Customer(name: 'Second'));
      final id3 = await repo.insert(const Customer(name: 'Third'));
      expect((await repo.getById(id1))!.code, '1');
      expect((await repo.getById(id2))!.code, '2');
      expect((await repo.getById(id3))!.code, '3');

      // A caller-supplied code is respected, and the sequence continues
      // after the max NUMERIC code (manual '7' pushes the next auto to 8).
      final idManual =
          await repo.insert(const Customer(name: 'Manual', code: '7'));
      expect((await repo.getById(idManual))!.code, '7');
      final idNext = await repo.insert(const Customer(name: 'Next'));
      expect((await repo.getById(idNext))!.code, '8');
      expect(await repo.nextCode(), '9');
    });

    test('suppliers get their own 1, 2, 3 sequence', () async {
      final db = await DatabaseHelper.instance.database;
      final repo = SupplierRepository(db);
      final id1 = await repo.insert(const Supplier(name: 'Sup One'));
      final id2 = await repo.insert(const Supplier(name: 'Sup Two'));
      expect((await repo.getById(id1))!.code, '1');
      expect((await repo.getById(id2))!.code, '2');
    });
  });

  group('buy/sell ledger references', () {
    test('sale ledger line names the items sold', () async {
      final customerId = await makeCustomer('Buyer');
      final db = await DatabaseHelper.instance.database;
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final productId =
          await makeProduct('Sarson Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: productId, qty: 100, unitId: kgId, reason: 'seed');

      await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 25),
        lines: [
          SaleLineInput(
              productId: productId,
              qty: 40,
              unitId: kgId,
              unitPricePaisa: 45000),
        ],
      );

      final statement = await accounting.ledgerWithRunningBalance(
        accountType: AccountType.customer,
        accountId: customerId,
      );
      final saleLine = statement.lines
          .firstWhere((l) => l.entry.referenceType == 'sale');
      expect(saleLine.entry.description, contains('Sarson Oil'));
      expect(saleLine.entry.description, contains('40 kg'));
      expect(saleLine.entry.referenceId, isNotNull);
      expect(await accounting.verifyBalances(), isEmpty);
    });

    test(
        'purchase from a customer credits their ledger with the item '
        'reference and stocks in', () async {
      final customerId = await makeCustomer('Farmer Customer');
      final db = await DatabaseHelper.instance.database;
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final seedId =
          await makeProduct('Sarson Seed', ProductCategory.rawMaterial);

      final journalKey = await accounting.postPurchaseFromCustomer(
        customerId: customerId,
        date: DateTime(2026, 10, 25),
        lines: [
          PurchaseLineInput(
              productId: seedId, qty: 80, unitId: kgId, unitPricePaisa: 15000),
        ],
        idempotencyKey: 'buy-from-customer-1',
      );
      expect(journalKey, isNotEmpty);

      // Business owes the customer: balance is negative by the total.
      expect(await accounting.getCustomerBalancePaisa(customerId), -1200000);

      // The ledger line names the item and says it is payable.
      final statement = await accounting.ledgerWithRunningBalance(
        accountType: AccountType.customer,
        accountId: customerId,
      );
      final line = statement.lines.single;
      expect(line.entry.creditPaisa, 1200000);
      expect(line.entry.description, contains('Sarson Seed'));
      expect(line.entry.description, contains('payable'));
      expect(line.entry.referenceType, 'purchase');

      // Stock came in.
      expect(await accounting.getProductStockBase(seedId), 80);

      // Idempotent re-post changes nothing.
      await accounting.postPurchaseFromCustomer(
        customerId: customerId,
        date: DateTime(2026, 10, 25),
        lines: [
          PurchaseLineInput(
              productId: seedId, qty: 80, unitId: kgId, unitPricePaisa: 15000),
        ],
        idempotencyKey: 'buy-from-customer-1',
      );
      expect(await accounting.getCustomerBalancePaisa(customerId), -1200000);
      expect(await accounting.getProductStockBase(seedId), 80);

      expect(await accounting.verifyBalances(), isEmpty);
    });
  });
}
