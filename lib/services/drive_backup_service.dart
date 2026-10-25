import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/services/backup_service.dart';
import 'package:namt_oil_mil/services/google_drive_service.dart';

/// Orchestrates Google Drive backups (user-requested 2026-10-18).
///
/// Two flavors:
/// * **Full backup** — the same versioned JSON document as the local
///   [BackupService.exportJson] (restorable via the existing restore flow).
/// * **Date-range export** — a lighter JSON with just the dated business
///   tables (ledger, invoices, payments, expenses, …) filtered to
///   [from]..[to]. Meant for "custom date se custom date tak ka hisaab".
///
/// Scheduling: [ensureDailyScheduler] registers a WorkManager periodic task
/// (24h, requires network). It is called from Settings when the user
/// enables auto-backup — no `main()` changes needed. The worker entry
/// point is the top-level [driveBackupCallbackDispatcher] below.
///
/// Everything here is best-effort and silent-safe: no network, no Google
/// connection, or revoked access simply means "skip this run".
class DriveBackupService {
  DriveBackupService(this._ref);

  final Ref _ref;

  static const String periodicTaskUniqueName =
      'namt_oil_mil_drive_backup_daily';
  static const String periodicTaskName = 'drive_daily_backup';

  GoogleDriveService get _drive => _ref.read(googleDriveServiceProvider);
  BackupService get _backup => _ref.read(backupServiceProvider);

  String _stamp(DateTime dt) =>
      DateFormat('yyyy-MM-dd_HH-mm').format(dt);

  // ------------------------------------------------------------ operations

  /// Exports the full database and uploads it to Drive.
  ///
  /// When [interactive] is true the user just tapped a button, so sign-in
  /// UI is allowed; otherwise everything stays silent. Returns a result
  /// carrying a localisable message key (the UI resolves it via
  /// FragmentStrings).
  Future<DriveBackupResult> runFullBackupNow(
      {required bool interactive}) async {
    final api = interactive
        ? await _drive.driveApiInteractive()
        : await _drive.driveApiSilent();
    if (api == null) {
      return const DriveBackupResult(
        ok: false,
        messageKey: 'backup_driveConnectFailed',
      );
    }
    try {
      final doc = await _backup.exportJson();
      final bytes =
          Uint8List.fromList(utf8.encode(jsonEncode(doc)));
      final name = 'namt-oil-mil_full_${_stamp(DateTime.now())}.json';
      await _drive.uploadBackup(api: api, fileName: name, bytes: bytes);
      await _drive.recordBackupAt(DateTime.now());
      return DriveBackupResult(
          ok: true,
          messageKey: 'backup_driveBackupSaved',
          params: {'name': name});
    } catch (e) {
      return DriveBackupResult(
          ok: false,
          messageKey: 'backup_driveBackupFailed',
          params: {'error': _shortError(e)});
    }
  }

  /// Exports [from]..[to] (inclusive) hisaab-kitaab and uploads to Drive.
  Future<DriveBackupResult> runDateRangeExport({
    required DateTime from,
    required DateTime to,
    required bool interactive,
  }) async {
    final api = interactive
        ? await _drive.driveApiInteractive()
        : await _drive.driveApiSilent();
    if (api == null) {
      return const DriveBackupResult(
        ok: false,
        messageKey: 'backup_driveConnectFailed',
      );
    }
    try {
      final doc = await exportDateRangeJson(from, to);
      final bytes =
          Uint8List.fromList(utf8.encode(jsonEncode(doc)));
      final fmt = DateFormat('yyyy-MM-dd');
      final name =
          'namt-oil-mil_${fmt.format(from)}_to_${fmt.format(to)}.json';
      await _drive.uploadBackup(api: api, fileName: name, bytes: bytes);
      return DriveBackupResult(
          ok: true,
          messageKey: 'backup_driveExportSaved',
          params: {'name': name});
    } catch (e) {
      return DriveBackupResult(
          ok: false,
          messageKey: 'backup_driveExportFailed',
          params: {'error': _shortError(e)});
    }
  }

