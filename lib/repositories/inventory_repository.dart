import 'package:sqflite/sqflite.dart';

import '../models/inventory_movement.dart';
import 'repo_utils.dart';

/// Inventory movement history. This table is the source of truth for stock;
/// `products.stock_qty` is a cache maintained by [AccountingService].
class InventoryRepository {
  InventoryRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'inventory_movements';

  Future<int> insertMovement(InventoryMovement movement) {
    return guard(table, () async {
      return _db.insert(
        table,
        movement.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
    });
  }

  Future<List<InventoryMovement>> movementsForProduct(
    int productId, {
    int limit = 100,
    int offset = 0,
  }) {
    return guard(table, () async {
      final rows = await _db.query(
        table,
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(InventoryMovement.fromMap).toList();
    });
  }

  Future<List<InventoryMovement>> movementsForReference(
    String referenceType,
    int referenceId,
  ) {
    return guard(table, () async {
      final rows = await _db.query(
        table,
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [referenceType, referenceId],
        orderBy: 'id ASC',
      );
      return rows.map(InventoryMovement.fromMap).toList();
    });
  }

  /// True stock from movements (SUM of base-unit deltas). Used by
  /// [AccountingService.verifyBalances]-style stock reconciliation.
  Future<double> stockFromMovements(int productId) {
    return guard(table, () async {
      final rows = await _db.rawQuery(
        'SELECT COALESCE(SUM(qty_change_base), 0) AS s FROM $table WHERE product_id = ?',
        [productId],
      );
      return ((rows.first['s'] as num?) ?? 0).toDouble();
    });
  }
}
