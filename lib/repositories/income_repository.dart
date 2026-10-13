import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/income_entry.dart';
import 'repo_utils.dart';

/// CRUD for other-income entries. Posting (ledger/balance effects) goes
/// through [AccountingService], never this class alone.
class IncomeRepository {
  IncomeRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'income_entries';

  /// Inserts an income row. Intended for use inside an [AccountingService]
  /// transaction.
  Future<IncomeEntry> insert(DatabaseExecutor db, IncomeEntry entry) {
    return guard(table, () async {
      final id = await db.insert(
        table,
        entry.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
      await AuditLog.log(db,
          action: 'post',
          entity: table,
          entityId: id,
          details: '${entry.amountPaisa} paisa');
      return entry.copyWith(id: id);
    });
  }

  Future<List<IncomeEntry>> list({
    DateTime? from,
    DateTime? to,
    int? accountId,
    int limit = 100,
    int offset = 0,
  }) {
    return guard(table, () async {
      final where = <String>[];
      final args = <Object?>[];
      if (from != null) {
        where.add('date >= ?');
        args.add(from.millisecondsSinceEpoch);
      }
      if (to != null) {
        where.add('date < ?');
        args.add(to.millisecondsSinceEpoch);
      }
      if (accountId != null) {
        where.add('account_id = ?');
        args.add(accountId);
      }
      final rows = await _db.query(
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(IncomeEntry.fromMap).toList();
    });
  }
}
