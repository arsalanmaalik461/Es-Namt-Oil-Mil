import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/cash_account.dart';
import 'repo_utils.dart';

/// CRUD for cash/bank accounts. Balance math lives in [AccountingService].
class CashAccountRepository {
  CashAccountRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'cash_accounts';

  Future<int> insert(CashAccount account) {
    return guard(table, () async {
      final timestamp = now();
      final id = await _db.insert(
        table,
        account.toMap()
          ..remove('id')
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      await AuditLog.log(_db,
          action: 'create', entity: table, entityId: id, details: account.name);
      return id;
    });
  }

  Future<CashAccount?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return CashAccount.fromMap(rows.first);
    });
  }

  Future<List<CashAccount>> getAll({bool activeOnly = true}) {
    return guard(table, () async {
      final rows = await _db.query(
        table,
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'name ASC',
      );
      return rows.map(CashAccount.fromMap).toList();
    });
  }

  Future<void> update(CashAccount account) {
    return guard(table, () async {
      final map = account.toMap()
        ..remove('id')
        ..remove('balance_paisa')
        ..['updated_at'] = now();
      await _db.update(table, map, where: 'id = ?', whereArgs: [account.id]);
      await AuditLog.log(_db,
          action: 'update',
          entity: table,
          entityId: account.id,
          details: account.name);
    });
  }

  Future<void> setActive(int id, bool active) {
    return guard(table, () async {
      await _db.update(
        table,
        {'is_active': active ? 1 : 0, 'updated_at': now()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Hard delete. Fails with [DatabaseException] when referenced by
  /// payments/expenses/ledger (ON DELETE RESTRICT) — deactivate instead.
  Future<void> delete(int id) {
    return guard(table, () async {
      await _db.delete(table, where: 'id = ?', whereArgs: [id]);
      await AuditLog.log(_db, action: 'delete', entity: table, entityId: id);
    });
  }

  /// Applies a signed delta to the cached balance. Called ONLY by
  /// [AccountingService] inside a posting transaction.
  Future<void> adjustBalance(DatabaseExecutor db, int id, int deltaPaisa) {
    return guard(table, () async {
      await db.rawUpdate(
        'UPDATE $table SET balance_paisa = balance_paisa + ?, updated_at = ? WHERE id = ?',
        [deltaPaisa, now(), id],
      );
    });
  }

  /// The cached balance (for [AccountingService.verifyBalances]).
  Future<int> cachedBalance(int id) {
    return guard(table, () async {
      final rows = await _db.query(table,
          columns: ['balance_paisa'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1);
      if (rows.isEmpty) return 0;
      return (rows.first['balance_paisa'] as int?) ?? 0;
    });
  }
}
