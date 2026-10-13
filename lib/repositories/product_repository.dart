import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/product.dart';
import 'repo_utils.dart';

/// CRUD + paged search for products. Stock/cost cache updates happen ONLY via
/// [AccountingService] inside posting transactions.
class ProductRepository {
  ProductRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'products';

  Future<int> insert(Product product) {
    return guard(table, () async {
      final timestamp = now();
      final id = await _db.insert(
        table,
        product.toMap()
          ..remove('id')
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      await AuditLog.log(_db,
          action: 'create', entity: table, entityId: id, details: product.name);
      return id;
    });
  }

  Future<Product?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Product.fromMap(rows.first);
    });
  }

  /// Paged, indexed search by name/sku, optionally filtered by category.
  Future<List<Product>> search({
    String query = '',
    ProductCategory? category,
    int limit = 50,
    int offset = 0,
    bool includeArchived = false,
  }) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (!includeArchived) where.add('is_archived = 0');
      if (category != null) {
        where.add('category = ?');
        args.add(category.dbValue);
      }
      final q = query.trim();
      if (q.isNotEmpty) {
        where.add("(name LIKE ? ESCAPE '\\' OR sku LIKE ? ESCAPE '\\')");
        final pattern = likePattern(q);
        args.addAll([pattern, pattern]);
      }
      final rows = await _db.query(
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'name COLLATE NOCASE ASC',
        limit: limit,
        offset: offset,
      );
      return rows.map(Product.fromMap).toList();
    });
  }

  Future<List<Product>> getAll({bool includeArchived = false}) {
    return search(limit: 1000000, includeArchived: includeArchived);
  }

  /// Products at or below their reorder level.
  Future<List<Product>> lowStock({int limit = 200}) {
    return guard(table, () async {
      final rows = await _db.query(
        table,
        where: 'is_archived = 0 AND stock_qty <= reorder_level_qty',
        orderBy: 'stock_qty ASC',
        limit: limit,
      );
      return rows.map(Product.fromMap).toList();
    });
  }

  /// Updates master data. Stock qty / avg cost are NOT touched here.
  Future<void> update(Product product) {
    return guard(table, () async {
      final map = product.toMap()
        ..remove('id')
        ..remove('stock_qty')
        ..remove('avg_cost_paisa')
        ..['updated_at'] = now();
      await _db.update(table, map, where: 'id = ?', whereArgs: [product.id]);
      await AuditLog.log(_db,
          action: 'update',
          entity: table,
          entityId: product.id,
          details: product.name);
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

  /// Hard delete. Fails with [DatabaseException] when referenced by
  /// movements/invoices (ON DELETE RESTRICT) — archive instead.
  Future<void> delete(int id) {
    return guard(table, () async {
      await _db.delete(table, where: 'id = ?', whereArgs: [id]);
      await AuditLog.log(_db, action: 'delete', entity: table, entityId: id);
    });
  }

  /// Applies a signed base-unit qty delta and optionally a new average cost.
  /// Called ONLY by [AccountingService] inside a posting transaction.
  Future<void> adjustStockAndCost(
    DatabaseExecutor db,
    int id,
    double qtyDeltaBase,
    int? newAvgCostPaisa,
  ) {
    return guard(table, () async {
      final args = <Object?>[];
      var sql = 'UPDATE $table SET stock_qty = stock_qty + ?, updated_at = ?';
      args.addAll([qtyDeltaBase, now()]);
      if (newAvgCostPaisa != null) {
        sql += ', avg_cost_paisa = ?';
        args.add(newAvgCostPaisa);
      }
      sql += ' WHERE id = ?';
      args.add(id);
      await db.rawUpdate(sql, args);
    });
  }
}
