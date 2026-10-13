import '../utils/time.dart';

/// Lifecycle of a sale/purchase invoice. Stored as the same strings in DB.
enum InvoiceStatus {
  draft('draft'),
  unpaid('unpaid'),
  partial('partial'),
  paid('paid'),
  returned('returned'),
  cancelled('cancelled');

  final String dbValue;
  const InvoiceStatus(this.dbValue);

  static InvoiceStatus fromDb(String? value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

/// A posted (or draft) sales invoice to a customer.
///
/// Money fields are integer paisa. `total = subtotal - discount + tax`.
/// [idempotencyKey] is UNIQUE — re-posting with the same key returns the
/// existing invoice instead of creating a duplicate.
class SalesInvoice {
  final int? id;
  final String invoiceNo;
  final int customerId;
  final DateTime date;
  final InvoiceStatus status;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int totalPaisa;
  final int paidPaisa;
  final String? idempotencyKey;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SalesInvoice({
    this.id,
    required this.invoiceNo,
    required this.customerId,
    required this.date,
    this.status = InvoiceStatus.draft,
    this.subtotalPaisa = 0,
    this.discountPaisa = 0,
    this.taxPaisa = 0,
    this.totalPaisa = 0,
    this.paidPaisa = 0,
    this.idempotencyKey,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Amount still due on this invoice (never negative).
  int get duePaisa => (totalPaisa - paidPaisa).clamp(0, totalPaisa);

  SalesInvoice copyWith({
    int? id,
    String? invoiceNo,
    int? customerId,
    DateTime? date,
    InvoiceStatus? status,
    int? subtotalPaisa,
    int? discountPaisa,
    int? taxPaisa,
    int? totalPaisa,
    int? paidPaisa,
    String? idempotencyKey,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      status: status ?? this.status,
      subtotalPaisa: subtotalPaisa ?? this.subtotalPaisa,
      discountPaisa: discountPaisa ?? this.discountPaisa,
      taxPaisa: taxPaisa ?? this.taxPaisa,
      totalPaisa: totalPaisa ?? this.totalPaisa,
      paidPaisa: paidPaisa ?? this.paidPaisa,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'invoice_no': invoiceNo,
      'customer_id': customerId,
      'date': toEpochMillis(date),
      'status': status.dbValue,
      'subtotal_paisa': subtotalPaisa,
      'discount_paisa': discountPaisa,
      'tax_paisa': taxPaisa,
      'total_paisa': totalPaisa,
      'paid_paisa': paidPaisa,
      'idempotency_key': idempotencyKey,
      'notes': notes,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
      'updated_at': updatedAt == null ? null : toEpochMillis(updatedAt!),
    };
  }

  factory SalesInvoice.fromMap(Map<String, Object?> map) {
    return SalesInvoice(
      id: map['id'] as int?,
      invoiceNo: (map['invoice_no'] as String?) ?? '',
      customerId: (map['customer_id'] as int?) ?? 0,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      status: InvoiceStatus.fromDb(map['status'] as String?),
      subtotalPaisa: (map['subtotal_paisa'] as int?) ?? 0,
      discountPaisa: (map['discount_paisa'] as int?) ?? 0,
      taxPaisa: (map['tax_paisa'] as int?) ?? 0,
      totalPaisa: (map['total_paisa'] as int?) ?? 0,
      paidPaisa: (map['paid_paisa'] as int?) ?? 0,
      idempotencyKey: map['idempotency_key'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
      updatedAt: map['updated_at'] == null
          ? null
          : fromEpochMillis((map['updated_at'] as int?) ?? 0),
    );
  }
}

/// One line of a sales invoice.
///
/// [qty] is in [unitId] (may differ from the product's base unit).
/// [lineTotalPaisa] = rounded(qty × unitPricePaisa × (1 − discountPercent/100)).
class SalesInvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final double discountPercent;
  final int lineTotalPaisa;

  const SalesInvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    this.discountPercent = 0,
    this.lineTotalPaisa = 0,
  });

  SalesInvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    double? qty,
    int? unitId,
    int? unitPricePaisa,
    double? discountPercent,
    int? lineTotalPaisa,
  }) {
    return SalesInvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitId: unitId ?? this.unitId,
      unitPricePaisa: unitPricePaisa ?? this.unitPricePaisa,
      discountPercent: discountPercent ?? this.discountPercent,
      lineTotalPaisa: lineTotalPaisa ?? this.lineTotalPaisa,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'qty': qty,
      'unit_id': unitId,
      'unit_price_paisa': unitPricePaisa,
      'discount_percent': discountPercent,
      'line_total_paisa': lineTotalPaisa,
    };
  }

  factory SalesInvoiceItem.fromMap(Map<String, Object?> map) {
    return SalesInvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: (map['product_id'] as int?) ?? 0,
      qty: ((map['qty'] as num?) ?? 0).toDouble(),
      unitId: (map['unit_id'] as int?) ?? 0,
      unitPricePaisa: (map['unit_price_paisa'] as int?) ?? 0,
      discountPercent: ((map['discount_percent'] as num?) ?? 0).toDouble(),
      lineTotalPaisa: (map['line_total_paisa'] as int?) ?? 0,
    );
  }
}
