import '../utils/time.dart';

/// Who the payment is with.
enum PartyType {
  customer('customer'),
  supplier('supplier');

  final String dbValue;
  const PartyType(this.dbValue);

  static PartyType fromDb(String? value) {
    return PartyType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PartyType.customer,
    );
  }
}

/// Direction of money relative to the business.
enum PaymentDirection {
  received('received'), // money came IN (from a customer)
  paid('paid'); // money went OUT (to a supplier)

  final String dbValue;
  const PaymentDirection(this.dbValue);

  static PaymentDirection fromDb(String? value) {
    return PaymentDirection.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PaymentDirection.received,
    );
  }
}

/// Cash vs bank channel. Must match the [CashAccount.type] of [accountId].
enum PaymentMethod {
  cash('cash'),
  bank('bank');

  final String dbValue;
  const PaymentMethod(this.dbValue);

  static PaymentMethod fromDb(String? value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// A payment received from a customer or paid to a supplier.
///
/// Posting (via [AccountingService]) writes ledger entries, updates the party
/// balance cache and the cash/bank balance cache, applies [allocations] to
/// invoices (updating their `paid_paisa` and status), all in one transaction.
/// [idempotencyKey] is UNIQUE for safe retries.
class Payment {
  final int? id;
  final DateTime date;
  final PartyType partyType;
  final int partyId;
  final int amountPaisa;
  final PaymentDirection direction;
  final PaymentMethod method;
  final int accountId;
  final String? reference;
  final String? allocationJson;
  final String? idempotencyKey;
  final String? notes;
  final DateTime? createdAt;

  const Payment({
    this.id,
    required this.date,
    required this.partyType,
    required this.partyId,
    required this.amountPaisa,
    required this.direction,
    required this.method,
    required this.accountId,
    this.reference,
    this.allocationJson,
    this.idempotencyKey,
    this.notes,
    this.createdAt,
  });

  Payment copyWith({
    int? id,
    DateTime? date,
    PartyType? partyType,
    int? partyId,
    int? amountPaisa,
    PaymentDirection? direction,
    PaymentMethod? method,
    int? accountId,
    String? reference,
    String? allocationJson,
    String? idempotencyKey,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      date: date ?? this.date,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      amountPaisa: amountPaisa ?? this.amountPaisa,
      direction: direction ?? this.direction,
      method: method ?? this.method,
      accountId: accountId ?? this.accountId,
      reference: reference ?? this.reference,
      allocationJson: allocationJson ?? this.allocationJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': toEpochMillis(date),
      'party_type': partyType.dbValue,
      'party_id': partyId,
      'amount_paisa': amountPaisa,
      'direction': direction.dbValue,
      'method': method.dbValue,
      'account_id': accountId,
      'reference': reference,
      'allocation_json': allocationJson,
      'idempotency_key': idempotencyKey,
      'notes': notes,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int?,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      partyType: PartyType.fromDb(map['party_type'] as String?),
      partyId: (map['party_id'] as int?) ?? 0,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
      direction: PaymentDirection.fromDb(map['direction'] as String?),
      method: PaymentMethod.fromDb(map['method'] as String?),
      accountId: (map['account_id'] as int?) ?? 0,
      reference: map['reference'] as String?,
      allocationJson: map['allocation_json'] as String?,
      idempotencyKey: map['idempotency_key'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}

/// Links a payment to the invoice(s) it settles.
class PaymentAllocation {
  final int? id;
  final int? paymentId;
  final String invoiceType; // 'sale' | 'purchase'
  final int invoiceId;
  final int amountPaisa;

  const PaymentAllocation({
    this.id,
    this.paymentId,
    required this.invoiceType,
    required this.invoiceId,
    required this.amountPaisa,
  });

  PaymentAllocation copyWith({
    int? id,
    int? paymentId,
    String? invoiceType,
    int? invoiceId,
    int? amountPaisa,
  }) {
    return PaymentAllocation(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      invoiceType: invoiceType ?? this.invoiceType,
      invoiceId: invoiceId ?? this.invoiceId,
      amountPaisa: amountPaisa ?? this.amountPaisa,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'invoice_type': invoiceType,
      'invoice_id': invoiceId,
      'amount_paisa': amountPaisa,
    };
  }

  factory PaymentAllocation.fromMap(Map<String, Object?> map) {
    return PaymentAllocation(
      id: map['id'] as int?,
      paymentId: map['payment_id'] as int?,
      invoiceType: (map['invoice_type'] as String?) ?? 'sale',
      invoiceId: (map['invoice_id'] as int?) ?? 0,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
    );
  }
}
