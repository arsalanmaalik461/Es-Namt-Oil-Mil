import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/supplier.dart';
import 'repo_utils.dart';

/// CRUD + paged search for suppliers. Balance math lives in
/// [AccountingService] — this class never computes balances.
class SupplierRepository {
  SupplierRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'suppliers';

  /// The next automatic party code: max existing NUMERIC code + 1, as a
  /// string ('1' for the very first supplier). Non-numeric legacy codes are
  /// ignored; existing codes are never renumbered.
  Future<String> nextCode() {
    return guard(table, () async {
      final rows = await _db.query(table, columns: ['code']);
      var max = 0;
      for (final row in rows) {
        final parsed = int.tryParse((row['code'] as String?)?.trim() ?? '');
        if (parsed != null && parsed > max) max = parsed;
      }
      return '${max + 1}';
    });
  }

  Future<int> insert(Supplier supplier) {
    return guard(table, () async {
      // Auto-assign the sequential code when the caller didn't supply one
      // (the form no longer asks the user to type it).
      var toInsert = supplier;
      if (supplier.code == null || supplier.code!.trim().isEmpty) {
        toInsert = supplier.copyWith(code: await nextCode());
      }
      final timestamp = now();
      final id = await _db.insert(
        table,
        toInsert.toMap()
          ..remove('id')
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      await AuditLog.log(_db,
          action: 'create',
          entity: table,
          entityId: id,
          details: supplier.name);
      return id;
    });
  }

  Future<Supplier?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Supplier.fromMap(rows.first);
    });
  }

  /// Paged, indexed search by name/phone/code.
  Future<List<Supplier>> search({
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
      return rows.map(Supplier.fromMap).toList();
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
  Future<void> update(Supplier supplier) {
    return guard(table, () async {
      final map = supplier.toMap()
        ..remove('id')
        ..remove('balance_paisa')
        ..remove('opening_balance_paisa')
        ..['updated_at'] = now();
      await _db.update(table, map, where: 'id = ?', whereArgs: [supplier.id]);
      await AuditLog.log(_db,
          action: 'update',
          entity: table,
          entityId: supplier.id,
          details: supplier.name);
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

  /// Hard delete. Fails with [DatabaseException] when the supplier is
  /// referenced (ON DELETE RESTRICT) — archive instead.
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
