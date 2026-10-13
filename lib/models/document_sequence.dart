/// A named counter for human-readable document numbers
/// (`SI-000001`, `LE-000042`, ...).
///
/// Managed exclusively by [DocumentNumberService]; increments are atomic
/// inside the caller's DB transaction.
class DocumentSequence {
  final String prefix;
  final int lastNumber;

  const DocumentSequence({required this.prefix, this.lastNumber = 0});

  DocumentSequence copyWith({String? prefix, int? lastNumber}) {
    return DocumentSequence(
      prefix: prefix ?? this.prefix,
      lastNumber: lastNumber ?? this.lastNumber,
    );
  }

  Map<String, Object?> toMap() => {'prefix': prefix, 'last_number': lastNumber};

  factory DocumentSequence.fromMap(Map<String, Object?> map) {
    return DocumentSequence(
      prefix: (map['prefix'] as String?) ?? '',
      lastNumber: (map['last_number'] as int?) ?? 0,
    );
  }
}
