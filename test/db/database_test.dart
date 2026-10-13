import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/services/backup_service.dart';

import '../helpers/test_db.dart';

void main() {
  setUpAll(initFfiDatabase);

  late AccountingService accounting;

  setUp(() async {
    accounting = await freshAccountingService();
  });

  group('CRUD', () {
    test('customer insert -> get -> update -> archive -> search', () async {
      final db = await DatabaseHelper.instance.database;
      final repo = CustomerRepository(db);
      final id = await repo.insert(const Customer(
        name: 'CRUD Customer',
        phone: '03001234567',
      ));
      var row = await repo.getById(id);
      expect(row, isNotNull);
      expect(row!.name, 'CRUD Customer');

      await repo.update(row.copyWith(address: 'Lahore'));
      row = await repo.getById(id);
      expect(row!.address, 'Lahore');

      final found = await repo.search(query: 'CRUD');
      expect(found.any((c) => c.id == id), isTrue);

      await repo.setArchived(id, true);
      row = await repo.getById(id);
      expect(row!.isArchived, isTrue);
      // Archived rows are hidden from default search.
      expect(
          (await repo.search(query: 'CRUD')).any((c) => c.id == id), isFalse);
    });
  });

  group('failed transaction rollback', () {
    test('a sale that fails partway leaves no invoice and no ledger rows',
        () async {
      final customerId = await makeCustomer('Rollback Customer');
      final db = await DatabaseHelper.instance.database;
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final productId =
          await makeProduct('Rollback Oil', ProductCategory.finishedOil);

      // No stock at all -> the sale must fail on stock validation.
      expect(
        () => accounting.postSale(
          customerId: customerId,
          date: DateTime(2026, 10, 1),
          lines: [
            SaleLineInput(
                productId: productId,
                qty: 5,
                unitId: kgId,
                unitPricePaisa: 45000),
          ],
        ),
        throwsA(isA<AppException>()),
      );

      final invoices = await db.query('sales_invoices',
          where: 'customer_id = ?', whereArgs: [customerId]);
      expect(invoices, isEmpty);
      final entries = await db.query(
        'ledger_entries',
        where: 'account_type = ? AND account_id = ?',
        whereArgs: [AccountType.customer.dbValue, customerId],
      );
      expect(entries, isEmpty);
      expect(await accounting.getCustomerBalancePaisa(customerId), 0);
    });
  });

  group('foreign keys', () {
    test('deleting a customer that has invoices is blocked (RESTRICT)',
        () async {
      final db = await DatabaseHelper.instance.database;
      final customerId = await makeCustomer('FK Customer');
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final productId =
          await makeProduct('FK Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: productId, qty: 10, unitId: kgId, reason: 'seed');
      await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 2),
        lines: [
          SaleLineInput(
              productId: productId,
              qty: 2,
              unitId: kgId,
              unitPricePaisa: 45000),
        ],
      );
      expect(
        () => CustomerRepository(db).delete(customerId),
        throwsA(anything),
      );
      // The customer is still there.
      expect(await CustomerRepository(db).getById(customerId), isNotNull);
    });

    test('a customer with no business records can be deleted', () async {
      final db = await DatabaseHelper.instance.database;
      final customerId = await makeCustomer('Deletable Customer');
      await CustomerRepository(db).delete(customerId);
      expect(await CustomerRepository(db).getById(customerId), isNull);
    });
  });

  group('idempotent re-post', () {
    test('same idempotency key returns the existing invoice, no duplicates',
        () async {
      final customerId = await makeCustomer('Idem Customer');
      final db = await DatabaseHelper.instance.database;
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final productId =
          await makeProduct('Idem Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: productId, qty: 10, unitId: kgId, reason: 'seed');

      Future<Database> run() => DatabaseHelper.instance.database;

      final first = await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 3),
        lines: [
          SaleLineInput(
              productId: productId,
              qty: 2,
              unitId: kgId,
              unitPricePaisa: 45000),
        ],
        idempotencyKey: 'sale-idem-1',
      );
      final second = await accounting.postSale(
        customerId: customerId,
        date: DateTime(2026, 10, 3),
        lines: [
          SaleLineInput(
              productId: productId,
              qty: 2,
              unitId: kgId,
              unitPricePaisa: 45000),
        ],
        idempotencyKey: 'sale-idem-1',
      );
      expect(second.id, first.id);
      expect(second.invoiceNo, first.invoiceNo);

      final db2 = await run();
      final invoices = await db2.query(
        'sales_invoices',
        where: 'idempotency_key = ?',
        whereArgs: ['sale-idem-1'],
      );
      expect(invoices.length, 1);
      // One journal only — the customer was charged exactly once.
      expect(await accounting.getCustomerBalancePaisa(customerId),
          first.totalPaisa);
    });
  });

  group('backup round-trip', () {
    test('export -> wipe -> import restores balances exactly', () async {
      final customerId = await makeCustomer('Backup Customer');
      final cashId = await seededCashAccountId();
      final db = await DatabaseHelper.instance.database;
      final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
      final productId =
          await makeProduct('Backup Oil', ProductCategory.finishedOil);
      await accounting.postStockAdjustment(
          productId: productId, qty: 50, unitId: kgId, reason: 'seed');
      await accounting.postCustomerUdhaar(
        customerId: customerId,
        accountId: cashId,
        amountPaisa: 123456,
        date: DateTime(2026, 10, 4),
      );

      final service = BackupService(DatabaseHelper.instance);
      final exported = await service.exportJson();
      expect(exported, isNotEmpty);

      // Validate the payload before touching the database.
      final summary = await service.validateBackup(
        Uint8List.fromList(utf8.encode(jsonEncode(exported))),
      );
      expect(summary.totalRows, greaterThan(0));

      // Wipe everything, then restore.
      await DatabaseHelper.instance.resetForTesting();
      expect(await accounting.getCustomerBalancePaisa(customerId), 0);

      final restored = await service.restoreBackup(
        Uint8List.fromList(utf8.encode(jsonEncode(exported))),
      );
      expect(restored, summary.totalRows);

      // Re-resolve ids by name (AUTOINCREMENT ids survive, but look up
      // defensively anyway).
      final db2 = await DatabaseHelper.instance.database;
      final rows = await db2.query('customers',
          where: 'name = ?', whereArgs: ['Backup Customer'], limit: 1);
      expect(rows, isNotEmpty);
      final restoredId = rows.first['id'] as int;
      expect(await accounting.getCustomerBalancePaisa(restoredId), 123456);
      expect(await accounting.verifyBalances(), isEmpty);
    });

    test('invalid backup payloads are rejected cleanly', () async {
      final service = BackupService(DatabaseHelper.instance);
      // Not JSON at all.
      expect(
        () => service.validateBackup(
            Uint8List.fromList(utf8.encode('this is not json'))),
        throwsA(isA<AppException>()),
      );
      // JSON but not a backup.
      expect(
        () => service.validateBackup(
            Uint8List.fromList(utf8.encode(jsonEncode({'hello': 'world'})))),
        throwsA(isA<AppException>()),
      );
      // Restore path also validates before writing.
      expect(
        () => service.restoreBackup(
            Uint8List.fromList(utf8.encode(jsonEncode({'nope': 1})))),
        throwsA(isA<AppException>()),
      );
    });
  });
}
