import '../utils/time.dart';

/// The type of account a ledger entry belongs to. Stored as [dbValue].
///
/// Balance formulas (owned exclusively by [AccountingService]):
/// * customer: Σ(debit) − Σ(credit); > 0 = customer owes business (receivable)
/// * supplier: Σ(credit) − Σ(debit); > 0 = business owes supplier (payable)
/// * cash/bank: Σ(debit) − Σ(credit); the account's on-hand balance
/// * expense: Σ(debit) − Σ(credit) (period totals for P&L)
/// * income: Σ(credit) − Σ(debit) (period totals for P&L)
enum AccountType {
  customer('customer'),
  supplier('supplier'),
  cash('cash'),
  bank('bank'),
  expense('expense'),
  income('income');

  final String dbValue;
  const AccountType(this.dbValue);

  static AccountType fromDb(String? value) {
    return AccountType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AccountType.expense,
    );
  }
}

/// One double-entry ledger line.
///
/// INVARIANTS (enforced by DB CHECKs and [AccountingService]):
/// * Exactly one of [debitPaisa]/[creditPaisa] is positive; the other is 0.
/// * Every posting writes a balanced journal: entries sharing [journalKey]
///   have Σ(debit) == Σ(credit).
/// * Posted entries are NEVER updated or deleted. Corrections are new
///   offsetting entries; a reversal entry carries [reversedById] = the id of
///   the original entry it reverses (the original row itself is untouched).
///
/// ADMIN FLAGS (do not change the financial facts; they control visibility):
/// * [voided]: soft-delete flag. Voided entries are excluded from all
///   balance/total calculations but remain visible in history with a badge.
/// * [dueDate]: optional due date for "udhaar" (receivable) entries; powers
///   overdue tracking and payment reminders.
/// * [billImagePath]: optional local path of an attached bill/receipt photo.
/// * [correctsJournal]: on a correction journal's entries, the [journalKey]
///   of the original journal being corrected.
class LedgerEntry {
  final int? id;
  final String entryNo;
  final String journalKey;
  final DateTime date;
  final AccountType accountType;
  final int accountId;
  final int debitPaisa;
  final int creditPaisa;
  final String? category;
  final String? referenceType;
  final int? referenceId;
  final String? description;
  final int? reversedById;
  final DateTime? createdAt;
  final bool voided;
  final DateTime? dueDate;
  final String? billImagePath;
  final String? correctsJournal;

  const LedgerEntry({
    this.id,
    required this.entryNo,
    required this.journalKey,
    required this.date,
    required this.accountType,
    required this.accountId,
    this.debitPaisa = 0,
    this.creditPaisa = 0,
    this.category,
    this.referenceType,
    this.referenceId,
    this.description,
    this.reversedById,
    this.createdAt,
    this.voided = false,
    this.dueDate,
    this.billImagePath,
    this.correctsJournal,
  });

  /// True when this entry is a reversal of another entry.
  bool get isReversal => reversedById != null;

  /// True when this entry belongs to a correction journal.
  bool get isCorrection => correctsJournal != null;

  LedgerEntry copyWith({
    int? id,
    String? entryNo,
    String? journalKey,
    DateTime? date,
    AccountType? accountType,
    int? accountId,
    int? debitPaisa,
    int? creditPaisa,
    String? category,
    String? referenceType,
    int? referenceId,
    String? description,
    int? reversedById,
    DateTime? createdAt,
    bool? voided,
    DateTime? dueDate,
    String? billImagePath,
    String? correctsJournal,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      entryNo: entryNo ?? this.entryNo,
      journalKey: journalKey ?? this.journalKey,
      date: date ?? this.date,
      accountType: accountType ?? this.accountType,
      accountId: accountId ?? this.accountId,
      debitPaisa: debitPaisa ?? this.debitPaisa,
      creditPaisa: creditPaisa ?? this.creditPaisa,
      category: category ?? this.category,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      reversedById: reversedById ?? this.reversedById,
      createdAt: createdAt ?? this.createdAt,
      voided: voided ?? this.voided,
      dueDate: dueDate ?? this.dueDate,
      billImagePath: billImagePath ?? this.billImagePath,
      correctsJournal: correctsJournal ?? this.correctsJournal,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entry_no': entryNo,
      'journal_key': journalKey,
      'date': toEpochMillis(date),
      'account_type': accountType.dbValue,
      'account_id': accountId,
      'debit_paisa': debitPaisa,
      'credit_paisa': creditPaisa,
      'category': category,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'description': description,
      'reversed_by_id': reversedById,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
      'voided': voided ? 1 : 0,
      'due_date': dueDate == null ? null : toEpochMillis(dueDate!),
      'bill_image_path': billImagePath,
      'corrects_journal': correctsJournal,
    };
  }

  factory LedgerEntry.fromMap(Map<String, Object?> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      entryNo: (map['entry_no'] as String?) ?? '',
      journalKey: (map['journal_key'] as String?) ?? '',
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      accountType: AccountType.fromDb(map['account_type'] as String?),
      accountId: (map['account_id'] as int?) ?? 0,
      debitPaisa: (map['debit_paisa'] as int?) ?? 0,
      creditPaisa: (map['credit_paisa'] as int?) ?? 0,
      category: map['category'] as String?,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      description: map['description'] as String?,
      reversedById: map['reversed_by_id'] as int?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
      voided: ((map['voided'] as int?) ?? 0) == 1,
      dueDate: map['due_date'] == null
          ? null
          : fromEpochMillis((map['due_date'] as int?) ?? 0),
      billImagePath: map['bill_image_path'] as String?,
      correctsJournal: map['corrects_journal'] as String?,
    );
  }
}
