/// Conversion factor between two units.
///
/// `qtyInToUnit = qtyInFromUnit * factor`.
/// The reverse conversion is derived automatically as `1 / factor` by
/// [UnitRepository], so only one direction needs a row.
///
/// NOTE: litre ↔ kg is deliberately NOT seeded — the factor depends on oil
/// density and varies. Users can add it themselves if they standardise one.
class UnitConversion {
  final int? id;
  final int fromUnitId;
  final int toUnitId;
  final double factor;

  const UnitConversion({
    this.id,
    required this.fromUnitId,
    required this.toUnitId,
    required this.factor,
  });

  UnitConversion copyWith({
    int? id,
    int? fromUnitId,
    int? toUnitId,
    double? factor,
  }) {
    return UnitConversion(
      id: id ?? this.id,
      fromUnitId: fromUnitId ?? this.fromUnitId,
      toUnitId: toUnitId ?? this.toUnitId,
      factor: factor ?? this.factor,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'from_unit_id': fromUnitId,
      'to_unit_id': toUnitId,
      'factor': factor,
    };
  }

  factory UnitConversion.fromMap(Map<String, Object?> map) {
    return UnitConversion(
      id: map['id'] as int?,
      fromUnitId: (map['from_unit_id'] as int?) ?? 0,
      toUnitId: (map['to_unit_id'] as int?) ?? 0,
      factor: ((map['factor'] as num?) ?? 0).toDouble(),
    );
  }
}
