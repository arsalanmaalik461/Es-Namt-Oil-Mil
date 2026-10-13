import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/payment.dart';
import 'repo_utils.dart';

/// CRUD for payments + allocations. Posting (ledger/balance effects) goes
/// through [AccountingService], never this class alone.
class PaymentRepository {
  PaymentRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'payments';
  static const String allocTable = 'payment_allocations';

  /// Inserts a payment row. Intended for use inside an [AccountingService]
  /// transaction.
  Future<Payment> insert(DatabaseExecutor db, Payment payment) {
    return guard(table, () async {
      final id = await db.insert(
        table,
        payment.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
      await AuditLog.log(db,
          action: 'post',
          entity: table,
          entityId: id,
          details: '${payment.direction.dbValue} ${payment.amountPaisa} paisa');
      return payment.copyWith(id: id);
    });
  }

  Future<Payment?> findByIdempotencyKey(String key) {
    return guard(table, () async {
      final rows = await _db.query(table,
          where: 'idempotency_key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) return null;
      return Payment.fromMap(rows.first);
    });
  }

  Future<Payment?> getById(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Payment.fromMap(rows.first);
    });
  }

  Future<List<Payment>> list({
    PartyType? partyType,
    int? partyId,
    int? accountId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (partyType != null) {
        where.add('party_type = ?');
        args.add(partyType.dbValue);
      }
      if (partyId != null) {
        where.add('party_id = ?');
        args.add(partyId);
      }
      if (accountId != null) {
        where.add('account_id = ?');
        args.add(accountId);
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
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(Payment.fromMap).toList();
    });
  }

  Future<void> insertAllocation(
      DatabaseExecutor db, PaymentAllocation allocation) {
    return guard(allocTable, () async {
      await db.insert(allocTable, allocation.toMap()..remove('id'));
    });
  }

  Future<List<PaymentAllocation>> allocationsForPayment(int paymentId) {
    return guard(allocTable, () async {
      final rows = await _db.query(allocTable,
          where: 'payment_id = ?', whereArgs: [paymentId], orderBy: 'id ASC');
      return rows.map(PaymentAllocation.fromMap).toList();
    });
  }

  /// Total paisa already allocated to an invoice (for over-allocation checks).
  Future<int> allocatedTotalForInvoice(String invoiceType, int invoiceId) {
    return guard(allocTable, () async {
      final rows = await _db.rawQuery(
        'SELECT COALESCE(SUM(amount_paisa), 0) AS s FROM $allocTable '
        'WHERE invoice_type = ? AND invoice_id = ?',
        [invoiceType, invoiceId],
      );
      return (rows.first['s'] as int?) ?? 0;
    });
  }
}
