# Namt Oil Mil — Data Layer API Contract (Module B)

> **Wave 2 UI agents: code against this file.** It is the complete, precise
> contract of the data layer. If a signature here disagrees with an older
> file in the repo, this file wins.

## The one rule

**UI must call `AccountingService` for anything that affects a balance —
sales, purchases, payments, expenses, income, transfers, production batches,
returns, stock adjustments, reversals. Repositories are CRUD-only** (create /
read / update / archive / search). Screens must **never** compute balances ad
hoc — not from invoices, not from payments, not from the ledger. All balance
formulas live in exactly one place: `AccountingService.signedEffect`, exposed
via `getCustomerBalancePaisa` / `getSupplierBalancePaisa` /
`getAccountBalancePaisa` / `ledgerWithRunningBalance`.

## Money conventions

- Money is **`int` paisa** everywhere: DB columns (`*_paisa`), models, method
  parameters and return values. 1 PKR = 100 paisa.
- **Never** use `double` for money. Quantities (kg, litres) are `double` in
  their own unit; convert back to integer paisa with the helpers below.
- `lib/utils/money.dart` (exact contract, Agent A imports this):

```dart
const int paisaPerRupee = 100;
String formatPkr(int paisa);              // 125050 -> "Rs 1,250.50"
int parsePkrToPaisa(String input);        // "1,250.50" -> 125050 (throws FormatException)
int percentOf(int amountPaisa, num percent);      // half-up, integer math
int applyDiscount(int amountPaisa, num discountPercent);
// extras:
int lineTotalPaisa({required int unitPricePaisa, required double qty, num discountPercent = 0});
int weightedAverageCostPaisa({required double oldQtyBase, required int oldAvgCostPaisa, required double addedQtyBase, required int addedValuePaisa});
```

## Exceptions

`lib/core/app_exception.dart`:

```dart
class AppException implements Exception {
  final String messageKey;            // l10n key, e.g. 'error.insufficientStock'
  final Map<String, Object?> params;  // interpolation values
}
class DatabaseException extends AppException { final Object? cause; }
class ValidationException extends AppException {}  // business-rule violation
```

- Every repository/service failure **throws** — nothing silently reports success.
- Catch `AppException` at the screen level and show the translated
  `messageKey`. Never show `toString()` to users.
- Common `messageKey`s: `error.database`, `error.insufficientStock`,
  `error.noConversion`, `error.overAllocated`, `error.overAllocatedInvoice`,
  `error.alreadyReversed`, `error.customerNotFound`, `error.supplierNotFound`,
  `error.productNotFound`, `error.accountNotFound`, `error.invalidQty`,
  `error.invalidAmount`, `error.negativeTotal`, `error.emptyInvoice`,
  `error.reasonRequired`, `error.returnExceedsSold`, `error.returnExceedsBought`,
  `error.transferSameAccount`, `error.methodAccountMismatch`,
  `error.unbalancedJournal`, `error.notADraft`.

## Providers (`lib/providers/db_providers.dart`)

Import: `package:namt_oil_mil/providers/db_providers.dart` with
`flutter_riverpod`. The DB opens asynchronously, so data providers are
`FutureProvider`s — use `ref.watch(p).when(...)` or
`await ref.watch(p.future)`.

| Provider | Type |
|---|---|
| `databaseHelperProvider` | `Provider<DatabaseHelper>` (singleton) |
| `databaseProvider` | `FutureProvider<Database>` |
| `customerRepositoryProvider` | `FutureProvider<CustomerRepository>` |
| `supplierRepositoryProvider` | `FutureProvider<SupplierRepository>` |
| `productRepositoryProvider` | `FutureProvider<ProductRepository>` |
| `unitRepositoryProvider` | `FutureProvider<UnitRepository>` |
| `inventoryRepositoryProvider` | `FutureProvider<InventoryRepository>` |
| `salesRepositoryProvider` | `FutureProvider<SalesRepository>` |
| `purchaseRepositoryProvider` | `FutureProvider<PurchaseRepository>` |
| `paymentRepositoryProvider` | `FutureProvider<PaymentRepository>` |
| `expenseRepositoryProvider` | `FutureProvider<ExpenseRepository>` |
| `incomeRepositoryProvider` | `FutureProvider<IncomeRepository>` |
| `cashAccountRepositoryProvider` | `FutureProvider<CashAccountRepository>` |
| `productionRepositoryProvider` | `FutureProvider<ProductionRepository>` |
| `returnRepositoryProvider` | `FutureProvider<ReturnRepository>` |
| `reportRepositoryProvider` | `FutureProvider<ReportRepository>` |
| `documentNumberServiceProvider` | `Provider<DocumentNumberService>` |
| **`accountingServiceProvider`** | **`FutureProvider<AccountingService>` — the one UI uses for postings** |

