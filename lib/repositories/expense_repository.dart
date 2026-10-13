import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/expense_category.dart';
import '../models/expense_entry.dart';
import 'repo_utils.dart';

/// CRUD for expenses and expense categories. Posting (ledger/balance effects)
/// goes through [AccountingService], never this class alone.
class ExpenseRepository {
  ExpenseRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'expenses';
  static const String categoryTable = 'expense_categories';

  /// Inserts an expense row. Intended for use inside an [AccountingService]
  /// transaction.
  Future<ExpenseEntry> insert(DatabaseExecutor db, ExpenseEntry entry) {
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

  Future<List<ExpenseEntry>> list({
    DateTime? from,
    DateTime? to,
    int? categoryId,
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
      if (categoryId != null) {
        where.add('category_id = ?');
        args.add(categoryId);
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
      return rows.map(ExpenseEntry.fromMap).toList();
    });
  }

  // ------------------------------------------------------------ categories

  Future<List<ExpenseCategory>> getCategories({bool activeOnly = true}) {
    return guard(categoryTable, () async {
      final rows = await _db.query(
        categoryTable,
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'name ASC',
      );
      return rows.map(ExpenseCategory.fromMap).toList();
    });
  }

  Future<ExpenseCategory?> getCategoryById(int id) {
    return guard(categoryTable, () async {
      final rows = await _db.query(categoryTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return ExpenseCategory.fromMap(rows.first);
    });
  }

  Future<int> insertCategory(ExpenseCategory category) {
    return guard(categoryTable, () async {
      final id =
          await _db.insert(categoryTable, category.toMap()..remove('id'));
      await AuditLog.log(_db,
          action: 'create',
          entity: categoryTable,
          entityId: id,
          details: category.name);
      return id;
    });
  }

  Future<void> setCategoryActive(int id, bool active) {
    return guard(categoryTable, () async {
      await _db.update(categoryTable, {'is_active': active ? 1 : 0},
          where: 'id = ?', whereArgs: [id]);
    });
  }
}
