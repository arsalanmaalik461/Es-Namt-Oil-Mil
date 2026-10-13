# L10n Fragment Contract — for module agents C, D, E, F

Base ARB files (`lib/l10n/app_en.arb`, `lib/l10n/app_ur.arb`) are owned by
**Agent A**. To add feature strings, do NOT edit the base ARB files.
Instead, add **fragment files** in this directory:

```
lib/l10n/fragments/
  <module>_en.json     e.g. customers_en.json
  <module>_ur.json     e.g. customers_ur.json
```

## Rules

1. **Flat JSON only.** `{"module_keyName": "value"}` — no nesting.
2. **Key naming:** lowerCamelCase, always prefixed with your module name,
   e.g. `customers_title`, `sales_invoiceNo`, `reports_profitLoss`.
   This avoids collisions between modules.
3. **Placeholders:** use `{name}` style, e.g. `"sales_totalPaid": "Paid {amount}"`.
   If a value has placeholders, also add a metadata entry:
   `"@sales_totalPaid": {"placeholders": {"amount": {"type": "String"}}}`
   (types: `String`, `int`, `double`, `DateTime`, `num`).
4. **No plurals inside JSON.** Need singular/plural? Use two keys:
   `inventory_itemOne`, `inventory_itemMany`. Let the Dart code pick.
5. **Urdu is proper script + RTL-safe.** Write full Urdu (e.g. "گاہک"),
   never Roman Urdu. Numbers/dates stay LTR automatically.
6. **Zero hardcoded UI strings.** Every visible string in your widgets must
   come from `AppLocalizations` (import
   `package:namt_oil_mil/l10n/gen/app_localizations.dart`).
7. **Both locales required.** Every key in `<module>_en.json` must exist in
   `<module>_ur.json`.

## Merge process

Before a release/QA build, Agent A (or the orchestrator) merges all
fragments into `app_en.arb` / `app_ur.arb` (keys sorted, `@` metadata kept),
then runs `flutter gen-l10n`. Generated code lands in `lib/l10n/gen/`
(synthetic-package: false) — never edit it by hand.

## Module → fragment file map

| Agent | Module              | Fragment files                  |
|-------|---------------------|---------------------------------|
| C     | Customers/suppliers | `customers_en.json / _ur.json`  |
| C     | Khata hub           | `khata_en.json / _ur.json`      |
| D     | Sales/purchases     | `sales_en.json / _ur.json`, `purchases_en.json / _ur.json` |
| D     | Transactions        | `transactions_en.json / _ur.json` |
| E     | Inventory/production| `inventory_en.json / _ur.json`, `production_en.json / _ur.json` |
| E     | Cashbook/expenses   | `cashbook_en.json / _ur.json`, `expenses_en.json / _ur.json` |
| F     | Reports/PDF/backup  | `reports_en.json / _ur.json`, `backup_en.json / _ur.json` |
