import '../utils/time.dart';

/// A customer (receivable account) of the oil mill.
///
/// BALANCE SEMANTICS: [balancePaisa] > 0 means the customer OWES the business
/// (receivable/udhaar). [balancePaisa] < 0 means the customer has paid in
/// advance (business owes the customer). Zero means settled.
///
/// [balancePaisa] is a CACHE maintained by [AccountingService] inside the same
/// DB transaction as the ledger entries. The source of truth is the
/// `ledger_entries` table; `AccountingService.verifyBalances()` reconciles them.
/// Never update [balancePaisa] directly from UI code.
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? code;
  final String? businessName;
  final String? notes;
  final int openingBalancePaisa;
  final int balancePaisa;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.code,
    this.businessName,
    this.notes,
    this.openingBalancePaisa = 0,
    this.balancePaisa = 0,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Amount still owed TO the business (never negative).
  int get receivablePaisa => balancePaisa > 0 ? balancePaisa : 0;

  /// Advance paid BY the customer (never negative).
  int get advancePaisa => balancePaisa < 0 ? -balancePaisa : 0;

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? code,
    String? businessName,
    String? notes,
    int? openingBalancePaisa,
    int? balancePaisa,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      code: code ?? this.code,
      businessName: businessName ?? this.businessName,
      notes: notes ?? this.notes,
      openingBalancePaisa: openingBalancePaisa ?? this.openingBalancePaisa,
      balancePaisa: balancePaisa ?? this.balancePaisa,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'code': code,
      'business_name': businessName,
      'notes': notes,
      'opening_balance_paisa': openingBalancePaisa,
      'balance_paisa': balancePaisa,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
      'updated_at': updatedAt == null ? null : toEpochMillis(updatedAt!),
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      code: map['code'] as String?,
      businessName: map['business_name'] as String?,
      notes: map['notes'] as String?,
      openingBalancePaisa: (map['opening_balance_paisa'] as int?) ?? 0,
      balancePaisa: (map['balance_paisa'] as int?) ?? 0,
      isArchived: ((map['is_archived'] as int?) ?? 0) == 1,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
      updatedAt: map['updated_at'] == null
          ? null
          : fromEpochMillis((map['updated_at'] as int?) ?? 0),
    );
  }
}
