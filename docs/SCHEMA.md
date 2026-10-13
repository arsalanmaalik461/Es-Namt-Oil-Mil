# Namt Oil Mil — Database Schema (Module B)

SQLite database file: **`namt_oil_mil.db`** · current version: **1** · 27 tables.
100% offline (sqflite). `PRAGMA foreign_keys = ON` on every connection.

## Conventions

| Concern | Rule |
|---|---|
| Money | `INTEGER` paisa, column name `*_paisa`. **Never** REAL/double for money. |
| Quantities | `REAL` in the row's own unit (kg, maund, litre…). Never money. |
| Dates | `INTEGER` milliseconds-since-epoch (index-friendly, sortable). |
| Booleans | `INTEGER` 0/1. |
| Enums | `TEXT` with `CHECK … IN (…)` constraints. |
| FK deletes | `ON DELETE RESTRICT` for referenced business records (customer, supplier, product, unit, cash account); `ON DELETE CASCADE` for line items (invoice items, return items, production lines, payment allocations). |
| Indexes | Every FK column and every date column is indexed (see `Schema.createIndexStatements`). |
| Migrations | Additive only. `onUpgrade` never drops/renames user tables and never changes a money column's type. See "Migration policy". |
| Audit | Mutations write to `audit_log` inside the same transaction. |

## Balance semantics (single source of truth: `ledger_entries`)

`AccountingService.signedEffect` is the ONLY implementation of these formulas.
Cached `balance_paisa` columns are updated in the same transaction as the
ledger rows; `AccountingService.verifyBalances()` reconciles them.

| Account type | Balance formula | Meaning of positive |
|---|---|---|
| `customer` | Σ(debit) − Σ(credit) | customer **owes** the business (receivable) |
| `supplier` | Σ(credit) − Σ(debit) | business **owes** the supplier (payable) |
| `cash` / `bank` | Σ(debit) − Σ(credit) | on-hand money |
| `expense` | Σ(debit) − Σ(credit) | period expense (P&L, no cache) |
| `income` | Σ(credit) − Σ(debit) | period income (P&L, no cache) |

Negative customer balance = customer paid in advance. Negative supplier
balance = business paid the supplier in advance.

## Double-entry journal model

Every posting writes a **balanced journal**: 2+ `ledger_entries` rows sharing
one `journal_key` with Σ(debit) == Σ(credit) (validated in code; DB CHECKs
guarantee one-sided entries: exactly one of `debit_paisa`/`credit_paisa` > 0).

Entry numbers (`entry_no`, e.g. `LE-000042`) come from `document_sequences`.

**Immutability:** posted ledger rows are NEVER updated or deleted.
Corrections are new offsetting rows. A reversal row carries
`reversed_by_id` = the id of the original row it reverses (the original row
itself is untouched). `AccountingService.reverseEntry` reverses the *whole
journal* identified by an entry.

### Posting map (what each operation writes)

| Operation | Debit | Credit | Also writes |
|---|---|---|---|
| Sale | customer (total) | income:0 / `sales` (total) | invoice+items, stock-out movements, customer cache |
| Purchase | expense:0 / `purchase` (total) | supplier (total) | invoice+items, stock-in movements, avg-cost update, supplier cache |
| Customer payment | cash/bank (amount) | customer (amount) | payment+allocations, invoice paid/status, caches |
| Supplier payment | supplier (amount) | cash/bank (amount) | payment+allocations, invoice paid/status, caches |
| Expense | expense:category (amount) | cash/bank (amount) | expense row, cash cache |
| Other income | cash/bank (amount) | income:0 (amount) | income row, cash cache |
| Transfer | to-account (amount) | from-account (amount) | transfer row, both caches. Never income/expense. |
| Production | — (no ledger by default) | — | batch+lines, movements, stock, avg-cost, yield |
| Production (with `costCashAccountId`) | expense:0 / `production_*` (each cost) | cash/bank (sum) | as above + cost journal |
| Sales return | income:0 / `sales_returns` (total) | customer (total) | return+items, stock-in movements, customer cache, invoice status |
| Purchase return | supplier (total) | expense:0 / `purchase_returns` (total) | return+items, stock-out movements, supplier cache, invoice status |
| Stock adjustment | — (no ledger) | — | movement, stock cache |

Notes:
- `income:0` / `expense:0` are canonical accounts (no separate tables).
- Production posts **no cash-affecting ledger entries by default**: material
  cost was already expensed at purchase; labour/electricity cash outflow
  belongs in `postExpense` (or pass `costCashAccountId` to post them inline).
- Stock adjustments post no ledger entries (they are corrections, not trade).

## Quantity representation

