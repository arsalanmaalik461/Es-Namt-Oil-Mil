# Namt Oil Mil — Digital Khata + Oil-Mill Accounts

**Namt Oil Mil** is a 100% offline-first Flutter app for running an oil mill's
books: customer/supplier khata (udhaar), sales & purchase invoices, inventory
(raw seed, finished oil, oil cake, packaging), production batches with yield
calculation, expenses/income, cash & bank accounts, 27 reports, PDF invoices /
receipts / statements (English + Urdu), payment reminders, and local
backup/restore. No internet, no cloud, no account needed — your data never
leaves the device.

- App name: **Namt Oil Mil** · package `namt_oil_mil` · Android
  `com.namtoilmil.app`
- Default currency: **Pakistani Rupee (PKR)** — all money is stored as integer
  **paisa** (1 Rs = 100 paisa); doubles are never used for money.
- Languages: **English + اردو (Urdu)** with full RTL layout.

## Quick start

Prerequisites: Flutter SDK 3.47+ (Dart 3.13+). This repo was built with the
SDK at `~/workspace/tools/flutter`.

```bash
cd namat_khata
flutter pub get --offline     # IMPORTANT: always --offline; online hangs
flutter run
```

> **Toolchain note (this build environment):** Dart's HTTP client cannot reach
> pub.dev through the sandbox egress proxy, so every `flutter`/`dart` command
> must pass `--offline` (online `pub get` hangs forever). Missing packages are
> fetched with a curl-based script into `~/.pub-cache`, after which `--offline`
> resolves them. Always run flutter commands as
> `CI=true timeout <N> flutter <cmd>`.

## Run the tests

```bash
cd namat_khata
CI=true timeout 900 flutter test
```

Test suites:

| File | What it covers |
|---|---|
| `test/unit/money_test.dart` | `formatPkr` / `parsePkrToPaisa` / `percentOf` (half-up) / `applyDiscount` / `lineTotalPaisa` / `weightedAverageCostPaisa` |
| `test/unit/accounting_math_test.dart` | Discounts, taxes, partial payments + status walk, opening balances, running balances, receivables/payables, transfers excluded from income/expense, unit conversions, stock movements, yield %, P&L math, udhaar posting |
| `test/db/database_test.dart` | CRUD, failed-transaction rollback, FK RESTRICT on customer delete, idempotent re-post, backup export→import round-trip, invalid-backup rejection (uses `sqflite_common_ffi`, in-memory-friendly) |
| `test/integration/workflows_test.dart` | Master workflows A–F: customer credit lifecycle, supplier credit lifecycle, production batch, cashbook reconcile, backup/restore, udhaar |
| `test/widget/smoke_test.dart` | App boots, all 5 bottom-nav tabs reachable, customer form rejects empty name, amount validator rejects 0/garbage, EN→UR gives RTL, dark theme applies |

Analyze & format:

```bash
CI=true timeout 300 dart format lib test
CI=true timeout 600 flutter analyze   # expect ZERO errors
```

## Build the APK

Requires JDK 17 and the Android SDK (one-time setup):

```bash
export JAVA_HOME=~/workspace/tools/jdk17
export ANDROID_HOME=~/workspace/tools/android-sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

cd namat_khata
CI=true timeout 1800 flutter build apk --debug
# -> build/app/outputs/flutter-apk/app-debug.apk
```

For a release APK: `flutter build apk --release` (signing config lives in
`android/app/build.gradle.kts` — add your keystore before publishing).

## Architecture

```
lib/
  main.dart / app.dart        — entry, MaterialApp (l10n, theme, router)
  models/                     — 19 pure-Dart immutable models (fromMap/toMap)
  db/                         — DatabaseHelper (singleton, FK pragma, migrations),
                                schema.dart (27 tables, 59 indexes), audit_log.dart
  repositories/               — 16 CRUD-only repositories (never compute balances)
  services/
    accounting_service.dart   — THE ledger authority (~2900 lines). Every
                                balance-affecting write goes through here as ONE
                                atomic SQLite transaction: journal entries +
                                balance caches + stock + documents.
    backup_service.dart       — versioned JSON export/import with checksums
    pdf/                      — PDF builders (DB-free, testable)
  providers/                  — Riverpod: db_providers (18), settings (locale/
                                theme/business profile, SharedPreferences)
  screens/                    — dashboard, khata, sales, purchases, inventory,
                                production, cashbook, expenses, transactions,
                                reports, backup, settings
  l10n/                       — app_en.arb / app_ur.arb (675 keys, parity-checked);
                                feature strings arrive via lib/l10n/fragments/
  utils/                      — money.dart (int-paisa contract), time, keys, qty
```

### The one rule

**UI code must call `AccountingService` for anything that affects a balance**
— sales, purchases, payments, udhaar, expenses, income, transfers, production,
returns, stock adjustments. Repositories are CRUD-only. Screens never compute
balances ad hoc. All balance formulas live in exactly one place:
`AccountingService.signedEffect`, exposed via `getCustomerBalancePaisa` /
`getSupplierBalancePaisa` / `getAccountBalancePaisa` /
`ledgerWithRunningBalance`.

Balance semantics:

- customer balance > 0 → customer owes the business (receivable / udhaar)
- supplier balance > 0 → business owes the supplier (payable)
- cash/bank balance → on-hand amount
- "Give Udhaar" posts **Dr Customer / Cr Cash|Bank** (`category: 'udhaar'`) —
  it is a cash advance, *not* a goods sale

Data integrity:

- Foreign keys `ON DELETE RESTRICT` on business records (a customer with
  invoices cannot be deleted), `CASCADE` on line items
- Balance caches (`balance_paisa`, stock, avg cost) are updated in the same
  transaction as the journal; `verifyBalances()` reconciles cache vs ledger
- Postings are idempotent via `idempotencyKey` — safe to retry
- Every write is audit-logged (`audit_log` table)

## Limitations (honest)

- **Urdu in PDFs is limited:** the `pdf` package sets RTL direction, but
  Arabic-script shaping and Urdu glyph coverage are limited — Urdu text in
  PDFs renders as-is (unshaped). On-screen Urdu (Flutter) renders correctly
  with full RTL.
- **100% offline by design:** no cloud sync, no Firebase, no backend. There is
  nothing to sign into and nothing is uploaded — ever.
- **Backups are local files:** a backup JSON lives on the device. **It does
  not survive an app uninstall** unless you copy the file elsewhere first.
- **Web/desktop were not built in this pass** (Android APK is the target).
- Production posts no cash ledger entries by default (raw material was already
  expensed at purchase); pass a cost cash account to post labour/electricity
  cash outflows inline.
- litre↔kg conversion is deliberately unseeded (oil density varies); add your
  own factor under Inventory → Units.
- Reversals correct ledger + caches only; invoice status/stock are untouched
  (use returns for those).

## خلاصہ (اردو)

**نعمت آئل مل** آپ کے آئل مل کا مکمل ڈیجیٹل کھاتہ ہے — سو فیصد آف لائن۔
گاہکوں اور سپلائرز کا ادھار، سیل اور خریداری کی رسیدیں، اسٹاک (سرسوں/تیل/کھل)،
پیداوار کی لاگت اور اوسط، اخراجات و آمدنی، کیش و بینک کھاتے، 27 رپورٹیں، اردو
اور انگریزی میں PDF رسیدیں، ادائیگی کی یاد دہانیاں، اور مقامی بیک اپ —
سب کچھ آپ کے اپنے موبائل میں، انٹرنیٹ کے بغیر۔

---

*Built with Flutter · SQLite (sqflite) · Riverpod · pdf/printing · intl*