  /// Builds the date-range export document. Dated business tables only,
  /// filtered on their `date` (millis-since-epoch) column.
  Future<Map<String, dynamic>> exportDateRangeJson(
      DateTime from, DateTime to) async {
    final db = await DatabaseHelper.instance.database;
    final fromMs =
        DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
    // inclusive end: start of the day after `to`
    final toMs =
        DateTime(to.year, to.month, to.day).add(const Duration(days: 1))
            .millisecondsSinceEpoch;

    // table -> date column
    const dated = <String, String>{
      'ledger_entries': 'date',
      'sales_invoices': 'date',
      'purchase_invoices': 'date',
      'payments': 'date',
      'account_transfers': 'date',
      'expenses': 'date',
      'income_entries': 'date',
      'production_batches': 'date',
      'inventory_movements': 'date',
      'sales_returns': 'date',
      'purchase_returns': 'date',
    };
    final tables = <String, dynamic>{};
    for (final entry in dated.entries) {
      final rows = await db.query(
        entry.key,
        where: '${entry.value} >= ? AND ${entry.value} < ?',
        whereArgs: [fromMs, toMs],
      );
      tables[entry.key] =
          rows.map((r) => Map<String, Object?>.from(r)).toList();
    }
    return {
      'formatVersion': BackupService.formatVersion,
      'exportKind': 'date_range',
      'exportedAt': DateTime.now().toIso8601String(),
      'app': BackupService.appId,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'tables': tables,
    };
  }

  // ------------------------------------------------------------ scheduling

  /// Registers the 24h WorkManager task. Called when the user enables
  /// auto-backup in Settings (and re-asserted on later Settings opens).
  Future<void> ensureDailyScheduler() async {
    try {
      await Workmanager().initialize(
        driveBackupCallbackDispatcher,
      );
      await Workmanager().registerPeriodicTask(
        periodicTaskUniqueName,
        periodicTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (_) {
      // Plugin unavailable on this platform — foreground opportunistic
      // backup (see maybeRunDailyBackup) still covers the user.
    }
  }

  Future<void> cancelDailyScheduler() async {
    try {
      await Workmanager().cancelByUniqueName(periodicTaskUniqueName);
    } catch (_) {}
  }

  /// Foreground opportunistic check: if auto-backup is on and the last
  /// backup is older than 24h, run one silently. Called at app start and
  /// when Settings opens — covers devices where WorkManager never fires.
  Future<void> maybeRunDailyBackup() async {
    if (!await _drive.isAutoBackupEnabled()) return;
    final last = await _drive.lastBackupAt();
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 24)) {
      return;
    }
    final result = await runFullBackupNow(interactive: false);
    // Silent by design: only failures worth retrying matter, and the next
    // trigger will retry automatically.
    if (!result.ok) {
      // ignore: avoid_print
      print('[DriveBackup] daily backup skipped: ${result.messageKey}');
    }
  }

  String _shortError(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}

/// Outcome of one backup/export attempt. [messageKey] is a FragmentStrings
/// key (`backup_drive*`) and [params] its interpolation values; the UI
/// resolves the pair into a localised message — never show the key raw.
class DriveBackupResult {
  final bool ok;
  final String messageKey;
  final Map<String, Object?> params;
  const DriveBackupResult({
    required this.ok,
    required this.messageKey,
    this.params = const {},
  });
}

/// Riverpod access to [DriveBackupService].
final driveBackupServiceProvider = Provider<DriveBackupService>(
  (ref) => DriveBackupService(ref),
);

// ---------------------------------------------------------------------------
// Background worker (WorkManager). Must stay top-level.
// ---------------------------------------------------------------------------

/// WorkManager entry point. Runs in a background isolate: re-opens the
/// database directly, exports the full backup JSON, and uploads it to the
/// user's Drive using silent Google auth. Any failure simply ends the task —
/// the next 24h tick (or the foreground check) retries.
@pragma('vm:entry-point')
void driveBackupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != DriveBackupService.periodicTaskName) return true;
    try {
      final driveService = GoogleDriveService();
      final autoOn = await driveService.isAutoBackupEnabled();
      if (!autoOn) return true;

      final api = await driveService.driveApiSilent();
      if (api == null) return true; // offline / revoked — retry next tick

      final helper = DatabaseHelper.instance;
      final backup = BackupService(helper);
      final doc = await backup.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(doc)));
      final name =
          'namt-oil-mil_full_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
      await driveService.uploadBackup(api: api, fileName: name, bytes: bytes);
      await driveService.recordBackupAt(DateTime.now());
      return true;
    } catch (_) {
      // Best-effort: a failed tick must not crash the worker.
      return false;
    }
  });
}