## `AccountingService` — method reference

Import: `package:namt_oil_mil/services/accounting_service.dart`.

### Balance readers (the only legal way to read a balance)

```dart
Future<int> getCustomerBalancePaisa(int customerId);   // >0 = customer owes business
Future<int> getSupplierBalancePaisa(int supplierId);   // >0 = business owes supplier
Future<int> getAccountBalancePaisa(int accountId);     // cash/bank on-hand
Future<double> getProductStockBase(int productId);     // stock in base unit
Future<double> convertQty(double qty, int fromUnitId, int toUnitId);
Future<LedgerStatement> ledgerWithRunningBalance({
  required AccountType accountType, required int accountId,
  DateTime? from, DateTime? to,                       // inclusive start, exclusive end
});
Future<List<BalanceMismatch>> verifyBalances();        // [] = healthy
Future<List<Customer>> receivables();                  // balance>0, desc
Future<List<Supplier>> payables();                      // balance>0, desc
Future<DailySummary> dailySummary(DateTime date);
Future<MonthlySummary> monthlySummary(int year, int month);
```

`LedgerStatement { accountType, accountId, openingBalancePaisa, lines: List<LedgerLine>, closingBalancePaisa }`;
`LedgerLine { entry: LedgerEntry, runningBalancePaisa }`.

### Postings (each is ONE atomic DB transaction; all-or-nothing)

```dart
Future<SalesInvoice> postSale({
  required int customerId, required DateTime date,
  required List<SaleLineInput> lines,          // productId, qty, unitId, unitPricePaisa, discountPercent
  num discountPercent = 0, int taxPaisa = 0,
  String? notes, String? idempotencyKey,        // re-post with same key -> returns existing
});
Future<SalesInvoice> createSalesDraft({ required int customerId, required DateTime date,
  required List<SaleLineInput> lines, num discountPercent = 0, int taxPaisa = 0, String? notes });
Future<SalesInvoice> postDraftSale(int draftId);   // draft replaced, number reused

Future<PurchaseInvoice> postPurchase({ required int supplierId, required DateTime date,
  required List<PurchaseLineInput> lines, num discountPercent = 0, int taxPaisa = 0,
  String? notes, String? idempotencyKey });
Future<PurchaseInvoice> createPurchaseDraft({...});   // mirror of sales
Future<PurchaseInvoice> postDraftPurchase(int draftId);

Future<Payment> postCustomerPayment({
  required int customerId, required int accountId, required int amountPaisa,
  required DateTime date, PaymentMethod method = PaymentMethod.cash,
  List<PaymentAllocationInput> allocations = const [],  // invoiceId + amountPaisa ('sale' invoices)
  String? reference, String? notes, String? idempotencyKey,
});
Future<Payment> postSupplierPayment({ required int supplierId, ... });  // mirror, invoiceType 'purchase'

Future<ExpenseEntry> postExpense({ required int categoryId, required int accountId,
  required int amountPaisa, required DateTime date, String? description, String? reference });
Future<IncomeEntry> postIncome({ required int accountId, required int amountPaisa,
  required DateTime date, String? category, String? description, String? reference });
Future<AccountTransfer> postTransfer({ required int fromAccountId, required int toAccountId,
  required int amountPaisa, required DateTime date, String? notes });

Future<ProductionBatch> postProductionBatch({
  required DateTime date,
  required List<BatchInputInput> inputs,      // productId, qty, unitId
  required List<BatchOutputInput> outputs,    // productId, qty, unitId, outputType
  int labourCostPaisa = 0, int electricityCostPaisa = 0, int otherCostPaisa = 0,
  int? costCashAccountId,   // when set, labour/electricity/other are posted as expense vs this account
  String? notes,
});

Future<InventoryMovement> postStockAdjustment({ required int productId, required double qty,
  required int unitId, required String reason, DateTime? date });   // qty signed, in unitId

Future<SalesReturn> postSalesReturn({ int? invoiceId, required int customerId,
  required DateTime date, required List<ReturnLineInput> lines,
  num discountPercent = 0, int taxPaisa = 0, String? reason, String? idempotencyKey });
Future<PurchaseReturn> postPurchaseReturn({ int? invoiceId, required int supplierId, ... }); // mirror

Future<List<LedgerEntry>> reverseEntry({ required int entryId, required String reason });
// Reverses the WHOLE journal of entryId with offsetting entries (originals untouched).
// Ledger + caches only — invoice paid amounts and stock are NOT auto-adjusted.
// Prefer returns / offsetting payments for business corrections.
```

