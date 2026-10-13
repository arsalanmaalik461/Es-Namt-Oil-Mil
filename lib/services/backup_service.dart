import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';

/// Summary of a validated backup file (also carries the raw tables so a
/// restore can proceed without re-parsing).
class BackupSummary {
  final String exportedAtIso;
  final Map<String, int> rowCounts;
  final Map<String, List<Map<String, Object?>>> tables;

  const BackupSummary({
    required this.exportedAtIso,
    required this.rowCounts,
    required this.tables,
  });

  int get tableCount => tables.length;

  int get totalRows => rowCounts.values.fold(0, (a, b) => a + b);
}

/// Versioned, offline JSON backup / restore of the whole database.
///
/// Format:
/// ```json
/// {
///   "formatVersion": 1,
///   "exportedAt": "2026-10-14T00:30:00.000",
///   "app": "namt_oil_mil",
///   "tables": { "<table>": [ {row}, ... ], ... },
///   "checksums": { "<table>": "<fnv1a-64 hex>", ... }
/// }
/// ```
///
/// * Export reads every user table with plain SELECTs (no balance math —
///   the ledger rows themselves are backed up verbatim).
/// * Validation checks structure, version, required tables and per-table
///   checksums *before* anything is written.
/// * Restore runs inside a single DB transaction: deletes go children-first,
///   inserts go parents-first (FK-safe), and row counts are re-verified
///   inside the transaction — any failure rolls everything back, so a
///   restore is never partial.
class BackupService {
  BackupService(this._helper);

  final DatabaseHelper _helper;

  static const int formatVersion = 1;
  static const String appId = 'namt_oil_mil';

  /// All user tables in FK-safe **insert** order (parents first).
  ///
  /// `ledger_entries` is self-referencing (`reversed_by_id`); it is
  /// special-cased at restore time (NULL-references first).
  static const List<String> tableNames = [
    'units',
    'unit_conversions',
    'expense_categories',
    'document_sequences',
    'customers',
    'suppliers',
    'products',
    'cash_accounts',
    'sales_invoices',
    'sales_invoice_items',
    'purchase_invoices',
    'purchase_invoice_items',
    'payments',
    'payment_allocations',
    'account_transfers',
    'inventory_movements',
    'ledger_entries',
    'expenses',
    'income_entries',
    'production_batches',
    'production_inputs',
    'production_outputs',
    'sales_returns',
    'sales_return_items',
    'purchase_returns',
    'purchase_return_items',
    'audit_log',
  ];

  /// 64-bit FNV-1a checksum of a table's rows (canonical JSON encoding).
  /// Pure Dart, no extra dependencies; deterministic for a given payload.
  static String checksumFor(List<Map<String, Object?>> rows) {
    final bytes = utf8.encode(jsonEncode(rows));
    var hash = 0xcbf29ce484222325; // FNV offset basis
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF; // FNV prime
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Reads every table and returns the versioned backup document.
  /// The caller encodes it (`jsonEncode`) and saves the bytes.
  Future<Map<String, dynamic>> exportJson() async {
    final db = await _helper.database;
    final tables = <String, dynamic>{};
    final checksums = <String, String>{};
    for (final table in tableNames) {
      final rows = await db.query(table);
      final normalized = rows.map((r) => Map<String, Object?>.from(r)).toList();
      tables[table] = normalized;
      checksums[table] = checksumFor(normalized);
    }
    return {
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': appId,
      'tables': tables,
      'checksums': checksums,
    };
  }

  /// Validates backup [bytes]; throws [ValidationException] with a
  /// `backup_error*` message key on any problem. Never touches the DB.
  Future<BackupSummary> validateBackup(Uint8List bytes) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ValidationException('backup_errorInvalidFile');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException('backup_errorInvalidFile');
    }
    final version = decoded['formatVersion'];
    if (version != formatVersion) {
      throw ValidationException(
        'backup_errorUnsupportedVersion',
        {'version': '$version'},
      );
    }
    final rawTables = decoded['tables'];
    if (rawTables is! Map) {
      throw const ValidationException('backup_errorInvalidFile');
    }
    final missing = tableNames.where((t) => !rawTables.containsKey(t)).toList();
    if (missing.isNotEmpty) {
      throw ValidationException(
        'backup_errorMissingTables',
        {'tables': missing.join(', ')},
      );
    }

    final tables = <String, List<Map<String, Object?>>>{};
    final rowCounts = <String, int>{};
    for (final table in tableNames) {
      final rawRows = rawTables[table];
      if (rawRows is! List) {
        throw const ValidationException('backup_errorInvalidFile');
      }
      final rows = <Map<String, Object?>>[];
      for (final r in rawRows) {
        if (r is! Map) {
          throw const ValidationException('backup_errorInvalidFile');
        }
        rows.add(Map<String, Object?>.from(r));
      }
      tables[table] = rows;
      rowCounts[table] = rows.length;
    }

    final rawChecksums = decoded['checksums'];
    if (rawChecksums is Map) {
      for (final table in tableNames) {
        final expected = rawChecksums[table];
        if (expected is String && checksumFor(tables[table]!) != expected) {
          throw ValidationException(
            'backup_errorChecksum',
            {'table': table},
          );
        }
      }
    }

    final exportedAt = decoded['exportedAt'];
    return BackupSummary(
      exportedAtIso: exportedAt is String ? exportedAt : '',
      rowCounts: rowCounts,
      tables: tables,
    );
  }

  /// Validates [bytes] and replaces ALL current data inside one DB
  /// transaction. Returns the number of restored rows.
  ///
  /// Validation happens before the transaction opens, and the transaction
  /// itself re-verifies row counts — a failure at any point rolls back, so
  /// the database is never left half-restored.
  Future<int> restoreBackup(Uint8List bytes) async {
    final summary = await validateBackup(bytes);
    await _helper.transaction((txn) async {
      // Deletes: children first (reverse of insert order). ledger_entries
      // rows that reverse other rows must go before the rows they reference.
      for (final table in tableNames.reversed) {
        if (table == 'ledger_entries') {
          await txn.delete(table, where: 'reversed_by_id IS NOT NULL');
        }
        await txn.delete(table);
      }
      // Inserts: parents first. ledger_entries rows with a NULL
      // reversed_by_id go before the rows that reference them.
      for (final table in tableNames) {
        final rows = summary.tables[table]!;
        if (table == 'ledger_entries') {
          final parents =
              rows.where((r) => r['reversed_by_id'] == null).toList();
          final children =
              rows.where((r) => r['reversed_by_id'] != null).toList();
          for (final row in [...parents, ...children]) {
            await txn.insert(table, row);
          }
        } else {
          for (final row in rows) {
            await txn.insert(table, row);
          }
        }
      }
      // Integrity check inside the transaction: counts must match.
      for (final table in tableNames) {
        final count = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) AS c FROM "$table"'),
            ) ??
            -1;
        if (count != summary.rowCounts[table]) {
          throw const DatabaseException('error.database');
        }
      }
    });
    return summary.totalRows;
  }
}

/// Riverpod access to [BackupService].
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseHelperProvider)),
);
