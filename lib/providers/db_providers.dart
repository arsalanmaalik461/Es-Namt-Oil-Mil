import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
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
import '../repositories/report_repository.dart';
import '../repositories/return_repository.dart';
import '../repositories/sales_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/unit_repository.dart';
import '../services/accounting_service.dart';

/// Riverpod providers for the data layer (Module B).
///
/// The database opens asynchronously, so repository/service providers are
/// [FutureProvider]s. Consume with `ref.watch(xProvider)` + `.when(...)`,
/// or `await ref.watch(xProvider.future)` inside async callbacks.
///
/// RULE: UI code must use [accountingServiceProvider] for anything that
/// affects balances. Repositories are CRUD-only.
///
/// Provider catalogue:
///   databaseHelperProvider, databaseProvider,
///   customerRepositoryProvider, supplierRepositoryProvider,
///   productRepositoryProvider, unitRepositoryProvider,
///   inventoryRepositoryProvider, salesRepositoryProvider,
///   purchaseRepositoryProvider, paymentRepositoryProvider,
///   expenseRepositoryProvider, incomeRepositoryProvider,
///   cashAccountRepositoryProvider, productionRepositoryProvider,
///   returnRepositoryProvider, reportRepositoryProvider,
///   documentNumberServiceProvider, accountingServiceProvider.

// ------------------------------------------------------------------ database

/// The singleton database helper (sync — the helper itself is a singleton).
final databaseHelperProvider =
    Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

/// The opened database. All repository providers build on this.
final databaseProvider = FutureProvider<Database>(
    (ref) => ref.watch(databaseHelperProvider).database);

// -------------------------------------------------------------- repositories

final customerRepositoryProvider = FutureProvider<CustomerRepository>(
    (ref) async =>
        CustomerRepository(await ref.watch(databaseProvider.future)));

final supplierRepositoryProvider = FutureProvider<SupplierRepository>(
    (ref) async =>
        SupplierRepository(await ref.watch(databaseProvider.future)));

final productRepositoryProvider = FutureProvider<ProductRepository>(
    (ref) async => ProductRepository(await ref.watch(databaseProvider.future)));

final unitRepositoryProvider = FutureProvider<UnitRepository>(
    (ref) async => UnitRepository(await ref.watch(databaseProvider.future)));

final inventoryRepositoryProvider = FutureProvider<InventoryRepository>(
    (ref) async =>
        InventoryRepository(await ref.watch(databaseProvider.future)));

final salesRepositoryProvider = FutureProvider<SalesRepository>(
    (ref) async => SalesRepository(await ref.watch(databaseProvider.future)));

final purchaseRepositoryProvider = FutureProvider<PurchaseRepository>(
    (ref) async =>
        PurchaseRepository(await ref.watch(databaseProvider.future)));

final paymentRepositoryProvider = FutureProvider<PaymentRepository>(
    (ref) async => PaymentRepository(await ref.watch(databaseProvider.future)));

final expenseRepositoryProvider = FutureProvider<ExpenseRepository>(
    (ref) async => ExpenseRepository(await ref.watch(databaseProvider.future)));

final incomeRepositoryProvider = FutureProvider<IncomeRepository>(
    (ref) async => IncomeRepository(await ref.watch(databaseProvider.future)));

final cashAccountRepositoryProvider = FutureProvider<CashAccountRepository>(
    (ref) async =>
        CashAccountRepository(await ref.watch(databaseProvider.future)));

final productionRepositoryProvider = FutureProvider<ProductionRepository>(
    (ref) async =>
        ProductionRepository(await ref.watch(databaseProvider.future)));

final returnRepositoryProvider = FutureProvider<ReturnRepository>(
    (ref) async => ReturnRepository(await ref.watch(databaseProvider.future)));

/// Document-number generator (must be called inside a posting transaction —
/// in practice you never call this directly; [AccountingService] does).
final documentNumberServiceProvider =
    Provider<DocumentNumberService>((ref) => DocumentNumberService());

// ----------------------------------------------------------------- services

/// THE ledger authority. Use for every balance-affecting operation.
final accountingServiceProvider = FutureProvider<AccountingService>(
    (ref) async => AccountingService(ref.watch(databaseHelperProvider)));

/// Read-only aggregates + statements (delegates balance math to
/// [accountingServiceProvider]).
final reportRepositoryProvider =
    FutureProvider<ReportRepository>((ref) async => ReportRepository(
          await ref.watch(databaseProvider.future),
          await ref.watch(accountingServiceProvider.future),
        ));
