# Namt Oil Mil

**100% offline digital khata + full accounts for a Pakistani oil mill.**
No internet, no cloud, no Firebase, no account — your data never leaves the device.

App name: **Namt Oil Mil** · package `namt_oil_mil` · Android `com.namtoilmil.app`
Default currency: **Pakistani Rupee (PKR)** — all money is stored as integer **paisa** (1 Rs = 100 paisa); doubles are never used for money.

## Features

- **Dashboard** — receivables / payables, today's sales, purchases, cash received / paid, cash + bank balances, monthly income / expense, low-stock alerts, recent transactions, quick actions.
- **Khata (customers & suppliers)** — party lists, per-party ledgers with running balances, opening balances, payments with invoice allocation, copyable payment-reminder messages.
- **Sales & purchases** — draft → posted invoicing with line items, discounts, tax %, paid-now, unique invoice numbers, and full **returns** (sales returns / purchase returns).
- **Inventory** — products in configurable units (kg, maund, ton, litre, bag, piece); conversion factors are user-editable; litre↔kg is deliberately unseeded (oil density varies — set your own factor under Inventory → Units); stock in / out / adjust, weighted-average cost, reorder levels.
- **Production** — batches with input materials, outputs (finished oil / oil cake / by-product), wastage, labour / electricity / other costs, and **yield %** calculation; batch numbers auto-assigned.
- **Cashbook + bank** — multiple cash / bank accounts, receipts, payments, account-to-account transfers (never mis-posted as income / expense), per-account ledgers.
- **Expenses & income** — 9 seeded expense categories plus custom ones; today / month / year summaries.
- **27 reports** — trial balance, daybook, P&L (carries an "estimated" disclaimer), party statements, stock, cash / bank, and more; date / month filters and drill-downs.
- **PDF documents (EN / UR)** — sale invoices, purchase vouchers, payment receipts, supplier payment vouchers, customer / supplier statements, cash receipts, expense vouchers, production reports — preview, save, share, print.
- **Local backup / restore** — versioned JSON export with checksums; import is validated and restored transactionally behind an explicit danger-confirm.
- **EN + UR (RTL) UI** — full bilingual interface with proper Urdu script and RTL layout, switchable in settings.

## Architecture

```
lib/
├── presentation   screens/ + widgets/     (UI — never computes balances)
├── providers/     Riverpod providers       (state plumbing)
├── services/     AccountingService        (SOLE owner of all balance math)
│                 pdf/ PdfService          (DB-free, testable document builder)
├── repositories/ 16 repos                 (CRUD only; no business logic)
├── db/           sqflite schema — 27 tables, FKs ON, additive migrations
├── models/       19 pure-Dart models
└── l10n/         EN + UR strings (ARB), RTL direction
```

The rules the codebase enforces:

- **Single ledger authority** — every balance-affecting write goes through `AccountingService`, which posts balanced double-entry journals (`ledger_entries`, Σ debit == Σ credit). Posted rows are immutable; corrections are offsetting rows. All balance formulas live in exactly one place: `AccountingService.signedEffect`. Balance caches are updated in the same transaction; `verifyBalances()` reconciles cache vs ledger.
- **Money is integer paisa** — DB columns are `*_paisa INTEGER`.
- **Zero network dependencies** — `pubspec.yaml` is locked down; every dependency works fully offline. No Firebase, no analytics, no tracking.
- **sqflite with additive migrations** — `namt_oil_mil.db`, version 1. Migrations never drop/rename user tables or change a money column's type.

## Run

Requires the Flutter SDK (built with 3.47.7 / Dart 3.13.5). Always use `--offline` — online `pub get` cannot reach pub.dev through a proxied environment and hangs; with a warm pub cache, offline resolves everything.

```bash
cd namat_khata
flutter pub get --offline
flutter run
```

## Build the APK

One-time: install **JDK 17** and the Android SDK **command-line tools**, then install the platform + build-tools via `sdkmanager`. Then:

```bash
cd namat_khata
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

The debug APK is unsigned — installs fine directly on a phone, but it cannot be uploaded to the Play Store. A signed release build is a separate step.

## Run the tests

```bash
cd namat_khata
flutter test
```

Unit tests (money math, balance formulas, idempotency), DB integration tests via `sqflite_common_ffi` (posting flows, allocations, returns, balance reconciliation, backup round-trip), and widget smoke tests.

## اردو خلاصہ

**نعمت آئل مل** آپ کے آئل مل کا مکمل ڈیجیٹل کھاتہ ہے — سو فیصد آف لائن۔
گاہکوں اور سپلائرز کا ادھار، سیل اور خریداری کی رسیدیں، اسٹاک (کلوگرام، من، ٹن، لیٹر)،
پیداوار کے بیچ (ییلڈ فیصد کے ساتھ)، نقد رقم و بینک کھاتے، اخراجات و آمدنی،
27 رپورٹیں، اردو اور انگریزی میں PDF دستاویزات، اور مقامی بیک اپ —
سب کچھ آپ کے اپنے موبائل میں، انٹرنیٹ کے بغیر۔
ڈیٹا کا بیک اپ کہیں اور محفوظ رکھیں، کیونکہ ایپ ڈیلیٹ ہونے پر ڈیٹا ضائع ہو جائے گا۔

## Honest limitations

- **Urdu shaping in generated PDFs is limited.** The PDF engine applies RTL direction, but Arabic-script glyph shaping and full Urdu glyph coverage are limited — Urdu text renders as-is and may not look as polished as the on-screen UI. On-screen Urdu (Flutter) renders correctly with full RTL. English PDFs are unaffected.
- **Web/desktop not built in this pass.** The codebase is plain Flutter and platform-agnostic, but this build and its QA targeted **Android**.
- **No cloud sync or Firebase — by design.** A deliberate choice for a business that cannot rely on connectivity. Nothing is uploaded, ever.
- **A local backup file does not survive app uninstall.** The backup JSON lives wherever *you* save or share it. Keep copies on a second device, a drive, or your laptop.
- **The debug APK is unsigned.** Fine for direct install; not for the Play Store.
- **P&L carries an "estimated" disclaimer** — it reflects ledger postings, not audited accounts.
- Draft invoices reserve real invoice numbers at creation, so deleting a draft leaves a number gap — intentional, to keep the audit trail clean.
