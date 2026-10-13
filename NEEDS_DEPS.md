# NEEDS_DEPS.md — Module B (data layer) dependency requests

> Owned by Module B. `pubspec.yaml` itself is owned by Module A — requests go
> here; Module A applies them.

## Status: nothing to add ✅

All packages needed by the data layer are already present in `pubspec.yaml`:

| Package | Used for | Status |
|---|---|---|
| `sqflite` ^2.4.2 | SQLite database (`lib/db/`, repositories, services) | ✅ present |
| `path` ^1.9.1 | `join(getDatabasesPath(), 'namt_oil_mil.db')` | ✅ present |
| `intl` ^0.20.2 | `formatPkr` in `lib/utils/money.dart` | ✅ present |
| `flutter_riverpod` ^2.6.1 | `lib/providers/db_providers.dart` | ✅ present |
| `uuid` ^4.5.1 | journal keys + idempotency keys (`lib/utils/keys.dart`) | ✅ present |

`sqflite_common_ffi` (dev) is available for the QA agent's automated tests.

No new dependencies requested.

## 2026-10-14 ~00:10 PKT — offline resolution (coordinator)

`flutter pub get --offline` SUCCEEDED: 110 dependencies resolved, **zero
unresolvable packages**. Nothing to escalate. Bumps applied to pubspec.yaml:
- `share_plus`: ^11.0.0 → ^13.3.1 (v13 API: `SharePlus.instance.share(ShareParams(...))`; `XFile` re-exported)
- `file_picker`: ^8.1.7 → ^13.1.0 (v13 API: static `FilePicker.pickFiles()` → `Future<List<PlatformFile>?>`; bytes via `await f.readAsBytes()`)
- `flutter_lints`: ^4.0.0 → ^6.0.0

Resolved from local cache (all verified): sqflite 2.4.4+2, sqflite_common_ffi 2.4.4,
flutter_riverpod 2.6.1, shared_preferences 2.5.6, pdf 3.13.1, printing 5.15.1,
intl 0.20.3, uuid 4.6.0, path_provider 2.1.6, collection, path.

`flutter gen-l10n` completed: `lib/l10n/gen/app_localizations.dart` (+ `_en`, `_ur`)
generated. Minor: l10n.yaml `synthetic-package` key is deprecated (warning only;
cleanup in final pass).
