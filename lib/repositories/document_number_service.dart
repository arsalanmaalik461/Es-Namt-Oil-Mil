import 'package:sqflite/sqflite.dart';

import 'repo_utils.dart';

/// Generates human-readable, gap-tolerant document numbers (`SI-000001`).
///
/// MUST be called inside the posting transaction: the increment
/// (UPDATE … SET last_number = last_number + 1) and the read happen on the
/// same [DatabaseExecutor], so concurrent postings can never reuse a number.
/// Numbers may have gaps after a rolled-back transaction — that is by design.
class DocumentNumberService {
  static const String salesInvoice = 'SI';
  static const String purchaseInvoice = 'PI';
  static const String salesReturn = 'SR';
  static const String purchaseReturn = 'PR';
  static const String payment = 'PMT';
  static const String productionBatch = 'PB';
  static const String ledgerEntry = 'LE';

  /// Returns the next formatted number for [prefix], e.g. `SI-000001`.
  Future<String> next(DatabaseExecutor db, String prefix, {int padWidth = 6}) {
    return guard('document_sequences', () async {
      final updated = await db.rawUpdate(
        'UPDATE document_sequences SET last_number = last_number + 1 WHERE prefix = ?',
        [prefix],
      );
      int n;
      if (updated == 0) {
        await db
            .insert('document_sequences', {'prefix': prefix, 'last_number': 1});
        n = 1;
      } else {
        final rows = await db.query(
          'document_sequences',
          columns: ['last_number'],
          where: 'prefix = ?',
          whereArgs: [prefix],
          limit: 1,
        );
        n = (rows.first['last_number'] as int?) ?? 1;
      }
      return '$prefix-${n.toString().padLeft(padWidth, '0')}';
    });
  }

  /// Peeks at the next number WITHOUT reserving it (for display only).
  Future<String> peek(DatabaseExecutor db, String prefix, {int padWidth = 6}) {
    return guard('document_sequences', () async {
      final rows = await db.query(
        'document_sequences',
        columns: ['last_number'],
        where: 'prefix = ?',
        whereArgs: [prefix],
        limit: 1,
      );
      final n =
          ((rows.isEmpty ? null : rows.first['last_number']) as int? ?? 0) + 1;
      return '$prefix-${n.toString().padLeft(padWidth, '0')}';
    });
  }
}
