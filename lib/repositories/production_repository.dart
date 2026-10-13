import 'package:sqflite/sqflite.dart';

import '../db/audit_log.dart';
import '../models/production_batch.dart';
import 'repo_utils.dart';

/// CRUD for production batches + input/output lines. Posting (stock and cost
/// effects) goes through [AccountingService], never this class alone.
class ProductionRepository {
  ProductionRepository(this._db);
  final DatabaseExecutor _db;

  static const String table = 'production_batches';
  static const String inputsTable = 'production_inputs';
  static const String outputsTable = 'production_outputs';

  /// Inserts a batch with its lines. Intended for use inside an
  /// [AccountingService] transaction.
  Future<ProductionBatch> insertBatch(
    DatabaseExecutor db,
    ProductionBatch batch,
    List<ProductionInput> inputs,
    List<ProductionOutput> outputs,
  ) {
    return guard(table, () async {
      final id = await db.insert(
        table,
        batch.toMap()
          ..remove('id')
          ..['created_at'] = now(),
      );
      for (final input in inputs) {
        await db.insert(
            inputsTable,
            input.toMap()
              ..remove('id')
              ..['batch_id'] = id);
      }
      for (final output in outputs) {
        await db.insert(
            outputsTable,
            output.toMap()
              ..remove('id')
              ..['batch_id'] = id);
      }
      await AuditLog.log(db,
          action: 'post', entity: table, entityId: id, details: batch.batchNo);
      return batch.copyWith(id: id);
    });
  }

  Future<ProductionBatch?> getBatch(int id) {
    return guard(table, () async {
      final rows =
          await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return ProductionBatch.fromMap(rows.first);
    });
  }

  Future<List<ProductionInput>> getInputs(int batchId) {
    return guard(inputsTable, () async {
      final rows = await _db.query(inputsTable,
          where: 'batch_id = ?', whereArgs: [batchId], orderBy: 'id ASC');
      return rows.map(ProductionInput.fromMap).toList();
    });
  }

  Future<List<ProductionOutput>> getOutputs(int batchId) {
    return guard(outputsTable, () async {
      final rows = await _db.query(outputsTable,
          where: 'batch_id = ?', whereArgs: [batchId], orderBy: 'id ASC');
      return rows.map(ProductionOutput.fromMap).toList();
    });
  }

  Future<List<ProductionBatch>> list({
    DateTime? from,
    DateTime? to,
    int limit = 50,
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
      final rows = await _db.query(
        table,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(ProductionBatch.fromMap).toList();
    });
  }

  /// Stores the computed yield %. Called ONLY by [AccountingService].
  Future<void> updateYield(DatabaseExecutor db, int id, double? yieldPct) {
    return guard(table, () async {
      await db.update(table, {'yield_pct': yieldPct},
          where: 'id = ?', whereArgs: [id]);
    });
  }
}