Posting semantics to remember:
- Sale validates stock (throws `error.insufficientStock`), writes invoice
  (`SI-…`), items, stock-out movements, journal (debit customer / credit
  income), updates the customer balance cache.
- Purchase writes invoice (`PI-…`), stock-in movements, recalculates the
  weighted-average cost, journal (debit expense/`purchase` / credit supplier).
- Payments allocate to invoices (`paidPaisa`, status unpaid→partial→paid);
  unallocated remainder stays as advance on the party balance.
- Returns restock / de-stock, adjust party balances, and flip the invoice
  status to `returned` on full return. Original invoices are never edited.
- Production consumes inputs at avg cost, capitalises
  materials+labour+electricity+other into finished-oil outputs' avg cost
  pro-rata, adds cake/by-products at zero cost, computes `yieldPct`
  (oil kg ÷ input kg × 100, null when a kg conversion is missing).
- Drafts carry no financial effects and may be edited/deleted; only
  `postDraftSale`/`postDraftPurchase` give them effects.

## Repositories — method reference (CRUD-only, no balance math)

All constructors take a `DatabaseExecutor` (`Database` or `Transaction`).
All throw `DatabaseException` on failure. `search`/`list` are paged
(`limit`/`offset`, `WHERE … LIKE ?` on indexed columns).

- `CustomerRepository` / `SupplierRepository`: `insert`, `getById`,
  `search({query, limit, offset, includeArchived})`, `count`, `update`
  (never touches balances), `setArchived`, `delete` (RESTRICT-aware),
  `adjustBalance(db, id, delta)` ⚠ service-only, `cachedBalance(id)`.
- `ProductRepository`: `insert`, `getById`, `search({query, category, limit,
  offset, includeArchived})`, `getAll`, `lowStock`, `update` (never touches
  stock/cost), `setArchived`, `delete`, `adjustStockAndCost(db, id,
  qtyDeltaBase, newAvgCostPaisa?)` ⚠ service-only.
- `UnitRepository`: `getAll`, `getById`, `getBySymbol`, `insertUnit`,
  `listConversions`, `insertConversion`, `deleteConversion`,
  `getFactor(from, to)` (auto-derives reverse as 1/f),
  `convertQty(qty, from, to)` (throws `error.noConversion`).
- `InventoryRepository`: `insertMovement`, `movementsForProduct`,
  `movementsForReference`, `stockFromMovements(productId)` (SUM of
  `qty_change_base` — source of truth).
- `SalesRepository` / `PurchaseRepository`: `insertInvoice(db, invoice,
  items)` ⚠ service-only, `findByIdempotencyKey`, `findByInvoiceNo`,
  `getById`, `getItems`, `list({partyId, from, to, status, excludeDrafts,
  limit, offset})`, `updatePaid(db, id, paid, status)` ⚠, `updateStatus(db,
  id, status)` ⚠, `createDraft`, `updateDraft`, `deleteDraft`.
- `PaymentRepository`: `insert(db, payment)` ⚠, `findByIdempotencyKey`,
  `getById`, `list({partyType, partyId, accountId, from, to, limit, offset})`,
  `insertAllocation` ⚠, `allocationsForPayment`, `allocatedTotalForInvoice`.
