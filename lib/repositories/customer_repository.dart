import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/customer.dart';
import 'repo_utils.dart';

/// CRUD + paged search for customers. Balance math lives in
/// [AccountingService] — this class never computes balances.
class CustomerRepository {
  CustomerRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'customers';

  Future<int> insert(Customer customer) {
    return guard(table, () async {
      final timestamp = now();
      final id = await _db.insert(
        table,
        customer.toMap()
          ..remove('id')
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      await AuditLog.log(_db,
          action: 'create',
          entity: table,
          entityId: id,
          details: customer.name);
      return id;
    });
  }

  Future<Customer?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Customer.fromMap(rows.first);
    });
  }

  /// Paged, indexed search by name/phone/code.
  Future<List<Customer>> search({
    String query = '',
    int limit = 50,
    int offset = 0,
    bool includeArchived = false,
  }) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (!includeArchived) where.add('is_archived = 0');
      final q = query.trim();
      if (q.isNotEmpty) {
        where.add(
            "(name LIKE ? ESCAPE '\\' OR phone LIKE ? ESCAPE '\\' OR code LIKE ? ESCAPE '\\')");
        final pattern = likePattern(q);
        args.addAll([pattern, pattern, pattern]);
      }
      final rows = await _db.query(
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'name COLLATE NOCASE ASC',
        limit: limit,
        offset: offset,
      );
      return rows.map(Customer.fromMap).toList();
    });
  }

  Future<int> count({String query = '', bool includeArchived = false}) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (!includeArchived) where.add('is_archived = 0');
      final q = query.trim();
      if (q.isNotEmpty) {
        where.add(
            "(name LIKE ? ESCAPE '\\' OR phone LIKE ? ESCAPE '\\' OR code LIKE ? ESCAPE '\\')");
        final pattern = likePattern(q);
        args.addAll([pattern, pattern, pattern]);
      }
      final rows = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM $table'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}',
        args,
      );
      return (rows.first['c'] as int?) ?? 0;
    });
  }

  /// Updates profile fields. Balance caches are NOT touched here.
  Future<void> update(Customer customer) {
    return guard(table, () async {
      final map = customer.toMap()
        ..remove('id')
        ..remove('balance_paisa')
        ..remove('opening_balance_paisa')
        ..['updated_at'] = now();
      await _db.update(table, map, where: 'id = ?', whereArgs: [customer.id]);
      await AuditLog.log(_db,
          action: 'update',
          entity: table,
          entityId: customer.id,
          details: customer.name);
    });
  }

  Future<void> setArchived(int id, bool archived) {
    return guard(table, () async {
      await _db.update(
        table,
        {'is_archived': archived ? 1 : 0, 'updated_at': now()},
        where: 'id = ?',
        whereArgs: [id],
      );
      await AuditLog.log(_db,
          action: archived ? 'archive' : 'unarchive',
          entity: table,
          entityId: id);
    });
  }

  /// Hard delete. Fails with [DatabaseException] when the customer is
  /// referenced by invoices/payments/ledger (ON DELETE RESTRICT) — archive
  /// instead.
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
