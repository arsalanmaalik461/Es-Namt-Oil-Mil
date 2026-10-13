import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/inventory_movement.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/production_batch.dart';

/// Localized labels shared by Module E screens (inventory, production,
/// cashbook, expenses). All strings come from [AppLocalizations] — nothing
/// is hardcoded here.

String productCategoryLabel(AppLocalizations l10n, ProductCategory c) {
  return switch (c) {
    ProductCategory.rawMaterial => l10n.inventory_catRawMaterial,
    ProductCategory.finishedOil => l10n.inventory_catFinishedOil,
    ProductCategory.oilCake => l10n.inventory_catOilCake,
    ProductCategory.packaging => l10n.inventory_catPackaging,
    ProductCategory.container => l10n.inventory_catContainer,
    ProductCategory.spare => l10n.inventory_catSpare,
    ProductCategory.consumable => l10n.inventory_catConsumable,
  };
}

String movementTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    MovementTypes.sale => l10n.inventory_typeSale,
    MovementTypes.purchase => l10n.inventory_typePurchase,
    MovementTypes.productionInput => l10n.inventory_typeProduction,
    MovementTypes.productionOutput => l10n.inventory_typeProduction,
    MovementTypes.salesReturn => l10n.inventory_typeReturn,
    MovementTypes.purchaseReturn => l10n.inventory_typeReturn,
    MovementTypes.adjustment => l10n.inventory_typeAdjustment,
    _ => type,
  };
}

String outputTypeLabel(AppLocalizations l10n, OutputType t) {
  return switch (t) {
    OutputType.finishedOil => l10n.production_typeFinishedOil,
    OutputType.oilCake => l10n.production_typeOilCake,
    OutputType.byProduct => l10n.production_typeByProduct,
  };
}

String cashAccountTypeLabel(AppLocalizations l10n, CashAccountType t) {
  return switch (t) {
    CashAccountType.cash => l10n.cashbook_typeCash,
    CashAccountType.bank => l10n.cashbook_typeBank,
  };
}
