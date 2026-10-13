import '../utils/time.dart';

/// A transfer between two cash/bank accounts (e.g. cash deposited to bank).
///
/// A transfer is NOT income and NOT an expense — it only moves money between
/// accounts. Posted as: debit(to account) / credit(from account).
class AccountTransfer {
  final int? id;
  final DateTime date;
  final int fromAccountId;
  final int toAccountId;
  final int amountPaisa;
  final String journalKey;
  final String? notes;
  final DateTime? createdAt;

  const AccountTransfer({
    this.id,
    required this.date,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountPaisa,
    required this.journalKey,
    this.notes,
    this.createdAt,
  });

  AccountTransfer copyWith({
    int? id,
    DateTime? date,
    int? fromAccountId,
    int? toAccountId,
    int? amountPaisa,
    String? journalKey,
    String? notes,
    DateTime? createdAt,
  }) {
    return AccountTransfer(
      id: id ?? this.id,
      date: date ?? this.date,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amountPaisa: amountPaisa ?? this.amountPaisa,
      journalKey: journalKey ?? this.journalKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': toEpochMillis(date),
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount_paisa': amountPaisa,
      'journal_key': journalKey,
      'notes': notes,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory AccountTransfer.fromMap(Map<String, Object?> map) {
    return AccountTransfer(
      id: map['id'] as int?,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      fromAccountId: (map['from_account_id'] as int?) ?? 0,
      toAccountId: (map['to_account_id'] as int?) ?? 0,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
      journalKey: (map['journal_key'] as String?) ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}
