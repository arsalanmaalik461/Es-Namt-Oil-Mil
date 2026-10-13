import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';

/// Add / edit product form.
///
/// New products are inserted with zero stock; a positive opening stock is
/// posted afterwards through `AccountingService.postStockAdjustment` so the
/// movement history stays complete. Edits never touch stock or average cost
/// (the repository strips those columns).
class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _FormData {
  final Product? product;
  final List<Unit> units;

  const _FormData(this.product, this.units);
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<_FormData> _future;

  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _reorder = TextEditingController();
  final _openingStock = TextEditingController();
  final _salePrice = TextEditingController();

  ProductCategory _category = ProductCategory.rawMaterial;
  int? _unitId;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _reorder.dispose();
    _openingStock.dispose();
    _salePrice.dispose();
    super.dispose();
  }

  Future<_FormData> _load() async {
    final products = await ref.read(productRepositoryProvider.future);
    final units = await ref.read(unitRepositoryProvider.future);
    final product = _isEdit ? await products.getById(widget.productId!) : null;
    final allUnits = await units.getAll();
    return _FormData(product, allUnits);
  }

  void _initFrom(_FormData data) {
    if (_initialized) return;
    _initialized = true;
    final p = data.product;
    if (p != null) {
      _name.text = p.name;
      _sku.text = p.sku ?? '';
      _category = p.category;
      _unitId = p.baseUnitId;
      if (p.reorderLevelQty > 0) _reorder.text = _trimNum(p.reorderLevelQty);
      if (p.defaultSalePricePaisa > 0) {
        _salePrice.text = (p.defaultSalePricePaisa / paisaPerRupee).toString();
      }
    } else if (data.units.isNotEmpty) {
      _unitId = data.units.first.id;
    }
  }

  String _trimNum(double v) {
    var s = v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
    return s.isEmpty ? '0' : s;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_unitId == null) return;
    setState(() => _saving = true);
    try {
      final products = await ref.read(productRepositoryProvider.future);
      final reorder = _reorder.text.trim().isEmpty
          ? 0.0
          : double.parse(_reorder.text.trim());
      final salePrice = _salePrice.text.trim().isEmpty
          ? 0
          : parsePkrToPaisa(_salePrice.text.trim());
      final sku = _sku.text.trim().isEmpty ? null : _sku.text.trim();

      if (!_isEdit) {
        final id = await products.insert(Product(
          name: _name.text.trim(),
          sku: sku,
          category: _category,
          baseUnitId: _unitId!,
          defaultSalePricePaisa: salePrice,
          reorderLevelQty: reorder,
        ));
        final opening = _openingStock.text.trim().isEmpty
            ? 0.0
            : double.parse(_openingStock.text.trim());
        if (opening > 0) {
          final accounting = await ref.read(accountingServiceProvider.future);
          await accounting.postStockAdjustment(
            productId: id,
            qty: opening,
            unitId: _unitId!,
            reason: l10n.inventory_openingStockReason,
          );
        }
      } else {
        final existing = (await _load()).product;
        if (existing == null) {
          throw ValidationException('error.productNotFound');
        }
        await products.update(existing.copyWith(
          name: _name.text.trim(),
          sku: sku,
          category: _category,
          defaultSalePricePaisa: salePrice,
          reorderLevelQty: reorder,
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventory_productSaved)),
      );
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText(context, e))),
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventory_errInvalidAmount)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEdit ? l10n.inventory_editProduct : l10n.inventory_addProduct),
      ),
      body: FutureBuilder<_FormData>(
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
          final data = snapshot.data!;
          _initFrom(data);
          return _buildForm(context, data);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, _FormData data) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            controller: _name,
            label: l10n.inventory_name,
            validator: AppValidators.required(context),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProductCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.inventory_category),
            items: [
              for (final c in ProductCategory.values)
                DropdownMenuItem(
                    value: c, child: Text(productCategoryLabel(l10n, c))),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _unitId,
            decoration: InputDecoration(labelText: l10n.inventory_unit),
            // The base unit is fixed once a product exists: changing it
            // would invalidate the stock cache.
            onChanged: _isEdit ? null : (v) => setState(() => _unitId = v),
            items: [
              for (final u in data.units)
                DropdownMenuItem(
                    value: u.id, child: Text('${u.name} (${u.symbol})')),
            ],
            validator: (v) => v == null ? l10n.val_required : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _sku,
            label: l10n.inventory_sku,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField.numeric(
                  controller: _reorder,
                  label: l10n.inventory_reorderLevel,
                  validator: (v) => _optionalQtyValidator(context, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEdit
                    ? const SizedBox.shrink()
                    : AppTextField.numeric(
                        controller: _openingStock,
                        label: l10n.inventory_openingStock,
                        validator: (v) => _optionalQtyValidator(context, v),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField.numeric(
            controller: _salePrice,
            label: l10n.inventory_salePrice,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              try {
                final paisa = parsePkrToPaisa(v.trim());
                if (paisa < 0) return l10n.inventory_errInvalidAmount;
              } on FormatException {
                return l10n.inventory_errInvalidAmount;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.common_save,
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            expanded: true,
          ),
        ],
      ),
    );
  }

  String? _optionalQtyValidator(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return null;
    final qty = double.tryParse(v.trim());
    if (qty == null || qty < 0) return l10n.inventory_errInvalidQty;
    return null;
  }
}
