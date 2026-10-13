/// An expense category (electricity, labour, transport, ...).
///
/// Seed categories are created on first open; users can add/deactivate their own.
class ExpenseCategory {
  final int? id;
  final String name;
  final bool isActive;

  const ExpenseCategory({this.id, required this.name, this.isActive = true});

  ExpenseCategory copyWith({int? id, String? name, bool? isActive}) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() =>
      {'id': id, 'name': name, 'is_active': isActive ? 1 : 0};

  factory ExpenseCategory.fromMap(Map<String, Object?> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      isActive: ((map['is_active'] as int?) ?? 1) == 1,
    );
  }
}
