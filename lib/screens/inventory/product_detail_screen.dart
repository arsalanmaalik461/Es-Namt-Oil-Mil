import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/inventory_movement.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/screens/inventory/product_form_screen.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Product detail: stock, weighted-average cost, movement history.
/// Actions: Stock In, Stock Out, Adjust (reason required), Edit.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _DetailData {
  final Product product;
  final Map<int, Unit> units;
  final List<InventoryMovement> movements;

  const _DetailData(this.product, this.units, this.movements);
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final products = await ref.read(productRepositoryProvider.future);
    final units = await ref.read(unitRepositoryProvider.future);
    final inventory = await ref.read(inventoryRepositoryProvider.future);
    final product = await products.getById(widget.productId);
    if (product == null) throw ValidationException('error.productNotFound');
    final allUnits = await units.getAll();
    final movements =
        await inventory.movementsForProduct(widget.productId, limit: 100);
    return _DetailData(
        product, {for (final u in allUnits) u.id!: u}, movements);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventory_title)),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError || snapshot.data == null) {
            final err = snapshot.error;
            return ErrorState(
              message: err is AppException
                  ? errorText(context, err)
                  : l10n.error_generic,
              onRetry: () => Navigator.of(context).pop(),
            );
          }
          return _buildBody(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, _DetailData data) {
    final l10n = AppLocalizations.of(context);
    final p = data.product;
    final unit = data.units[p.baseUnitId];
    final symbol = unit?.symbol ?? '';
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${productCategoryLabel(l10n, p.category)}'
                    '${p.sku == null || p.sku!.isEmpty ? '' : ' • ${p.sku}'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _Stat(l10n.inventory_stock,
                              '${formatQty(p.stockQty)} $symbol')),
                      Expanded(
                          child: _Stat(l10n.inventory_avgCost,
                              formatPkr(p.avgCostPaisa))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _Stat(l10n.inventory_stockValue,
                              formatPkr(p.stockValuePaisa))),
                      Expanded(
                          child: _Stat(l10n.inventory_reorderLevel,
                              '${formatQty(p.reorderLevelQty)} $symbol')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: l10n.inventory_stockIn,
                icon: Icons.add,
                onPressed: () => _showStockDialog(data, isIn: true),
              ),
              AppButton(
                label: l10n.inventory_stockOut,
                icon: Icons.remove,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showStockDialog(data, isIn: false),
              ),
              AppButton(
                label: l10n.inventory_adjust,
                icon: Icons.tune,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showAdjustDialog(data),
              ),
              AppButton(
                label: l10n.common_edit,
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(productId: p.id),
                    ),
                  );
                  if (saved == true) _refresh();
                },
              ),
            ],
          ),
        ),
        SectionHeader(title: l10n.inventory_movements),
        if (data.movements.isEmpty)
          EmptyState(
            icon: Icons.history,
            message: l10n.inventory_noMovements,
          )
        else
          ...data.movements.map((m) => _MovementRow(
                movement: m,
                units: data.units,
                dateFormat: DateFormat.yMMMd(l10n.localeName),
              )),
      ],
    );
  }

  Future<void> _showStockDialog(_DetailData data, {required bool isIn}) async {
    final l10n = AppLocalizations.of(context);
    final qtyController = TextEditingController();
    int? unitId = data.product.baseUnitId;
    var saving = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final qty = double.tryParse(qtyController.text.trim());
              if (qty == null || qty <= 0 || unitId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.inventory_errInvalidQty)));
                return;
              }
              setDialogState(() => saving = true);
              try {
                final accounting =
                    await ref.read(accountingServiceProvider.future);
                await accounting.postStockAdjustment(
                  productId: data.product.id!,
                  qty: isIn ? qty : -qty,
                  unitId: unitId!,
                  reason: isIn
                      ? l10n.inventory_stockInReason
                      : l10n.inventory_stockOutReason,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } on AppException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(errorText(dialogContext, e))));
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              title:
                  Text(isIn ? l10n.inventory_stockIn : l10n.inventory_stockOut),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField.numeric(
                    controller: qtyController,
                    label: l10n.inventory_qty,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: unitId,
                    decoration: InputDecoration(labelText: l10n.inventory_unit),
                    items: [
                      for (final u in data.units.values)
                        DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.symbol})')),
                    ],
                    onChanged: (v) => setDialogState(() => unitId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );
    qtyController.dispose();
    if (ok == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.inventory_stockUpdated)));
      }
    }
  }

  Future<void> _showAdjustDialog(_DetailData data) async {
    final l10n = AppLocalizations.of(context);
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    int? unitId = data.product.baseUnitId;
    var saving = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final qty = double.tryParse(qtyController.text.trim());
              if (qty == null || qty == 0 || unitId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.inventory_errInvalidQty)));
                return;
              }
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.inventory_reasonRequired)));
                return;
              }
              setDialogState(() => saving = true);
              try {
                final accounting =
                    await ref.read(accountingServiceProvider.future);
                await accounting.postStockAdjustment(
                  productId: data.product.id!,
                  qty: qty,
                  unitId: unitId!,
                  reason: reasonController.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } on AppException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(errorText(dialogContext, e))));
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(l10n.inventory_adjust),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField.numeric(
                    controller: qtyController,
                    label: l10n.inventory_qty,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: unitId,
                    decoration: InputDecoration(labelText: l10n.inventory_unit),
                    items: [
                      for (final u in data.units.values)
                        DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.symbol})')),
                    ],
                    onChanged: (v) => setDialogState(() => unitId = v),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: reasonController,
                    label: l10n.inventory_reason,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );
    qtyController.dispose();
    reasonController.dispose();
    if (ok == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.inventory_stockUpdated)));
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final InventoryMovement movement;
  final Map<int, Unit> units;
  final DateFormat dateFormat;

  const _MovementRow({
    required this.movement,
    required this.units,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final symbol = units[movement.unitId]?.symbol ?? '';
    final positive = movement.qtyChange > 0;
    final scheme = Theme.of(context).colorScheme;
    final color = positive ? Colors.green.shade700 : scheme.error;
    final notes = movement.notes;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
        child: Icon(
          positive ? Icons.arrow_downward : Icons.arrow_upward,
          color: scheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        '${positive ? '+' : ''}${formatQty(movement.qtyChange)} $symbol',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${movementTypeLabel(l10n, movement.movementType)} • '
        '${dateFormat.format(movement.date)}'
        '${notes == null || notes.isEmpty ? '' : ' • $notes'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
