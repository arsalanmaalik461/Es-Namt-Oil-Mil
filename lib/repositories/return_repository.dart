import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/purchase_return.dart';
import '../models/sales_return.dart';
import 'repo_utils.dart';

/// CRUD for sales/purchase returns. Posting (ledger/stock/balance effects)
/// goes through [AccountingService], never this class alone.
class ReturnRepository {
  ReturnRepository(this._db);
  final DatabaseExecutor _db;

  static const String salesTable = 'sales_returns';
  static const String salesItemsTable = 'sales_return_items';
  static const String purchaseTable = 'purchase_returns';
  static const String purchaseItemsTable = 'purchase_return_items';

  // ---------------------------------------------------------- sales returns

  Future<SalesReturn> insertSalesReturn(
    DatabaseExecutor db,
    SalesReturn ret,
    List<SalesReturnItem> items,
  ) {
    return guard(salesTable, () async {
      final id = await db.insert(
        salesTable,
        ret.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
      for (final item in items) {
        await db.insert(
            salesItemsTable,
            item.toMap()
              ..remove('id')
              ..['return_id'] = id);
      }
      await AuditLog.log(db,
          action: 'post',
          entity: salesTable,
          entityId: id,
          details: ret.returnNo);
      return ret.copyWith(id: id);
    });
  }

  Future<SalesReturn?> getSalesReturn(int id) {
    return guard(salesTable, () async {
      final rows = await _db.query(salesTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return SalesReturn.fromMap(rows.first);
    });
  }

  Future<SalesReturn?> findSalesReturnByIdempotencyKey(String key) {
    return guard(salesTable, () async {
      final rows = await _db.query(salesTable,
          where: 'idempotency_key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) return null;
      return SalesReturn.fromMap(rows.first);
    });
  }

  Future<List<SalesReturnItem>> getSalesReturnItems(int returnId) {
    return guard(salesItemsTable, () async {
      final rows = await _db.query(salesItemsTable,
          where: 'return_id = ?', whereArgs: [returnId], orderBy: 'id ASC');
      return rows.map(SalesReturnItem.fromMap).toList();
    });
  }

  Future<List<SalesReturn>> listSalesReturns({
    int? customerId,
    int? invoiceId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    return guard(salesTable, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (customerId != null) {
        where.add('customer_id = ?');
        args.add(customerId);
      }
      if (invoiceId != null) {
        where.add('invoice_id = ?');
        args.add(invoiceId);
      }
      if (from != null) {
        where.add('date >= ?');
        args.add(from.millisecondsSinceEpoch);
      }
      if (to != null) {
        where.add('date < ?');
        args.add(to.millisecondsSinceEpoch);
      }
      final rows = await _db.query(
        salesTable,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(SalesReturn.fromMap).toList();
    });
  }

  /// Total paisa already returned against a sales invoice.
  Future<int> totalReturnedForSalesInvoice(int invoiceId) {
    return guard(salesTable, () async {
      final rows = await _db.rawQuery(
        'SELECT COALESCE(SUM(total_paisa), 0) AS s FROM $salesTable WHERE invoice_id = ?',
        [invoiceId],
      );
      return (rows.first['s'] as int?) ?? 0;
    });
  }

  /// Qty (in original units, summed per row) already returned for one
  /// invoice+product. Callers convert to base units for comparison.
  Future<List<SalesReturnItem>> itemsForSalesInvoiceProduct(
      int invoiceId, int productId) {
    return guard(salesItemsTable, () async {
      final rows = await _db.rawQuery(
        'SELECT i.* FROM $salesItemsTable i '
        'JOIN $salesTable r ON r.id = i.return_id '
        'WHERE r.invoice_id = ? AND i.product_id = ?',
        [invoiceId, productId],
      );
      return rows.map(SalesReturnItem.fromMap).toList();
    });
  }

  // ------------------------------------------------------- purchase returns

  Future<PurchaseReturn> insertPurchaseReturn(
    DatabaseExecutor db,
    PurchaseReturn ret,
    List<PurchaseReturnItem> items,
  ) {
    return guard(purchaseTable, () async {
      final id = await db.insert(
        purchaseTable,
        ret.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
      for (final item in items) {
        await db.insert(
            purchaseItemsTable,
            item.toMap()
              ..remove('id')
              ..['return_id'] = id);
      }
      await AuditLog.log(db,
          action: 'post',
          entity: purchaseTable,
          entityId: id,
          details: ret.returnNo);
      return ret.copyWith(id: id);
    });
  }

  Future<PurchaseReturn?> getPurchaseReturn(int id) {
    return guard(purchaseTable, () async {
      final rows = await _db.query(purchaseTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return PurchaseReturn.fromMap(rows.first);
    });
  }

  Future<PurchaseReturn?> findPurchaseReturnByIdempotencyKey(String key) {
    return guard(purchaseTable, () async {
      final rows = await _db.query(purchaseTable,
          where: 'idempotency_key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) return null;
      return PurchaseReturn.fromMap(rows.first);
    });
  }

  Future<List<PurchaseReturnItem>> getPurchaseReturnItems(int returnId) {
    return guard(purchaseItemsTable, () async {
      final rows = await _db.query(purchaseItemsTable,
          where: 'return_id = ?', whereArgs: [returnId], orderBy: 'id ASC');
      return rows.map(PurchaseReturnItem.fromMap).toList();
    });
  }

  Future<List<PurchaseReturn>> listPurchaseReturns({
    int? supplierId,
    int? invoiceId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    return guard(purchaseTable, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (supplierId != null) {
        where.add('supplier_id = ?');
        args.add(supplierId);
      }
      if (invoiceId != null) {
        where.add('invoice_id = ?');
        args.add(invoiceId);
      }
      if (from != null) {
        where.add('date >= ?');
        args.add(from.millisecondsSinceEpoch);
      }
      if (to != null) {
        where.add('date < ?');
        args.add(to.millisecondsSinceEpoch);
      }
      final rows = await _db.query(
        purchaseTable,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(PurchaseReturn.fromMap).toList();
    });
  }

  /// Total paisa already returned against a purchase invoice.
  Future<int> totalReturnedForPurchaseInvoice(int invoiceId) {
    return guard(purchaseTable, () async {
      final rows = await _db.rawQuery(
        'SELECT COALESCE(SUM(total_paisa), 0) AS s FROM $purchaseTable WHERE invoice_id = ?',
        [invoiceId],
      );
      return (rows.first['s'] as int?) ?? 0;
    });
  }

  Future<List<PurchaseReturnItem>> itemsForPurchaseInvoiceProduct(
      int invoiceId, int productId) {
    return guard(purchaseItemsTable, () async {
      final rows = await _db.rawQuery(
        'SELECT i.* FROM $purchaseItemsTable i '
        'JOIN $purchaseTable r ON r.id = i.return_id '
        'WHERE r.invoice_id = ? AND i.product_id = ?',
        [invoiceId, productId],
      );
      return rows.map(PurchaseReturnItem.fromMap).toList();
    });
  }
}