- `ExpenseRepository`: `insert(db, entry)` ⚠, `list({from, to, categoryId,
  accountId, limit, offset})`, `getCategories`, `getCategoryById`,
  `insertCategory`, `setCategoryActive`.
- `IncomeRepository`: `insert(db, entry)` ⚠, `list({from, to, accountId,
  limit, offset})`.
- `CashAccountRepository`: `insert`, `getById`, `getAll({activeOnly})`,
  `update` (never touches balance), `setActive`, `delete`,
  `adjustBalance(db, id, delta)` ⚠, `cachedBalance(id)`.
- `ProductionRepository`: `insertBatch(db, batch, inputs, outputs)` ⚠,
  `getBatch`, `getInputs`, `getOutputs`, `list({from, to, limit, offset})`,
  `updateYield(db, id, yieldPct)` ⚠.
- `ReturnRepository`: `insertSalesReturn` / `insertPurchaseReturn` ⚠,
  `getSalesReturn` / `getPurchaseReturn`, `findSalesReturnByIdempotencyKey` /
  `findPurchaseReturnByIdempotencyKey`, `getSalesReturnItems` /
  `getPurchaseReturnItems`, `listSalesReturns` / `listPurchaseReturns`,
  `totalReturnedForSalesInvoice` / `totalReturnedForPurchaseInvoice`.
- `ReportRepository(db, accountingService)`: `customerLedger`,
  `supplierLedger`, `cashBook` (→ `LedgerStatement`), `salesSummary(from,
  to)` / `purchaseSummary(from, to)` (→ `PeriodTotals`), `expensesByCategory`
  (→ `List<CategoryTotal>`), `otherIncomeTotal`, `profitLoss(from, to)` (→
  `ProfitLoss`, from the ledger), `stockReport`, `lowStockReport`.
