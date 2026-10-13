import '../utils/time.dart';

/// Cash vs bank account type. Stored as [dbValue].
enum CashAccountType {
  cash('cash'),
  bank('bank');

  final String dbValue;
  const CashAccountType(this.dbValue);

  static CashAccountType fromDb(String? value) {
    return CashAccountType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => CashAccountType.cash,
    );
  }
}

/// A cash-in-hand or bank account.
///
/// BALANCE SEMANTICS: [balancePaisa] >= 0 is the on-hand balance
/// (Σ(debit) − Σ(credit) of its ledger entries). It is a CACHE maintained by
/// [AccountingService]; source of truth is `ledger_entries`.
/// [openingBalancePaisa] is informational (the balance at account creation);
/// the running balance starts from 0 in the ledger unless an opening entry
/// was posted — see docs/SCHEMA.md.
class CashAccount {
  final int? id;
  final String name;
  final CashAccountType type;
  final int openingBalancePaisa;
  final int balancePaisa;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CashAccount({
    this.id,
    required this.name,
    required this.type,
    this.openingBalancePaisa = 0,
    this.balancePaisa = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  CashAccount copyWith({
    int? id,
    String? name,
    CashAccountType? type,
    int? openingBalancePaisa,
    int? balancePaisa,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalancePaisa: openingBalancePaisa ?? this.openingBalancePaisa,
      balancePaisa: balancePaisa ?? this.balancePaisa,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.dbValue,
      'opening_balance_paisa': openingBalancePaisa,
      'balance_paisa': balancePaisa,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
      'updated_at': updatedAt == null ? null : toEpochMillis(updatedAt!),
    };
  }

  factory CashAccount.fromMap(Map<String, Object?> map) {
    return CashAccount(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      type: CashAccountType.fromDb(map['type'] as String?),
      openingBalancePaisa: (map['opening_balance_paisa'] as int?) ?? 0,
      balancePaisa: (map['balance_paisa'] as int?) ?? 0,
      isActive: ((map['is_active'] as int?) ?? 1) == 1,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
      updatedAt: map['updated_at'] == null
          ? null
          : fromEpochMillis((map['updated_at'] as int?) ?? 0),
    );
  }
}
