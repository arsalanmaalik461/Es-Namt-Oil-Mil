/// A unit of measure (kg, maund, ton, litre, bag, piece).
///
/// Units are seed data; users may add more (e.g. "crate"). Conversions live in
/// [UnitConversion] and are user-configurable.
class Unit {
  final int? id;
  final String name;
  final String symbol;

  const Unit({this.id, required this.name, required this.symbol});

  Unit copyWith({int? id, String? name, String? symbol}) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
    );
  }

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'symbol': symbol};

  factory Unit.fromMap(Map<String, Object?> map) {
    return Unit(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      symbol: (map['symbol'] as String?) ?? '',
    );
  }
}
