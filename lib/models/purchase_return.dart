import '../utils/time.dart';

/// Goods returned TO a supplier (stock reduced; supplier payable reduced).
///
/// Posted as: debit(supplier) / credit(expense, category 'purchase_returns').
/// The original purchase invoice is NOT modified (except its status may become
/// `returned` when fully returned).
class PurchaseReturn {
  final int? id;
  final String returnNo;
  final DateTime date;
  final int? invoiceId;
  final int supplierId;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int totalPaisa;
  final String? reason;
  final String? idempotencyKey;
  final String journalKey;
  final DateTime? createdAt;

  const PurchaseReturn({
    this.id,
    required this.returnNo,
    required this.date,
    this.invoiceId,
    required this.supplierId,
    this.subtotalPaisa = 0,
    this.discountPaisa = 0,
    this.taxPaisa = 0,
    this.totalPaisa = 0,
    this.reason,
    this.idempotencyKey,
    required this.journalKey,
    this.createdAt,
  });

  PurchaseReturn copyWith({
    int? id,
    String? returnNo,
    DateTime? date,
    int? invoiceId,
    int? supplierId,
    int? subtotalPaisa,
    int? discountPaisa,
    int? taxPaisa,
    int? totalPaisa,
    String? reason,
    String? idempotencyKey,
    String? journalKey,
    DateTime? createdAt,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      returnNo: returnNo ?? this.returnNo,
      date: date ?? this.date,
      invoiceId: invoiceId ?? this.invoiceId,
      supplierId: supplierId ?? this.supplierId,
      subtotalPaisa: subtotalPaisa ?? this.subtotalPaisa,
      discountPaisa: discountPaisa ?? this.discountPaisa,
      taxPaisa: taxPaisa ?? this.taxPaisa,
      totalPaisa: totalPaisa ?? this.totalPaisa,
      reason: reason ?? this.reason,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      journalKey: journalKey ?? this.journalKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'return_no': returnNo,
      'date': toEpochMillis(date),
      'invoice_id': invoiceId,
      'supplier_id': supplierId,
      'subtotal_paisa': subtotalPaisa,
      'discount_paisa': discountPaisa,
      'tax_paisa': taxPaisa,
      'total_paisa': totalPaisa,
      'reason': reason,
      'idempotency_key': idempotencyKey,
      'journal_key': journalKey,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory PurchaseReturn.fromMap(Map<String, Object?> map) {
    return PurchaseReturn(
      id: map['id'] as int?,
      returnNo: (map['return_no'] as String?) ?? '',
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      invoiceId: map['invoice_id'] as int?,
      supplierId: (map['supplier_id'] as int?) ?? 0,
      subtotalPaisa: (map['subtotal_paisa'] as int?) ?? 0,
      discountPaisa: (map['discount_paisa'] as int?) ?? 0,
      taxPaisa: (map['tax_paisa'] as int?) ?? 0,
      totalPaisa: (map['total_paisa'] as int?) ?? 0,
      reason: map['reason'] as String?,
      idempotencyKey: map['idempotency_key'] as String?,
      journalKey: (map['journal_key'] as String?) ?? '',
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}

/// One purchase-return line (removed from stock).
class PurchaseReturnItem {
  final int? id;
  final int? returnId;
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final int lineTotalPaisa;

  const PurchaseReturnItem({
    this.id,
    this.returnId,
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    this.lineTotalPaisa = 0,
  });

  PurchaseReturnItem copyWith({
    int? id,
    int? returnId,
    int? productId,
    double? qty,
    int? unitId,
    int? unitPricePaisa,
    int? lineTotalPaisa,
  }) {
    return PurchaseReturnItem(
      id: id ?? this.id,
      returnId: returnId ?? this.returnId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitId: unitId ?? this.unitId,
      unitPricePaisa: unitPricePaisa ?? this.unitPricePaisa,
      lineTotalPaisa: lineTotalPaisa ?? this.lineTotalPaisa,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'return_id': returnId,
      'product_id': productId,
      'qty': qty,
      'unit_id': unitId,
      'unit_price_paisa': unitPricePaisa,
      'line_total_paisa': lineTotalPaisa,
    };
  }

  factory PurchaseReturnItem.fromMap(Map<String, Object?> map) {
    return PurchaseReturnItem(
      id: map['id'] as int?,
      returnId: map['return_id'] as int?,
      productId: (map['product_id'] as int?) ?? 0,
      qty: ((map['qty'] as num?) ?? 0).toDouble(),
      unitId: (map['unit_id'] as int?) ?? 0,
      unitPricePaisa: (map['unit_price_paisa'] as int?) ?? 0,
      lineTotalPaisa: (map['line_total_paisa'] as int?) ?? 0,
    );
  }
}
