import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
import '../models/ledger_entry.dart';
import '../repositories/cash_account_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/supplier_repository.dart';
import '../utils/time.dart';
import 'accounting_service.dart';

/// Transaction edit & void with full audit trail.
///
/// The ledger is immutable: posted amounts/dates/accounts are NEVER changed.
/// Instead:
/// * **Void** ("delete"): marks every entry of a journal as `voided = 1`.
///   Voided entries are excluded from all balances/totals but stay visible
///   in history with a "voided" badge. Balance caches are reversed.
/// * **Edit** ("correction"): voids the original journal, then the caller
///   posts a fresh corrected journal carrying `correctsJournal` = the
///   original journal key. Use [isCorrected] to show a "corrected" badge on
///   the original.
///
/// Voiding a whole journal (not a single leg) keeps double-entry balanced:
/// every voided journal still sums to zero.
class LedgerCorrectionService {
  LedgerCorrectionService._();

  /// Marks every entry of [journalKey] as voided and reverses balance caches.
  ///
  /// Throws [CorrectionException] when the journal doesn't exist or is
  /// already voided.
  static Future<void> voidJournal(String journalKey) async {
    final helper = DatabaseHelper.instance;
    await helper.transaction((txn) async {
      final rows = await txn.query(
        'ledger_entries',
        where: 'journal_key = ?',
        whereArgs: [journalKey],
      );
      if (rows.isEmpty) {
        throw CorrectionException('Transaction nahi mili.');
      }
      final entries = rows.map(LedgerEntry.fromMap).toList();
      if (entries.every((e) => e.voided)) {
        throw CorrectionException('Ye entry pehle se void hai.');
      }
      // Mark voided.
      await txn.update(
        'ledger_entries',
        {'voided': 1},
        where: 'journal_key = ? AND COALESCE(voided, 0) = 0',
        whereArgs: [journalKey],
      );
      // Reverse the cached balance deltas so cached totals stay correct.
      for (final e in entries) {
        if (e.voided) continue;
        final reverse =
            -AccountingService.signedEffect(e.accountType, e.debitPaisa, e.creditPaisa);
        if (reverse == 0) continue;
        await _adjustCache(txn, e.accountType, e.accountId, reverse);
      }
      // Audit trail.
      await txn.insert('audit_log', {
        'action': 'void',
        'entity': 'ledger_entries',
        'entity_id': journalKey,
        'created_at': nowMillis(),
      });
    });
  }

  /// True when [journalKey] has been voided.
  static Future<bool> isVoided(String journalKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'ledger_entries',
      columns: ['id'],
      where: 'journal_key = ? AND COALESCE(voided, 0) = 0',
      whereArgs: [journalKey],
      limit: 1,
    );
    return rows.isEmpty;
  }

  /// True when a correction journal exists for [journalKey].
  static Future<bool> isCorrected(String journalKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'ledger_entries',
      columns: ['id'],
      where: 'corrects_journal = ? AND COALESCE(voided, 0) = 0',
      whereArgs: [journalKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// The journal key of the correction for [journalKey], if any.
  static Future<String?> correctionJournalKey(String journalKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'ledger_entries',
      columns: ['journal_key'],
      where: 'corrects_journal = ? AND COALESCE(voided, 0) = 0',
      whereArgs: [journalKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['journal_key'] as String?;
  }

  static Future<void> _adjustCache(
    Transaction txn,
    AccountType type,
    int accountId,
    int deltaPaisa,
  ) async {
    switch (type) {
      case AccountType.customer:
        await CustomerRepository(txn).adjustBalance(txn, accountId, deltaPaisa);
      case AccountType.supplier:
        await SupplierRepository(txn).adjustBalance(txn, accountId, deltaPaisa);
      case AccountType.cash:
      case AccountType.bank:
        await CashAccountRepository(txn).adjustBalance(txn, accountId, deltaPaisa);
      case AccountType.expense:
      case AccountType.income:
        break;
    }
  }
}

/// User-readable correction failure.
class CorrectionException implements Exception {
  final String message;
  const CorrectionException(this.message);
  @override
  String toString() => 'CorrectionException: $message';
}
