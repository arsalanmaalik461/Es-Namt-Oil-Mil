import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/supplier.dart';
import 'package:namt_oil_mil/repositories/cash_account_repository.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/product_repository.dart';
import 'package:namt_oil_mil/repositories/supplier_repository.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';

/// Routes sqflite through the ffi implementation (in-memory-capable,
/// desktop-friendly) instead of the platform channel. Call once in
/// `setUpAll` of every DB-backed test file.
void initFfiDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Drops and re-seeds the database, then returns a service bound to it.
/// Call inside `setUp` for full test isolation.
Future<AccountingService> freshAccountingService() async {
  await DatabaseHelper.instance.resetForTesting();
  return AccountingService(DatabaseHelper.instance);
}

/// Creates a customer and returns its id.
Future<int> makeCustomer(String name) async {
  final db = await DatabaseHelper.instance.database;
  return CustomerRepository(db).insert(Customer(name: name));
}

/// Creates a supplier and returns its id.
Future<int> makeSupplier(String name) async {
  final db = await DatabaseHelper.instance.database;
  return SupplierRepository(db).insert(Supplier(name: name));
}

/// Creates a product in [category] measured in [unitSymbol] (default 'kg')
/// and returns its id.
Future<int> makeProduct(
  String name,
  ProductCategory category, {
  String unitSymbol = 'kg',
}) async {
  final db = await DatabaseHelper.instance.database;
  final unit = await UnitRepository(db).getBySymbol(unitSymbol);
  expect(unit, isNotNull, reason: 'seeded unit "$unitSymbol" must exist');
  return ProductRepository(db).insert(
    Product(name: name, category: category, baseUnitId: unit!.id!),
  );
}

/// Returns the id of the seeded cash account ("Cash").
Future<int> seededCashAccountId() async {
  final db = await DatabaseHelper.instance.database;
  final accounts = await CashAccountRepository(db).getAll(activeOnly: true);
  final cash = accounts.firstWhere(
    (a) => a.type == CashAccountType.cash,
    orElse: () => accounts.first,
  );
  return cash.id!;
}
