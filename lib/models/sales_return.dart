import '../utils/time.dart';

/// Goods returned BY a customer (restocked; customer receivable reduced).
///
/// Posted as: credit(customer) / debit(income, category 'sales_returns').
/// The original invoice is NOT modified (except its status may become
/// `returned` when fully returned) — the return is its own document.
class SalesReturn {
  final int? id;
  final String returnNo;
  final DateTime date;
  final int? invoiceId;
  final int customerId;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int totalPaisa;
  final String? reason;
  final String? idempotencyKey;
  final String journalKey;
  final DateTime? createdAt;

  const SalesReturn({
    this.id,
    required this.returnNo,
    required this.date,
    this.invoiceId,
    required this.customerId,
    this.subtotalPaisa = 0,
    this.discountPaisa = 0,
    this.taxPaisa = 0,
    this.totalPaisa = 0,
    this.reason,
    this.idempotencyKey,
    required this.journalKey,
    this.createdAt,
  });

  SalesReturn copyWith({
    int? id,
    String? returnNo,
    DateTime? date,
    int? invoiceId,
    int? customerId,
    int? subtotalPaisa,
    int? discountPaisa,
    int? taxPaisa,
    int? totalPaisa,
    String? reason,
    String? idempotencyKey,
    String? journalKey,
    DateTime? createdAt,
  }) {
    return SalesReturn(
      id: id ?? this.id,
      returnNo: returnNo ?? this.returnNo,
      date: date ?? this.date,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
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
      'customer_id': customerId,
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

  factory SalesReturn.fromMap(Map<String, Object?> map) {
    return SalesReturn(
      id: map['id'] as int?,
      returnNo: (map['return_no'] as String?) ?? '',
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      invoiceId: map['invoice_id'] as int?,
      customerId: (map['customer_id'] as int?) ?? 0,
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

/// One returned line (restocked at [unitPricePaisa] per [unitId]).
class SalesReturnItem {
  final int? id;
  final int? returnId;
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final int lineTotalPaisa;

  const SalesReturnItem({
    this.id,
    this.returnId,
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    this.lineTotalPaisa = 0,
  });

  SalesReturnItem copyWith({
    int? id,
    int? returnId,
    int? productId,
    double? qty,
    int? unitId,
    int? unitPricePaisa,
    int? lineTotalPaisa,
  }) {
    return SalesReturnItem(
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

  factory SalesReturnItem.fromMap(Map<String, Object?> map) {
    return SalesReturnItem(
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
