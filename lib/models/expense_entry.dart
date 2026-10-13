import '../utils/time.dart';

/// A business expense paid from a cash/bank account.
///
/// Posted as: debit(expense, category) / credit(cash|bank account).
class ExpenseEntry {
  final int? id;
  final DateTime date;
  final int categoryId;
  final int amountPaisa;
  final int accountId;
  final String? description;
  final String? reference;
  final String journalKey;
  final DateTime? createdAt;

  const ExpenseEntry({
    this.id,
    required this.date,
    required this.categoryId,
    required this.amountPaisa,
    required this.accountId,
    this.description,
    this.reference,
    required this.journalKey,
    this.createdAt,
  });

  ExpenseEntry copyWith({
    int? id,
    DateTime? date,
    int? categoryId,
    int? amountPaisa,
    int? accountId,
    String? description,
    String? reference,
    String? journalKey,
    DateTime? createdAt,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      amountPaisa: amountPaisa ?? this.amountPaisa,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      journalKey: journalKey ?? this.journalKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': toEpochMillis(date),
      'category_id': categoryId,
      'amount_paisa': amountPaisa,
      'account_id': accountId,
      'description': description,
      'reference': reference,
      'journal_key': journalKey,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory ExpenseEntry.fromMap(Map<String, Object?> map) {
    return ExpenseEntry(
      id: map['id'] as int?,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      categoryId: (map['category_id'] as int?) ?? 0,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
      accountId: (map['account_id'] as int?) ?? 0,
      description: map['description'] as String?,
      reference: map['reference'] as String?,
      journalKey: (map['journal_key'] as String?) ?? '',
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}
