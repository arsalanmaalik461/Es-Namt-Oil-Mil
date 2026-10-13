import '../utils/time.dart';

/// Other business income received into a cash/bank account
/// (e.g. oil-cake sale recorded directly, scrap sale, commission).
///
/// Posted as: debit(cash|bank account) / credit(income).
/// NOTE: sales invoices already credit income — do not record invoice income
/// here as well.
class IncomeEntry {
  final int? id;
  final DateTime date;
  final String? category;
  final int amountPaisa;
  final int accountId;
  final String? description;
  final String? reference;
  final String journalKey;
  final DateTime? createdAt;

  const IncomeEntry({
    this.id,
    required this.date,
    this.category,
    required this.amountPaisa,
    required this.accountId,
    this.description,
    this.reference,
    required this.journalKey,
    this.createdAt,
  });

  IncomeEntry copyWith({
    int? id,
    DateTime? date,
    String? category,
    int? amountPaisa,
    int? accountId,
    String? description,
    String? reference,
    String? journalKey,
    DateTime? createdAt,
  }) {
    return IncomeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
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
      'category': category,
      'amount_paisa': amountPaisa,
      'account_id': accountId,
      'description': description,
      'reference': reference,
      'journal_key': journalKey,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory IncomeEntry.fromMap(Map<String, Object?> map) {
    return IncomeEntry(
      id: map['id'] as int?,
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      category: map['category'] as String?,
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
