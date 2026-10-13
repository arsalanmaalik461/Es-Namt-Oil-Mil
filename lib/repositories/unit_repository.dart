import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';
import '../db/audit_log.dart';
import '../models/unit.dart';
import '../models/unit_conversion.dart';
import 'repo_utils.dart';

/// Units and conversions. Owns all quantity-conversion math (quantities only —
/// never money).
class UnitRepository {
  UnitRepository(this._db);
  final DatabaseExecutor _db;

  Future<List<Unit>> getAll() {
    return guard('units', () async {
      final rows = await _db.query('units', orderBy: 'name ASC');
      return rows.map(Unit.fromMap).toList();
    });
  }

  Future<Unit?> getById(int id) {
    return guard('units', () async {
      final rows =
          await _db.query('units', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Unit.fromMap(rows.first);
    });
  }

  Future<Unit?> getBySymbol(String symbol) {
    return guard('units', () async {
      final rows = await _db.query('units',
          where: 'symbol = ?', whereArgs: [symbol], limit: 1);
      if (rows.isEmpty) return null;
      return Unit.fromMap(rows.first);
    });
  }

  Future<int> insertUnit(Unit unit) {
    return guard('units', () async {
      final id = await _db.insert('units', unit.toMap()..remove('id'));
      await AuditLog.log(_db,
          action: 'create', entity: 'units', entityId: id, details: unit.name);
      return id;
    });
  }

  Future<List<UnitConversion>> listConversions() {
    return guard('unit_conversions', () async {
      final rows = await _db.query('unit_conversions');
      return rows.map(UnitConversion.fromMap).toList();
    });
  }

  Future<int> insertConversion(UnitConversion conversion) {
    return guard('unit_conversions', () async {
      final id = await _db.insert(
          'unit_conversions', conversion.toMap()..remove('id'));
      await AuditLog.log(_db,
          action: 'create',
          entity: 'unit_conversions',
          entityId: id,
          details:
              '${conversion.fromUnitId} -> ${conversion.toUnitId} x${conversion.factor}');
      return id;
    });
  }

  Future<void> deleteConversion(int id) {
    return guard('unit_conversions', () async {
      await _db.delete('unit_conversions', where: 'id = ?', whereArgs: [id]);
      await AuditLog.log(_db,
          action: 'delete', entity: 'unit_conversions', entityId: id);
    });
  }

  /// Direct factor from [fromUnitId] to [toUnitId], or null when unknown.
  /// The reverse direction is derived as 1/factor automatically.
  Future<double?> getFactor(int fromUnitId, int toUnitId) {
    return guard('unit_conversions', () async {
      if (fromUnitId == toUnitId) return 1.0;
      var rows = await _db.query(
        'unit_conversions',
        columns: ['factor'],
        where: 'from_unit_id = ? AND to_unit_id = ?',
        whereArgs: [fromUnitId, toUnitId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return ((rows.first['factor'] as num?) ?? 0).toDouble();
      }
      rows = await _db.query(
        'unit_conversions',
        columns: ['factor'],
        where: 'from_unit_id = ? AND to_unit_id = ?',
        whereArgs: [toUnitId, fromUnitId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final f = ((rows.first['factor'] as num?) ?? 0).toDouble();
        if (f > 0) return 1.0 / f;
      }
      return null;
    });
  }

  /// Converts [qty] from [fromUnitId] to [toUnitId].
  /// Throws [ValidationException] (`error.noConversion`) when no conversion
  /// path exists.
  Future<double> convertQty(double qty, int fromUnitId, int toUnitId) async {
    final factor = await getFactor(fromUnitId, toUnitId);
    if (factor == null) {
      throw ValidationException('error.noConversion', {
        'fromUnitId': fromUnitId,
        'toUnitId': toUnitId,
      });
    }
    return qty * factor;
  }
}
