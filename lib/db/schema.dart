/// SQLite DDL for the Namt Oil Mil database (pure Dart, no Flutter imports).
///
/// Conventions:
/// * Every money column is `INTEGER` storing **paisa** and is named `*_paisa`.
/// * Quantities are `REAL` in the row's own unit; never money.
/// * Dates are `INTEGER` milliseconds-since-epoch (index-friendly).
/// * Booleans are `INTEGER` 0/1.
/// * Every FK column and every date column has an index (see
///   [createIndexStatements]).
/// * Referenced business records use `ON DELETE RESTRICT`; child line items
///   use `ON DELETE CASCADE`.
///
/// Migrations are additive-only: `onUpgrade` never drops user tables.
abstract final class Schema {
  static const List<String> createTableStatements = [
    // ---------------------------------------------------------------- units
    '''
CREATE TABLE units(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  symbol TEXT NOT NULL UNIQUE
)''',
    '''
CREATE TABLE unit_conversions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_unit_id INTEGER NOT NULL,
  to_unit_id INTEGER NOT NULL,
  factor REAL NOT NULL CHECK(factor > 0),
  UNIQUE(from_unit_id, to_unit_id),
  CHECK(from_unit_id != to_unit_id),
  FOREIGN KEY(from_unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  FOREIGN KEY(to_unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------------------ parties
    '''
CREATE TABLE customers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  code TEXT UNIQUE,
  business_name TEXT,
  notes TEXT,
  opening_balance_paisa INTEGER NOT NULL DEFAULT 0,
  balance_paisa INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER,
  updated_at INTEGER
)''',
    '''
CREATE TABLE suppliers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  code TEXT UNIQUE,
  business_name TEXT,
  notes TEXT,
  opening_balance_paisa INTEGER NOT NULL DEFAULT 0,
  balance_paisa INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER,
  updated_at INTEGER
)''',
    // ------------------------------------------------------------ products
    '''