- `DocumentNumberService`: prefixes `SI PI SR PR PMT PB LE`;
  `next(db, prefix, {padWidth: 6})` — **must be called inside the posting
  transaction** (it is; you don't call it directly).

⚠ = service-only: called by `AccountingService` inside its transaction.
UI code calling these directly bypasses ledger/balance/stock writes.

## Models (`lib/models/`, pure Dart — no Flutter imports)

Immutable, `fromMap`/`toMap`/`copyWith`. Dates ↔ epoch-millis INTEGER.
Key fields per model (see source for the full field list):

| Model | Key fields |
|---|---|
| `Customer` | id, name, phone?, address?, code?, businessName?, notes?, openingBalancePaisa, **balancePaisa (cache)**, isArchived, createdAt, updatedAt |
| `Supplier` | same as Customer (payable semantics) |
| `Product` | id, name, sku?, category (`ProductCategory`: rawMaterial, finishedOil, oilCake, packaging, container, spare, consumable), baseUnitId, avgCostPaisa, defaultSalePricePaisa, **stockQty (cache, base unit, double)**, reorderLevelQty, isArchived |
| `Unit` | id, name, symbol |
| `UnitConversion` | id, fromUnitId, toUnitId, factor |
| `InventoryMovement` | id, date, productId, qtyChange (signed, original unit), qtyChangeBase (signed, base unit), unitId, movementType, referenceType?, referenceId?, notes? |
| `SalesInvoice` / `PurchaseInvoice` | id, invoiceNo, customerId/supplierId, date, status (`InvoiceStatus`: draft, unpaid, partial, paid, returned, cancelled), subtotalPaisa, discountPaisa, taxPaisa, totalPaisa, paidPaisa, idempotencyKey?, notes? |
| `SalesInvoiceItem` / `PurchaseInvoiceItem` | id, invoiceId?, productId, qty (double), unitId, unitPricePaisa, discountPercent, lineTotalPaisa |
| `Payment` | id, date, partyType (`customer`/`supplier`), partyId, amountPaisa, direction (`received`/`paid`), method (`cash`/`bank`), accountId, reference?, allocationJson?, idempotencyKey?, notes? |
| `PaymentAllocation` | id, paymentId?, invoiceType (`sale`/`purchase`), invoiceId, amountPaisa |
| `LedgerEntry` | id, entryNo, journalKey, date, accountType (`customer`/`supplier`/`cash`/`bank`/`expense`/`income`), accountId, debitPaisa, creditPaisa (exactly one > 0), category?, referenceType?, referenceId?, description?, reversedById? |
| `CashAccount` | id, name, type (`cash`/`bank`), openingBalancePaisa, **balancePaisa (cache)**, isActive |
| `AccountTransfer` | id, date, fromAccountId, toAccountId, amountPaisa, journalKey, notes? |
| `ExpenseEntry` | id, date, categoryId, amountPaisa, accountId, description?, reference?, journalKey |
| `IncomeEntry` | id, date, category?, amountPaisa, accountId, description?, reference?, journalKey |
| `ExpenseCategory` | id, name, isActive |
| `ProductionBatch` | id, batchNo, date, notes?, labourCostPaisa, electricityCostPaisa, otherCostPaisa, yieldPct?, journalKey? |
| `ProductionInput` / `ProductionOutput` | id, batchId?, productId, qty, unitId (+ outputType: finishedOil/oilCake/byProduct) |
| `SalesReturn` / `PurchaseReturn` | id, returnNo, date, invoiceId?, customerId/supplierId, subtotal/discount/tax/total paisa, reason?, idempotencyKey?, journalKey |
| `SalesReturnItem` / `PurchaseReturnItem` | id, returnId?, productId, qty, unitId, unitPricePaisa, lineTotalPaisa |
| `DocumentSequence` | prefix, lastNumber |

## Usage examples

### 1. Post a sale (validates stock, updates everything atomically)

```dart
final accounting = await ref.watch(accountingServiceProvider.future);

final invoice = await accounting.postSale(
  customerId: 3,
  date: DateTime.now(),
  lines: [
    SaleLineInput(productId: 7, qty: 2.5, unitId: 1 /* kg */,
        unitPricePaisa: 45000, discountPercent: 5),   // Rs 450/kg, 5% off
  ],
  discountPercent: 0,
  taxPaisa: 0,
  idempotencyKey: newIdempotencyKey(),   // safe retry
);
// invoice.invoiceNo == 'SI-000001', invoice.status == InvoiceStatus.unpaid
// Customer balance, stock, ledger all updated in one transaction.
```

### 2. Record a payment against invoices

```dart
final payment = await accounting.postCustomerPayment(
  customerId: 3,
  accountId: 1,                       // the seeded "Cash" account
  amountPaisa: parsePkrToPaisa('10,000'),
  date: DateTime.now(),
  allocations: [
    PaymentAllocationInput(invoiceId: invoice.id!, amountPaisa: parsePkrToPaisa('10,000')),
  ],
  idempotencyKey: newIdempotencyKey(),
);
// Invoice paidPaisa/status updated; customer + cash balances updated.
```

### 3. Read a customer ledger with running balance

```dart
final report = await ref.watch(reportRepositoryProvider.future);
final statement = await report.customerLedger(3,
    from: DateTime(2026, 10, 1), to: DateTime(2026, 11, 1));

print('Opening: ${formatPkr(statement.openingBalancePaisa)}');
for (final line in statement.lines) {
  print('${line.entry.date}  ${line.entry.description}  '
      'D ${formatPkr(line.entry.debitPaisa)}  C ${formatPkr(line.entry.creditPaisa)}  '
      'Bal ${formatPkr(line.runningBalancePaisa)}');
}
print('Closing: ${formatPkr(statement.closingBalancePaisa)}');
```

## Other notes for Wave 2

- `DatabaseHelper.transaction((txn) async { … })` is available for custom
  multi-write flows, but prefer adding a method to `AccountingService` so the
  ledger stays the single authority.
- Document numbers (`SI-000001`, …) are generated inside postings; drafts
  reserve their number at creation. Gaps after rollbacks are by design.
- `verifyBalances()` should back a "Data health" screen/diagnostic — an empty
  list means caches agree with the ledger.
- Seeded on first open: units (kg/maund/ton/litre/bag/piece), conversions
  (maund→kg 40, ton→kg 1000 — **litre↔kg intentionally absent**), 9 expense
  categories, one active `Cash` account. No demo customers/transactions.
