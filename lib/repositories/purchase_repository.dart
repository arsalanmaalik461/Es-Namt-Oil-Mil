import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/purchase_invoice.dart';
import '../models/sales_invoice.dart' show InvoiceStatus;
import 'repo_utils.dart';

/// CRUD for purchase invoices + items. Posting (ledger/stock/balance effects)
/// goes through [AccountingService], never this class alone.
class PurchaseRepository {
  PurchaseRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'purchase_invoices';
  static const String itemsTable = 'purchase_invoice_items';

  /// Inserts an invoice with its items. Intended for use inside an
  /// [AccountingService] transaction.
  Future<PurchaseInvoice> insertInvoice(
    DatabaseExecutor db,
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) {
    return guard(table, () async {
      final timestamp = now();
      final id = await db.insert(
        table,
        invoice.toMap()
          ..remove('id')
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      for (final item in items) {
        await db.insert(
            itemsTable,
            item.toMap()
              ..remove('id')
              ..['invoice_id'] = id);
      }
      await AuditLog.log(db,
          action: 'post',
          entity: table,
          entityId: id,
          details: invoice.invoiceNo);
      return invoice.copyWith(id: id);
    });
  }

  Future<PurchaseInvoice?> findByIdempotencyKey(String key) {
    return guard(table, () async {
      final rows = await _db.query(table,
          where: 'idempotency_key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) return null;
      return PurchaseInvoice.fromMap(rows.first);
    });
  }

  Future<PurchaseInvoice?> findByInvoiceNo(String invoiceNo) {
    return guard(table, () async {
      final rows = await _db.query(table,
          where: 'invoice_no = ?', whereArgs: [invoiceNo], limit: 1);
      if (rows.isEmpty) return null;
      return PurchaseInvoice.fromMap(rows.first);
    });
  }

  Future<PurchaseInvoice?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return PurchaseInvoice.fromMap(rows.first);
    });
  }

  Future<List<PurchaseInvoiceItem>> getItems(int invoiceId) {
    return guard(itemsTable, () async {
      final rows = await _db.query(itemsTable,
          where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'id ASC');
      return rows.map(PurchaseInvoiceItem.fromMap).toList();
    });
  }

  Future<List<PurchaseInvoice>> list({
    int? supplierId,
    DateTime? from,
    DateTime? to,
    InvoiceStatus? status,
    bool excludeDrafts = true,
    int limit = 50,
    int offset = 0,
  }) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (supplierId != null) {
        where.add('supplier_id = ?');
        args.add(supplierId);
      }
      if (from != null) {
        where.add('date >= ?');
        args.add(from.millisecondsSinceEpoch);
      }
      if (to != null) {
        where.add('date < ?');
        args.add(to.millisecondsSinceEpoch);
      }
      if (status != null) {
        where.add('status = ?');
        args.add(status.dbValue);
      } else if (excludeDrafts) {
        where.add("status != 'draft'");
      }
      final rows = await _db.query(
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(PurchaseInvoice.fromMap).toList();
    });
  }

  /// Updates paid amount + status. Called ONLY by [AccountingService].
  Future<void> updatePaid(
    DatabaseExecutor db,
    int id,
    int paidPaisa,
    InvoiceStatus status,
  ) {
    return guard(table, () async {
      await db.update(
        table,
        {
          'paid_paisa': paidPaisa,
          'status': status.dbValue,
          'updated_at': now(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Updates status only. Called ONLY by [AccountingService].
  Future<void> updateStatus(DatabaseExecutor db, int id, InvoiceStatus status) {
    return guard(table, () async {
      await db.update(
        table,
        {'status': status.dbValue, 'updated_at': now()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ------------------------------------------------------------ drafts

  Future<int> createDraft(
      PurchaseInvoice draft, List<PurchaseInvoiceItem> items) {
    return guard(table, () async {
      final timestamp = now();
      final id = await _db.insert(
        table,
        draft.toMap()
          ..remove('id')
          ..['status'] = InvoiceStatus.draft.dbValue
          ..['created_at'] = timestamp
          ..['updated_at'] = timestamp,
      );
      for (final item in items) {
        await _db.insert(
            itemsTable,
            item.toMap()
              ..remove('id')
              ..['invoice_id'] = id);
      }
      return id;
    });
  }

  Future<void> updateDraft(
      int id, PurchaseInvoice draft, List<PurchaseInvoiceItem> items) {
    return guard(table, () async {
      await _db.update(
        table,
        draft.toMap()
          ..remove('id')
          ..remove('invoice_no')
          ..remove('status')
          ..remove('paid_paisa')
          ..['updated_at'] = now(),
        where: "id = ? AND status = 'draft'",
        whereArgs: [id],
      );
      await _db.delete(itemsTable, where: 'invoice_id = ?', whereArgs: [id]);
      for (final item in items) {
        await _db.insert(
            itemsTable,
            item.toMap()
              ..remove('id')
              ..['invoice_id'] = id);
      }
    });
  }

  Future<void> deleteDraft(int id) {
    return guard(table, () async {
      await _db
          .delete(table, where: "id = ? AND status = 'draft'", whereArgs: [id]);
      await AuditLog.log(_db, action: 'delete', entity: table, entityId: id);
    });
  }
}