CREATE TABLE products(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  sku TEXT,
  category TEXT NOT NULL,
  base_unit_id INTEGER NOT NULL,
  avg_cost_paisa INTEGER NOT NULL DEFAULT 0,
  default_sale_price_paisa INTEGER NOT NULL DEFAULT 0,
  stock_qty REAL NOT NULL DEFAULT 0,
  reorder_level_qty REAL NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER,
  updated_at INTEGER,
  FOREIGN KEY(base_unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE inventory_movements(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty_change REAL NOT NULL,
  qty_change_base REAL NOT NULL,
  unit_id INTEGER NOT NULL,
  movement_type TEXT NOT NULL,
  reference_type TEXT,
  reference_id INTEGER,
  notes TEXT,
  created_at INTEGER,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // ---------------------------------------------------------------- sales
    '''
CREATE TABLE sales_invoices(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_no TEXT NOT NULL UNIQUE,
  customer_id INTEGER NOT NULL,
  date INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK(status IN ('draft','unpaid','partial','paid','returned','cancelled')),
  subtotal_paisa INTEGER NOT NULL DEFAULT 0,
  discount_paisa INTEGER NOT NULL DEFAULT 0,
  tax_paisa INTEGER NOT NULL DEFAULT 0,
  total_paisa INTEGER NOT NULL DEFAULT 0,
  paid_paisa INTEGER NOT NULL DEFAULT 0,
  idempotency_key TEXT UNIQUE,
  notes TEXT,
  created_at INTEGER,
  updated_at INTEGER,
  FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE sales_invoice_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  unit_price_paisa INTEGER NOT NULL CHECK(unit_price_paisa >= 0),
  discount_percent REAL NOT NULL DEFAULT 0,
  line_total_paisa INTEGER NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES sales_invoices(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------------------- purchases
    '''
CREATE TABLE purchase_invoices(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_no TEXT NOT NULL UNIQUE,
  supplier_id INTEGER NOT NULL,
  date INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK(status IN ('draft','unpaid','partial','paid','returned','cancelled')),
  subtotal_paisa INTEGER NOT NULL DEFAULT 0,
  discount_paisa INTEGER NOT NULL DEFAULT 0,
  tax_paisa INTEGER NOT NULL DEFAULT 0,
  total_paisa INTEGER NOT NULL DEFAULT 0,
  paid_paisa INTEGER NOT NULL DEFAULT 0,
  idempotency_key TEXT UNIQUE,
  notes TEXT,
  created_at INTEGER,
  updated_at INTEGER,
  FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE purchase_invoice_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  unit_price_paisa INTEGER NOT NULL CHECK(unit_price_paisa >= 0),
  discount_percent REAL NOT NULL DEFAULT 0,
  line_total_paisa INTEGER NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES purchase_invoices(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------------------- payments
    '''
CREATE TABLE cash_accounts(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK(type IN ('cash','bank')),
  opening_balance_paisa INTEGER NOT NULL DEFAULT 0,
  balance_paisa INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER,
  updated_at INTEGER
)''',
    '''
CREATE TABLE payments(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  party_type TEXT NOT NULL CHECK(party_type IN ('customer','supplier')),
  party_id INTEGER NOT NULL,
  amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
  direction TEXT NOT NULL CHECK(direction IN ('received','paid')),
  method TEXT NOT NULL CHECK(method IN ('cash','bank')),
  account_id INTEGER NOT NULL,
  reference TEXT,
  allocation_json TEXT,
  idempotency_key TEXT UNIQUE,
  notes TEXT,
  created_at INTEGER,
  FOREIGN KEY(account_id) REFERENCES cash_accounts(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE payment_allocations(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_id INTEGER NOT NULL,
  invoice_type TEXT NOT NULL CHECK(invoice_type IN ('sale','purchase')),
  invoice_id INTEGER NOT NULL,
  amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
  FOREIGN KEY(payment_id) REFERENCES payments(id) ON DELETE CASCADE
)''',
    '''
CREATE TABLE account_transfers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  from_account_id INTEGER NOT NULL,
  to_account_id INTEGER NOT NULL,
  amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
  journal_key TEXT NOT NULL,
  notes TEXT,
  created_at INTEGER,
  CHECK(from_account_id != to_account_id),
  FOREIGN KEY(from_account_id) REFERENCES cash_accounts(id) ON DELETE RESTRICT,
  FOREIGN KEY(to_account_id) REFERENCES cash_accounts(id) ON DELETE RESTRICT
)''',
    // ---------------------------------------------------------------- ledger
    '''
CREATE TABLE ledger_entries(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_no TEXT NOT NULL UNIQUE,
  journal_key TEXT NOT NULL,
  date INTEGER NOT NULL,
  account_type TEXT NOT NULL
    CHECK(account_type IN ('customer','supplier','cash','bank','expense','income')),
  account_id INTEGER NOT NULL,
  debit_paisa INTEGER NOT NULL DEFAULT 0 CHECK(debit_paisa >= 0),
  credit_paisa INTEGER NOT NULL DEFAULT 0 CHECK(credit_paisa >= 0),
  category TEXT,
  reference_type TEXT,
  reference_id INTEGER,
  description TEXT,
  reversed_by_id INTEGER,
  idempotency_key TEXT UNIQUE,
  created_at INTEGER,
  CHECK(debit_paisa + credit_paisa > 0),
  CHECK(debit_paisa = 0 OR credit_paisa = 0),
  FOREIGN KEY(reversed_by_id) REFERENCES ledger_entries(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------------ expenses/income
    '''
CREATE TABLE expense_categories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  is_active INTEGER NOT NULL DEFAULT 1
)''',
    '''
CREATE TABLE expenses(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
  account_id INTEGER NOT NULL,
  description TEXT,
  reference TEXT,
  journal_key TEXT NOT NULL,
  created_at INTEGER,
  FOREIGN KEY(category_id) REFERENCES expense_categories(id) ON DELETE RESTRICT,
  FOREIGN KEY(account_id) REFERENCES cash_accounts(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE income_entries(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  category TEXT,
  amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
  account_id INTEGER NOT NULL,
  description TEXT,
  reference TEXT,
  journal_key TEXT NOT NULL,
  created_at INTEGER,
  FOREIGN KEY(account_id) REFERENCES cash_accounts(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------------------ production
    '''
CREATE TABLE production_batches(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_no TEXT NOT NULL UNIQUE,
  date INTEGER NOT NULL,
  notes TEXT,
  labour_cost_paisa INTEGER NOT NULL DEFAULT 0,
  electricity_cost_paisa INTEGER NOT NULL DEFAULT 0,
  other_cost_paisa INTEGER NOT NULL DEFAULT 0,
  yield_pct REAL,
  journal_key TEXT,
  created_at INTEGER
)''',
    '''
CREATE TABLE production_inputs(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  FOREIGN KEY(batch_id) REFERENCES production_batches(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE production_outputs(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  output_type TEXT NOT NULL
    CHECK(output_type IN ('finished_oil','oil_cake','by_product')),
  FOREIGN KEY(batch_id) REFERENCES production_batches(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // --------------------------------------------------------------- returns
    '''
CREATE TABLE sales_returns(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  return_no TEXT NOT NULL UNIQUE,
  date INTEGER NOT NULL,
  invoice_id INTEGER,
  customer_id INTEGER NOT NULL,
  subtotal_paisa INTEGER NOT NULL DEFAULT 0,
  discount_paisa INTEGER NOT NULL DEFAULT 0,
  tax_paisa INTEGER NOT NULL DEFAULT 0,
  total_paisa INTEGER NOT NULL DEFAULT 0,
  reason TEXT,
  idempotency_key TEXT UNIQUE,
  journal_key TEXT NOT NULL,
  created_at INTEGER,
  FOREIGN KEY(invoice_id) REFERENCES sales_invoices(id) ON DELETE RESTRICT,
  FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE sales_return_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  return_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  unit_price_paisa INTEGER NOT NULL CHECK(unit_price_paisa >= 0),
  line_total_paisa INTEGER NOT NULL,
  FOREIGN KEY(return_id) REFERENCES sales_returns(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE purchase_returns(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  return_no TEXT NOT NULL UNIQUE,
  date INTEGER NOT NULL,
  invoice_id INTEGER,
  supplier_id INTEGER NOT NULL,
  subtotal_paisa INTEGER NOT NULL DEFAULT 0,
  discount_paisa INTEGER NOT NULL DEFAULT 0,
  tax_paisa INTEGER NOT NULL DEFAULT 0,
  total_paisa INTEGER NOT NULL DEFAULT 0,
  reason TEXT,
  idempotency_key TEXT UNIQUE,
  journal_key TEXT NOT NULL,
  created_at INTEGER,
  FOREIGN KEY(invoice_id) REFERENCES purchase_invoices(id) ON DELETE RESTRICT,
  FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
)''',
    '''
CREATE TABLE purchase_return_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  return_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  qty REAL NOT NULL CHECK(qty > 0),
  unit_id INTEGER NOT NULL,
  unit_price_paisa INTEGER NOT NULL CHECK(unit_price_paisa >= 0),
  line_total_paisa INTEGER NOT NULL,
  FOREIGN KEY(return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT
)''',
    // ------------------------------------------------- sequences + audit log
    '''
CREATE TABLE document_sequences(
  prefix TEXT PRIMARY KEY,
  last_number INTEGER NOT NULL DEFAULT 0
)''',
    '''
CREATE TABLE audit_log(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  details TEXT
)''',
  ];

  /// One index per FK column and per date column, plus lookup helpers.
  static const List<String> createIndexStatements = [
    // units
    'CREATE INDEX idx_conversions_from ON unit_conversions(from_unit_id)',
    'CREATE INDEX idx_conversions_to ON unit_conversions(to_unit_id)',
    // parties
    'CREATE INDEX idx_customers_name ON customers(name)',
    'CREATE INDEX idx_customers_code ON customers(code)',
    'CREATE INDEX idx_suppliers_name ON suppliers(name)',
    'CREATE INDEX idx_suppliers_code ON suppliers(code)',
    // products + movements
    'CREATE INDEX idx_products_name ON products(name)',
    'CREATE INDEX idx_products_category ON products(category)',
    'CREATE INDEX idx_products_base_unit ON products(base_unit_id)',
    'CREATE INDEX idx_movements_product ON inventory_movements(product_id)',
    'CREATE INDEX idx_movements_date ON inventory_movements(date)',
    'CREATE INDEX idx_movements_ref ON inventory_movements(reference_type, reference_id)',
    'CREATE INDEX idx_movements_unit ON inventory_movements(unit_id)',
    // sales
    'CREATE INDEX idx_sales_customer ON sales_invoices(customer_id)',
    'CREATE INDEX idx_sales_date ON sales_invoices(date)',
    'CREATE INDEX idx_sales_status ON sales_invoices(status)',
    'CREATE INDEX idx_sii_invoice ON sales_invoice_items(invoice_id)',
    'CREATE INDEX idx_sii_product ON sales_invoice_items(product_id)',
    'CREATE INDEX idx_sii_unit ON sales_invoice_items(unit_id)',
    // purchases
    'CREATE INDEX idx_purchases_supplier ON purchase_invoices(supplier_id)',
    'CREATE INDEX idx_purchases_date ON purchase_invoices(date)',
    'CREATE INDEX idx_purchases_status ON purchase_invoices(status)',
    'CREATE INDEX idx_pii_invoice ON purchase_invoice_items(invoice_id)',
    'CREATE INDEX idx_pii_product ON purchase_invoice_items(product_id)',
    'CREATE INDEX idx_pii_unit ON purchase_invoice_items(unit_id)',
    // payments + transfers
    'CREATE INDEX idx_payments_party ON payments(party_type, party_id)',
    'CREATE INDEX idx_payments_date ON payments(date)',
    'CREATE INDEX idx_payments_account ON payments(account_id)',
    'CREATE INDEX idx_alloc_payment ON payment_allocations(payment_id)',
    'CREATE INDEX idx_alloc_invoice ON payment_allocations(invoice_type, invoice_id)',
    'CREATE INDEX idx_transfers_date ON account_transfers(date)',
    'CREATE INDEX idx_transfers_from ON account_transfers(from_account_id)',
    'CREATE INDEX idx_transfers_to ON account_transfers(to_account_id)',
    // ledger
    'CREATE INDEX idx_ledger_account ON ledger_entries(account_type, account_id)',
    'CREATE INDEX idx_ledger_date ON ledger_entries(date)',
    'CREATE INDEX idx_ledger_journal ON ledger_entries(journal_key)',
    'CREATE INDEX idx_ledger_ref ON ledger_entries(reference_type, reference_id)',
    // expenses / income
    'CREATE INDEX idx_expenses_date ON expenses(date)',
    'CREATE INDEX idx_expenses_category ON expenses(category_id)',
    'CREATE INDEX idx_expenses_account ON expenses(account_id)',
    'CREATE INDEX idx_income_date ON income_entries(date)',
    'CREATE INDEX idx_income_account ON income_entries(account_id)',
    // production
    'CREATE INDEX idx_batches_date ON production_batches(date)',
    'CREATE INDEX idx_pinputs_batch ON production_inputs(batch_id)',
    'CREATE INDEX idx_pinputs_product ON production_inputs(product_id)',
    'CREATE INDEX idx_poutputs_batch ON production_outputs(batch_id)',
    'CREATE INDEX idx_poutputs_product ON production_outputs(product_id)',
    // returns
    'CREATE INDEX idx_sreturns_date ON sales_returns(date)',
    'CREATE INDEX idx_sreturns_customer ON sales_returns(customer_id)',
    'CREATE INDEX idx_sreturns_invoice ON sales_returns(invoice_id)',
    'CREATE INDEX idx_sreturn_items_return ON sales_return_items(return_id)',
    'CREATE INDEX idx_sreturn_items_product ON sales_return_items(product_id)',
    'CREATE INDEX idx_preturns_date ON purchase_returns(date)',
    'CREATE INDEX idx_preturns_supplier ON purchase_returns(supplier_id)',
    'CREATE INDEX idx_preturns_invoice ON purchase_returns(invoice_id)',
    'CREATE INDEX idx_preturn_items_return ON purchase_return_items(return_id)',
    'CREATE INDEX idx_preturn_items_product ON purchase_return_items(product_id)',
    // audit
    'CREATE INDEX idx_audit_entity ON audit_log(entity, entity_id)',
    'CREATE INDEX idx_audit_timestamp ON audit_log(timestamp)',
  ];

  /// All DDL in creation order (tables first, then indexes).
  static const List<String> allStatements = [
    ...createTableStatements,
    ...createIndexStatements,
  ];
}