Quantities are `REAL` **in the row's own unit**. `inventory_movements` stores
both `qty_change` (original unit) and `qty_change_base` (signed, in the
product's base unit). Aggregation and cache updates always use
`qty_change_base`. `products.stock_qty` is a cache in the base unit; the
movements table is the source of truth for history.

Conversions live in `unit_conversions` (`qty_in_to = qty_in_from × factor`);
reverse direction is derived as `1/factor`. Seeded: maund→kg **40.0**,
ton→kg **1000.0** (configurable, user-editable). **litre↔kg is deliberately
not seeded** — the factor depends on oil density and varies.

## Tables

### Reference data
- `units(id, name UNIQUE, symbol UNIQUE)` — seeded: kg, maund, ton, litre, bag, piece.
- `unit_conversions(id, from_unit_id→units, to_unit_id→units, factor REAL CHECK>0, UNIQUE(from,to), CHECK(from!=to))`.
- `expense_categories(id, name UNIQUE, is_active)` — seeded: electricity, labour, transport, rent, repairs, packaging, maintenance, admin, other.
- `document_sequences(prefix PK, last_number)` — counters for SI/PI/SR/PR/PMT/PB/LE.
- `audit_log(id, timestamp, action, entity, entity_id, details)`.

### Parties
- `customers` / `suppliers`: `id, name, phone?, address?, code? UNIQUE, business_name?, notes?, opening_balance_paisa, balance_paisa` (cache), `is_archived, created_at, updated_at`.

### Products & inventory
- `products(id, name, sku?, category, base_unit_id→units RESTRICT, avg_cost_paisa` (weighted moving avg per base unit)`, default_sale_price_paisa, stock_qty REAL` (cache, base unit)`, reorder_level_qty, is_archived, created_at, updated_at)`.
- `inventory_movements(id, date, product_id→products RESTRICT, qty_change REAL, qty_change_base REAL, unit_id→units RESTRICT, movement_type, reference_type?, reference_id?, notes?, created_at)`.

### Sales / purchases
- `sales_invoices(id, invoice_no UNIQUE, customer_id→customers RESTRICT, date, status CHECK(draft|unpaid|partial|paid|returned|cancelled), subtotal_paisa, discount_paisa, tax_paisa, total_paisa, paid_paisa, idempotency_key UNIQUE?, notes?, created_at, updated_at)`.
- `sales_invoice_items(id, invoice_id→sales_invoices CASCADE, product_id→products RESTRICT, qty REAL CHECK>0, unit_id→units RESTRICT, unit_price_paisa, discount_percent REAL, line_total_paisa)`.
- `purchase_invoices` / `purchase_invoice_items` — mirror with `supplier_id→suppliers`.

### Payments & cash
- `cash_accounts(id, name UNIQUE, type CHECK(cash|bank), opening_balance_paisa, balance_paisa` (cache)`, is_active, created_at, updated_at)` — seeded with one active `Cash` account.
- `payments(id, date, party_type CHECK(customer|supplier), party_id` (polymorphic — enforced in app code, not FK)`, amount_paisa CHECK>0, direction CHECK(received|paid), method CHECK(cash|bank), account_id→cash_accounts RESTRICT, reference?, allocation_json?, idempotency_key UNIQUE?, notes?, created_at)`.
- `payment_allocations(id, payment_id→payments CASCADE, invoice_type CHECK(sale|purchase), invoice_id, amount_paisa CHECK>0)`.
- `account_transfers(id, date, from_account_id→cash_accounts RESTRICT, to_account_id→cash_accounts RESTRICT, amount_paisa CHECK>0, journal_key, notes?, created_at, CHECK(from!=to))`.

### Ledger
- `ledger_entries(id, entry_no UNIQUE, journal_key, date, account_type CHECK(customer|supplier|cash|bank|expense|income), account_id, debit_paisa CHECK>=0, credit_paisa CHECK>=0, category?, reference_type?, reference_id?, description?, reversed_by_id→ledger_entries RESTRICT?, created_at, CHECK(debit+credit>0), CHECK(debit=0 OR credit=0))`.

### Expenses / income
- `expenses(id, date, category_id→expense_categories RESTRICT, amount_paisa CHECK>0, account_id→cash_accounts RESTRICT, description?, reference?, journal_key, created_at)`.
- `income_entries(id, date, category?, amount_paisa CHECK>0, account_id→cash_accounts RESTRICT, description?, reference?, journal_key, created_at)`.

### Production
- `production_batches(id, batch_no UNIQUE, date, notes?, labour_cost_paisa, electricity_cost_paisa, other_cost_paisa, yield_pct REAL?, journal_key?, created_at)`.
- `production_inputs(id, batch_id→production_batches CASCADE, product_id→products RESTRICT, qty REAL CHECK>0, unit_id→units RESTRICT)`.
- `production_outputs(id, batch_id CASCADE, product_id RESTRICT, qty REAL CHECK>0, unit_id RESTRICT, output_type CHECK(finished_oil|oil_cake|by_product))`.

### Returns
- `sales_returns(id, return_no UNIQUE, date, invoice_id?→sales_invoices RESTRICT, customer_id→customers RESTRICT, subtotal/discount/tax/total_paisa, reason?, idempotency_key UNIQUE?, journal_key, created_at)` + `sales_return_items(id, return_id CASCADE, product_id RESTRICT, qty CHECK>0, unit_id RESTRICT, unit_price_paisa, line_total_paisa)`.
- `purchase_returns` + `purchase_return_items` — mirror with `supplier_id→suppliers`.

## Migration policy

- `DatabaseHelper.dbVersion` starts at **1** (baseline = full `onCreate`).
- Each future schema change adds its DDL strings to `DatabaseHelper.migrations[targetVersion]`; `onUpgrade` applies them in version order inside the open.
- **Additive only**: new tables/columns/indexes. Never `DROP` a user table, never rename a column in an upgrade, never change a money column's type. New `NOT NULL` columns must have a `DEFAULT` (or be backfilled) so existing rows stay valid.
- Destructive operations (wipe/reset) are never performed automatically; backup/restore is a user-initiated feature owned by a later module.

## Seed data (first open only)

Units (kg, maund, ton, litre, bag, piece), conversions (maund→kg 40.0,
ton→kg 1000.0), 9 expense categories, one active `Cash` account.
**No** customers, suppliers, products, invoices, payments or ledger rows are
seeded — the app starts with a genuinely empty ledger.
