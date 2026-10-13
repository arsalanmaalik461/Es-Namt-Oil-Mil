import '../utils/time.dart';

/// Well-known movement types stored in `inventory_movements.movement_type`.
abstract final class MovementTypes {
  static const sale = 'sale';
  static const purchase = 'purchase';
  static const productionInput = 'production_input';
  static const productionOutput = 'production_output';
  static const adjustment = 'adjustment';
  static const salesReturn = 'sales_return';
  static const purchaseReturn = 'purchase_return';
}

/// Well-known reference types linking a movement to its source document.
abstract final class ReferenceTypes {
  static const sale = 'sale';
  static const purchase = 'purchase';
  static const payment = 'payment';
  static const expense = 'expense';
  static const income = 'income';
  static const transfer = 'transfer';
  static const production = 'production';
  static const adjustment = 'adjustment';
  static const salesReturn = 'sales_return';
  static const purchaseReturn = 'purchase_return';
  static const udhaar = 'udhaar';
}

/// One stock movement. This table is the SOURCE OF TRUTH for stock history;
/// `products.stock_qty` is a cache.
///
/// [qtyChange] is signed in the original [unitId] (e.g. -2.5 maund on a sale).
/// [qtyChangeBase] is the same movement signed in the product's base unit —
/// aggregations and cache updates always use [qtyChangeBase].
class InventoryMovement {
  final int? id;
  final DateTime date;
  final int productId;
  final double qtyChange;
  final double qtyChangeBase;
  final int unitId;
  final String movementType;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final DateTime? createdAt;

  const InventoryMovement({
    this.id,
    required this.date,
    required this.productId,
    required this.qtyChange,
    required this.qtyChangeBase,
    required this.unitId,
    required this.movementType,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.createdAt,
  });

  InventoryMovement copyWith({
    int? id,
    DateTime? date,
    int? productId,
    double? qtyChange,
    double? qtyChangeBase,
    int? unitId,
    String? movementType,
    String? referenceType,
    int? referenceId,
    String? notes,
    DateTime? createdAt,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      date: date ?? this.date,
      productId: productId ?? this.productId,
      qtyChange: qtyChange ?? this.qtyChange,
      qtyChangeBase: qtyChangeBase ?? this.qtyChangeBase,
      unitId: unitId ?? this.unitId,
      movementType: movementType ?? this.movementType,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': toEpochMillis(date),
      'product_id': productId,
      'qty_change': qtyChange,
      'qty_change_base': qtyChangeBase,
      'unit_id': unitId,
      'movement_type': movementType,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory InventoryMovement.fromMap(Map<String, Object?> map) {
    return InventoryMovement(
      id: map['id'] as int?,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      productId: (map['product_id'] as int?) ?? 0,
      qtyChange: ((map['qty_change'] as num?) ?? 0).toDouble(),
      qtyChangeBase: ((map['qty_change_base'] as num?) ?? 0).toDouble(),
      unitId: (map['unit_id'] as int?) ?? 0,
      movementType: (map['movement_type'] as String?) ?? '',
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}
