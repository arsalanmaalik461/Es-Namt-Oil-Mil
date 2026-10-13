import '../utils/time.dart';

/// Product category. Stored in DB as [dbValue].
enum ProductCategory {
  rawMaterial('raw_material'),
  finishedOil('finished_oil'),
  oilCake('oil_cake'),
  packaging('packaging'),
  container('container'),
  spare('spare'),
  consumable('consumable');

  final String dbValue;
  const ProductCategory(this.dbValue);

  static ProductCategory fromDb(String? value) {
    return ProductCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ProductCategory.consumable,
    );
  }
}

/// A stockable product (oilseed, finished oil, oil cake, packaging, ...).
///
/// QUANTITY REPRESENTATION: [stockQty] is a double in the product's
/// [baseUnitId] (e.g. kg). Quantities are doubles — never money — while all
/// money ([avgCostPaisa], [defaultSalePricePaisa]) stays integer paisa.
/// [stockQty] is a CACHE updated by [AccountingService] in the same transaction
/// as the `inventory_movements` rows; the movements table is the source of
/// truth for audit.
///
/// [avgCostPaisa] is the weighted moving-average cost per ONE base unit,
/// recalculated on every purchase/production receipt.
class Product {
  final int? id;
  final String name;
  final String? sku;
  final ProductCategory category;
  final int baseUnitId;
  final int avgCostPaisa;
  final int defaultSalePricePaisa;
  final double stockQty;
  final double reorderLevelQty;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    required this.name,
    this.sku,
    required this.category,
    required this.baseUnitId,
    this.avgCostPaisa = 0,
    this.defaultSalePricePaisa = 0,
    this.stockQty = 0,
    this.reorderLevelQty = 0,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => stockQty <= reorderLevelQty;

  /// Stock value at moving-average cost (integer paisa).
  int get stockValuePaisa => (stockQty * avgCostPaisa).round();

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    ProductCategory? category,
    int? baseUnitId,
    int? avgCostPaisa,
    int? defaultSalePricePaisa,
    double? stockQty,
    double? reorderLevelQty,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      avgCostPaisa: avgCostPaisa ?? this.avgCostPaisa,
      defaultSalePricePaisa:
          defaultSalePricePaisa ?? this.defaultSalePricePaisa,
      stockQty: stockQty ?? this.stockQty,
      reorderLevelQty: reorderLevelQty ?? this.reorderLevelQty,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category.dbValue,
      'base_unit_id': baseUnitId,
      'avg_cost_paisa': avgCostPaisa,
      'default_sale_price_paisa': defaultSalePricePaisa,
      'stock_qty': stockQty,
      'reorder_level_qty': reorderLevelQty,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt == null ? null : toEpochMillis(createdAt!),
      'updated_at': updatedAt == null ? null : toEpochMillis(updatedAt!),
    };
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      sku: map['sku'] as String?,
      category: ProductCategory.fromDb(map['category'] as String?),
      baseUnitId: (map['base_unit_id'] as int?) ?? 0,
      avgCostPaisa: (map['avg_cost_paisa'] as int?) ?? 0,
      defaultSalePricePaisa: (map['default_sale_price_paisa'] as int?) ?? 0,
      stockQty: ((map['stock_qty'] as num?) ?? 0).toDouble(),
      reorderLevelQty: ((map['reorder_level_qty'] as num?) ?? 0).toDouble(),
      isArchived: ((map['is_archived'] as int?) ?? 0) == 1,
      createdAt: map['created_at'] == null
          ? null
          : fromEpochMillis((map['created_at'] as int?) ?? 0),
      updatedAt: map['updated_at'] == null
          ? null
          : fromEpochMillis((map['updated_at'] as int?) ?? 0),
    );
  }
}
