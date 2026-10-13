import '../utils/time.dart';

/// Output type of a production output line. Stored as [dbValue].
enum OutputType {
  finishedOil('finished_oil'),
  oilCake('oil_cake'),
  byProduct('by_product');

  final String dbValue;
  const OutputType(this.dbValue);

  static OutputType fromDb(String? value) {
    return OutputType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => OutputType.byProduct,
    );
  }
}

/// One oil-mill production run (e.g. a day's expeller pressing).
///
/// Inputs (oilseed) are consumed from stock at their moving-average cost;
/// outputs (oil, cake) are added to stock. The full batch cost
/// (materials + labour + electricity + other) is capitalised into the
/// finished-oil outputs' average cost, pro-rata by base-unit quantity —
/// see [AccountingService.postProductionBatch].
///
/// [yieldPct] = finished-oil output (kg) / total input (kg) × 100, or null when
/// a kg conversion is unavailable.
class ProductionBatch {
  final int? id;
  final String batchNo;
  final DateTime date;
  final String? notes;
  final int labourCostPaisa;
  final int electricityCostPaisa;
  final int otherCostPaisa;
  final double? yieldPct;
  final String? journalKey;
  final DateTime? createdAt;

  const ProductionBatch({
    this.id,
    required this.batchNo,
    required this.date,
    this.notes,
    this.labourCostPaisa = 0,
    this.electricityCostPaisa = 0,
    this.otherCostPaisa = 0,
    this.yieldPct,
    this.journalKey,
    this.createdAt,
  });

  /// Total batch cost in paisa (materials are added at posting time;
  /// this getter covers the cash cost components only).
  int get cashCostPaisa =>
      labourCostPaisa + electricityCostPaisa + otherCostPaisa;

  ProductionBatch copyWith({
    int? id,
    String? batchNo,
    DateTime? date,
    String? notes,
    int? labourCostPaisa,
    int? electricityCostPaisa,
    int? otherCostPaisa,
    double? yieldPct,
    String? journalKey,
    DateTime? createdAt,
  }) {
    return ProductionBatch(
      id: id ?? this.id,
      batchNo: batchNo ?? this.batchNo,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      labourCostPaisa: labourCostPaisa ?? this.labourCostPaisa,
      electricityCostPaisa: electricityCostPaisa ?? this.electricityCostPaisa,
      otherCostPaisa: otherCostPaisa ?? this.otherCostPaisa,
      yieldPct: yieldPct ?? this.yieldPct,
      journalKey: journalKey ?? this.journalKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'batch_no': batchNo,
      'date': toEpochMillis(date),
      'notes': notes,
      'labour_cost_paisa': labourCostPaisa,
      'electricity_cost_paisa': electricityCostPaisa,
      'other_cost_paisa': otherCostPaisa,
      'yield_pct': yieldPct,
      'journal_key': journalKey,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
    };
  }

  factory ProductionBatch.fromMap(Map<String, Object?> map) {
    return ProductionBatch(
      id: map['id'] as int?,
      batchNo: (map['batch_no'] as String?) ?? '',
      date: fromEpochMillis((map['date'] as int?) ?? 0),
      notes: map['notes'] as String?,
      labourCostPaisa: (map['labour_cost_paisa'] as int?) ?? 0,
      electricityCostPaisa: (map['electricity_cost_paisa'] as int?) ?? 0,
      otherCostPaisa: (map['other_cost_paisa'] as int?) ?? 0,
      yieldPct: (map['yield_pct'] as num?)?.toDouble(),
      journalKey: map['journal_key'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
    );
  }
}

/// Raw material consumed by a batch.
class ProductionInput {
  final int? id;
  final int? batchId;
  final int productId;
  final double qty;
  final int unitId;

  const ProductionInput({
    this.id,
    this.batchId,
    required this.productId,
    required this.qty,
    required this.unitId,
  });

  ProductionInput copyWith({
    int? id,
    int? batchId,
    int? productId,
    double? qty,
    int? unitId,
  }) {
    return ProductionInput(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitId: unitId ?? this.unitId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'product_id': productId,
      'qty': qty,
      'unit_id': unitId,
    };
  }

  factory ProductionInput.fromMap(Map<String, Object?> map) {
    return ProductionInput(
      id: map['id'] as int?,
      batchId: map['batch_id'] as int?,
      productId: (map['product_id'] as int?) ?? 0,
      qty: ((map['qty'] as num?) ?? 0).toDouble(),
      unitId: (map['unit_id'] as int?) ?? 0,
    );
  }
}

/// Finished output of a batch (oil, cake, by-product).
class ProductionOutput {
  final int? id;
  final int? batchId;
  final int productId;
  final double qty;
  final int unitId;
  final OutputType outputType;

  const ProductionOutput({
    this.id,
    this.batchId,
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.outputType,
  });

  ProductionOutput copyWith({
    int? id,
    int? batchId,
    int? productId,
    double? qty,
    int? unitId,
    OutputType? outputType,
  }) {
    return ProductionOutput(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitId: unitId ?? this.unitId,
      outputType: outputType ?? this.outputType,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'product_id': productId,
      'qty': qty,
      'unit_id': unitId,
      'output_type': outputType.dbValue,
    };
  }

  factory ProductionOutput.fromMap(Map<String, Object?> map) {
    return ProductionOutput(
      id: map['id'] as int?,
      batchId: map['batch_id'] as int?,
      productId: (map['product_id'] as int?) ?? 0,
      qty: ((map['qty'] as num?) ?? 0).toDouble(),
      unitId: (map['unit_id'] as int?) ?? 0,
      outputType: OutputType.fromDb(map['output_type'] as String?),
    );
  }
}
