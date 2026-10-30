import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/time.dart';
import 'schema.dart';

/// Central SQLite access for Namt Oil Mil (pure Dart, no Flutter imports).
///
/// * Single database file: `namt_oil_mil.db`, 100% offline.
/// * `PRAGMA foreign_keys = ON` is enforced on every connection.
/// * Schema versioning: [dbVersion] starts at 1. Future changes add their DDL
///   to [migrations] keyed by target version; [onUpgrade] applies them in
///   order. Migrations are additive-only — user tables are NEVER dropped.
/// * The database is never wiped on startup. Failed operations throw.
/// * First open seeds reference data only (units, conversions, expense
///   categories, one "Cash" account). NO fake customers, suppliers, products
///   or transactions are ever created.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// SQLite file name.
  static const String dbFileName = 'namt_oil_mil.db';

  /// Current schema version. Bump when adding entries to [migrations].
  static const int dbVersion = 5;

  /// Additive migration scripts keyed by TARGET version.
  ///
  /// Example for v2:
  /// ```dart
  /// static const Map<int, List<String>> migrations = {
  ///   2: ['ALTER TABLE products ADD COLUMN barcode TEXT'],
  /// };
  /// ```
  /// Rules: only ADD tables/columns/indexes. Never DROP/rename user tables,
  /// never change a money column's type. Backfill new NOT NULL columns with
  /// a DEFAULT so existing rows stay valid.
  static const Map<int, List<String>> migrations = <int, List<String>>{
    // v2: idempotency for ledger-only postings (udhaar). UNIQUE allows
    // multiple NULLs, so pre-v2 rows and postings without a key are unaffected.
    2: ['ALTER TABLE ledger_entries ADD COLUMN idempotency_key TEXT UNIQUE'],
    // v3: WhatsApp number per customer (user-requested 2026-10-18) for
    // one-tap statement sharing to the customer's WhatsApp chat.
    3: ['ALTER TABLE customers ADD COLUMN whatsapp_number TEXT'],
    // v4: Reminders/sharing gaps (Team 6, 2026-10-18) — void flag, due date,
    // bill photo path, and correction-journal link on ledger entries.
    // All additive; existing rows default to not-voided / no due date.
    4: [
      'ALTER TABLE ledger_entries ADD COLUMN voided INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE ledger_entries ADD COLUMN due_date INTEGER',
      'ALTER TABLE ledger_entries ADD COLUMN bill_image_path TEXT',
      'ALTER TABLE ledger_entries ADD COLUMN corrects_journal TEXT',
      'CREATE INDEX IF NOT EXISTS idx_ledger_voided ON ledger_entries(voided)',
      'CREATE INDEX IF NOT EXISTS idx_ledger_due ON ledger_entries(due_date)',
    ],
    // v5: Automatic payment reminders (user-requested 2026-10-30) — send
    // log for the daily WhatsApp queue and the 7-day SMS cadence. One row
    // per confirmed send; the due computation reads MAX(sent_at) per
    // (customer, channel). Device-local history only: deliberately NOT in
    // BackupService.tableNames, so older backups (which lack this table)
    // still validate and restore, and a restore never rewrites send
    // history.
    5: [
      'CREATE TABLE reminder_auto_log ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'customer_id INTEGER NOT NULL, '
          'channel TEXT NOT NULL, '
          'sent_at INTEGER NOT NULL, '
          'balance_paisa INTEGER NOT NULL DEFAULT 0, '
          "status TEXT NOT NULL DEFAULT 'sent')",
      'CREATE INDEX idx_reminder_auto_log_lookup '
          'ON reminder_auto_log(customer_id, channel, sent_at)',
    ],
  };

  Database? _db;

  /// In-flight open future. Stored (not just awaited) so concurrent callers
  /// awaiting [database] during first open all share ONE openDatabase call.
  /// Without this, two callers racing on a cold start each ran openDatabase
  /// on the same file -> "database is locked" (SqliteException code 5)
  /// during CREATE TABLE. Reported by user 2026-10-20, fixed same day.
  Future<Database>? _openFuture;

  /// The shared database connection, opened (and seeded) on first use.
  Future<Database> get database {
    final db = _db;
    if (db != null && db.isOpen) return Future.value(db);
    return _openFuture ??= _open().then((opened) {
      _db = opened;
      _openFuture = null;
      return opened;
    }).catchError((Object e) {
      // Let the next caller retry a fresh open instead of caching failure.
      _openFuture = null;
      throw e;
    });
  }

  /// Runs [action] inside a single SQLite transaction.
  ///
  /// All multi-write business operations (postings) MUST go through this so
  /// ledger entries, balance caches, stock and documents stay consistent.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// TEST-ONLY: closes the connection and deletes the database file so the
  /// next [database] call starts from a clean, freshly-seeded slate.
  ///
  /// Never call this in production code — it destroys all user data.
  Future<void> resetForTesting() async {
    final db = _db;
    _db = null;
    _openFuture = null;
    await db?.close();
    final dir = await getDatabasesPath();
    final file = File(p.join(dir, dbFileName));
    if (await file.exists()) await file.delete();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, dbFileName),
      version: dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final stmt in Schema.allStatements) {
      batch.execute(stmt);
    }
    await batch.commit(noResult: true);
    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final statements = migrations[v];
      if (statements == null) continue;
      for (final stmt in statements) {
        await db.execute(stmt);
      }
    }
  }

  /// Seeds reference data on first open. Idempotent by construction (runs once
  /// inside onCreate). Contains NO business/fake data.
  Future<void> _seed(DatabaseExecutor db) async {
    final now = nowMillis();

    // --- units ---
    final kgId = await db.insert('units', {'name': 'Kilogram', 'symbol': 'kg'});
    final maundId =
        await db.insert('units', {'name': 'Maund', 'symbol': 'maund'});
    final tonId = await db.insert('units', {'name': 'Ton', 'symbol': 'ton'});
    await db.insert('units', {'name': 'Litre', 'symbol': 'litre'});
    await db.insert('units', {'name': 'Bag', 'symbol': 'bag'});
    await db.insert('units', {'name': 'Piece', 'symbol': 'piece'});

    // --- unit conversions (configurable; user-editable later) ---
    // Pakistani maund = 40 kg by convention; metric ton = 1000 kg.
    // litre <-> kg is deliberately NOT seeded: the factor depends on oil
    // density and varies by product/batch.
    await db.insert('unit_conversions', {
      'from_unit_id': maundId,
      'to_unit_id': kgId,
      'factor': 40.0,
    });
    await db.insert('unit_conversions', {
      'from_unit_id': tonId,
      'to_unit_id': kgId,
      'factor': 1000.0,
    });

    // --- expense categories ---
    for (final name in [
      'electricity',
      'labour',
      'transport',
      'rent',
      'repairs',
      'packaging',
      'maintenance',
      'admin',
      'other',
    ]) {
      await db.insert('expense_categories', {'name': name, 'is_active': 1});
    }

    // --- one active Cash account ---
    await db.insert('cash_accounts', {
      'name': 'Cash',
      'type': 'cash',
      'opening_balance_paisa': 0,
      'balance_paisa': 0,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Closes the shared connection (used in tests / app shutdown).
  Future<void> close() async {
    final db = _db;
    _db = null;
    _openFuture = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
