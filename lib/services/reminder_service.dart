import '../db/database.dart';
import '../models/ledger_entry.dart';
import '../utils/time.dart';

/// Due-date and overdue tracking for khata entries.
///
/// * [setDueDate] stamps a due date on every entry of a journal.
/// * [overdueEntries] lists receivable entries past their due date.
/// * [remindersSummary] powers the "Reminders (N overdue)" card and the
///   reminders screen: one row per customer with overdue amount + nearest
///   due date, sorted by urgency.
class ReminderService {
  ReminderService._();

  /// Sets [dueDate] on all entries of [journalKey]. Pass null to clear.
  static Future<void> setDueDate(String journalKey, DateTime? dueDate) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ledger_entries',
      {'due_date': dueDate == null ? null : toEpochMillis(dueDate)},
      where: 'journal_key = ?',
      whereArgs: [journalKey],
    );
  }

  /// All non-voided customer-receivable entries whose due date has passed.
  /// Ordered by due date (most overdue first).
  static Future<List<LedgerEntry>> overdueEntries({int limit = 200}) async {
    final db = await DatabaseHelper.instance.database;
    final now = nowMillis();
    final rows = await db.query(
      'ledger_entries',
      where: 'account_type = ? '
          'AND COALESCE(voided, 0) = 0 '
          'AND due_date IS NOT NULL '
          'AND due_date < ? '
          'AND debit_paisa > 0',
      whereArgs: [AccountType.customer.dbValue, now],
      orderBy: 'due_date ASC',
      limit: limit,
    );
    return rows.map(LedgerEntry.fromMap).toList();
  }

  /// Entries due within the next [daysAhead] days (upcoming, not yet overdue).
  static Future<List<LedgerEntry>> upcomingEntries({int daysAhead = 7}) async {
    final db = await DatabaseHelper.instance.database;
    final now = nowMillis();
    final horizon = now + daysAhead * 24 * 60 * 60 * 1000;
    final rows = await db.query(
      'ledger_entries',
      where: 'account_type = ? '
          'AND COALESCE(voided, 0) = 0 '
          'AND due_date IS NOT NULL '
          'AND due_date >= ? AND due_date < ? '
          'AND debit_paisa > 0',
      whereArgs: [AccountType.customer.dbValue, now, horizon],
      orderBy: 'due_date ASC',
      limit: 200,
    );
    return rows.map(LedgerEntry.fromMap).toList();
  }

  /// Per-customer overdue summary for the reminders screen.
  ///
  /// Returns rows sorted by nearest due date first:
  /// `{customerId, overduePaisa, nearestDueDate, entryCount}`.
  /// Customer names are resolved by the caller via CustomerRepository.
  static Future<List<CustomerReminder>> remindersSummary() async {
    final db = await DatabaseHelper.instance.database;
    final now = nowMillis();
    final rows = await db.rawQuery(
      'SELECT account_id AS customerId, '
      'SUM(debit_paisa - credit_paisa) AS overduePaisa, '
      'MIN(due_date) AS nearestDueDate, '
      'COUNT(*) AS entryCount '
      'FROM ledger_entries '
      'WHERE account_type = ? '
      'AND COALESCE(voided, 0) = 0 '
      'AND due_date IS NOT NULL '
      'AND due_date < ? '
      'AND debit_paisa > 0 '
      'GROUP BY account_id '
      'ORDER BY nearestDueDate ASC',
      [AccountType.customer.dbValue, now],
    );
    return rows
        .map((r) => CustomerReminder(
              customerId: (r['customerId'] as int?) ?? 0,
              overduePaisa: ((r['overduePaisa'] as num?) ?? 0).toInt(),
              nearestDueDate:
                  fromEpochMillis(((r['nearestDueDate'] as int?) ?? 0)),
              entryCount: ((r['entryCount'] as int?) ?? 0),
            ))
        .where((r) => r.overduePaisa > 0)
        .toList();
  }

  /// Count of customers with overdue amounts (for the "N overdue" badge).
  static Future<int> overdueCustomerCount() async {
    final list = await remindersSummary();
    return list.length;
  }

  /// Total overdue paisa across all customers.
  static Future<int> totalOverduePaisa() async {
    final list = await remindersSummary();
    var total = 0;
    for (final r in list) {
      total += r.overduePaisa;
    }
    return total;
  }
}

/// One row of the reminders screen: a customer with overdue dues.
class CustomerReminder {
  final int customerId;
  final int overduePaisa;
  final DateTime nearestDueDate;
  final int entryCount;

  const CustomerReminder({
    required this.customerId,
    required this.overduePaisa,
    required this.nearestDueDate,
    required this.entryCount,
  });

  /// Whole days past the nearest due date.
  int get daysOverdue {
    final diff = DateTime.now().difference(nearestDueDate).inDays;
    return diff < 0 ? 0 : diff;
  }
}
