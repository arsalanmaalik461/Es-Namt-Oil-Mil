import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Prefix used to persist the wastage quantity inside the batch notes
/// (the service stores no separate wastage column).
const String wastageNotePrefix = 'wastage:';

/// Form for a new production batch: inputs (raw material), outputs
/// (finished oil / oil cake / by-products), wastage, costs and an optional
/// cost account. Posting goes through `AccountingService.postProductionBatch`
/// in ONE transaction; the batch number is generated inside that transaction.
class ProductionBatchFormScreen extends ConsumerStatefulWidget {
  const ProductionBatchFormScreen({super.key});

  @override
  ConsumerState<ProductionBatchFormScreen> createState() =>
      _ProductionBatchFormScreenState();
}

class _BatchLine {
  int? productId;
  final TextEditingController qty = TextEditingController();
  int? unitId;
  OutputType outputType = OutputType.finishedOil;

  void dispose() => qty.dispose();
}

class _FormData {
  final List<Product> products;
  final List<Unit> units;
  final List<CashAccount> accounts;

  const _FormData(this.products, this.units, this.accounts);
}

class _ProductionBatchFormScreenState
    extends ConsumerState<ProductionBatchFormScreen> {
  late Future<_FormData> _future;
  DateTime _date = DateTime.now();
  final List<_BatchLine> _inputs = [_BatchLine()];
  final List<_BatchLine> _outputs = [_BatchLine()];
  final _wastageQty = TextEditingController();
  int? _wastageUnitId;
  final _labour = TextEditingController();
  final _electricity = TextEditingController();
  final _other = TextEditingController();
  final _expectedYield = TextEditingController();
  final _notes = TextEditingController();
  int? _costAccountId;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final l in [..._inputs, ..._outputs]) {
      l.dispose();
    }
    _wastageQty.dispose();
    _labour.dispose();
    _electricity.dispose();
    _other.dispose();
    _expectedYield.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<_FormData> _load() async {
    final products = await ref.read(productRepositoryProvider.future);
    final units = await ref.read(unitRepositoryProvider.future);
    final accounts = await ref.read(cashAccountRepositoryProvider.future);
    return _FormData(
      await products.getAll(),
      await units.getAll(),
      await accounts.getAll(),
    );
  }

  Product? _productById(_FormData data, int? id) {
    if (id == null) return null;
    return data.products.where((p) => p.id == id).firstOrNull;
  }

  String _unitSymbol(_FormData data, int? id) {
    if (id == null) return '';
    return data.units.where((u) => u.id == id).firstOrNull?.symbol ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickProduct(
      _FormData data, _BatchLine line, bool isInput) async {
    final l10n = AppLocalizations.of(context);
    final allowed = isInput
        ? {ProductCategory.rawMaterial}
        : {ProductCategory.finishedOil, ProductCategory.oilCake};
    final candidates =
        data.products.where((p) => allowed.contains(p.category)).toList();
    final picked = await showDialog<Product>(
      context: context,
      builder: (dCtx) => _ProductPickerDialog(
        title: l10n.production_selectProduct,
        products: candidates,
        units: {for (final u in data.units) u.id!: u},
        emptyMessage:
            isInput ? l10n.production_outOfStock : l10n.inventory_noProducts,
      ),
    );
    if (picked != null) {
      setState(() {
        line.productId = picked.id;
        line.unitId ??= picked.baseUnitId;
        if (!isInput) {
          line.outputType = picked.category == ProductCategory.finishedOil
              ? OutputType.finishedOil
              : OutputType.oilCake;
        }
      });
    }
  }

  int _parseMoney(String text) => parsePkrToPaisa(text.trim());

  String? _buildNotes(_FormData data) {
    final parts = <String>[];
    final w = double.tryParse(_wastageQty.text.trim());
    if (w != null && w > 0) {
      final sym = _unitSymbol(data, _wastageUnitId);
      parts.add('$wastageNotePrefix ${formatQty(w)} $sym'.trim());
    }
    final n = _notes.text.trim();
    if (n.isNotEmpty) parts.add(n);
    return parts.isEmpty ? null : parts.join('\n');
  }

  Future<void> _post(_FormData data) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _posting = true);
    try {
      final validInputs = _inputs
          .where((l) =>
              l.productId != null &&
              l.unitId != null &&
              (double.tryParse(l.qty.text.trim()) ?? 0) > 0)
          .toList();
      final validOutputs = _outputs
          .where((l) =>
              l.productId != null &&
              l.unitId != null &&
              (double.tryParse(l.qty.text.trim()) ?? 0) > 0)
          .toList();
      if (validInputs.isEmpty) {
        throw ValidationException('error.emptyBatchInputs');
      }
      if (validOutputs.isEmpty) {
        throw ValidationException('error.emptyBatchOutputs');
      }

      final accounting = await ref.read(accountingServiceProvider.future);
      final unitRepo = await ref.read(unitRepositoryProvider.future);

      // Live availability check: block posting on insufficient stock.
      // convertQty itself throws error.noConversion when no path exists.
      for (final line in validInputs) {
        final product = _productById(data, line.productId)!;
        final qty = double.parse(line.qty.text.trim());
        final qtyBase =
            await unitRepo.convertQty(qty, line.unitId!, product.baseUnitId);
        if (qtyBase > product.stockQty + 1e-9) {
          throw ValidationException('error.insufficientStock', {
            'product': product.name,
            'available': formatQty(product.stockQty),
            'needed': formatQty(qtyBase),
          });
        }
      }

      final batch = await accounting.postProductionBatch(
        date: _date,
        inputs: [
          for (final l in validInputs)
            BatchInputInput(
              productId: l.productId!,
              qty: double.parse(l.qty.text.trim()),
              unitId: l.unitId!,
            ),
        ],
        outputs: [
          for (final l in validOutputs)
            BatchOutputInput(
              productId: l.productId!,
              qty: double.parse(l.qty.text.trim()),
              unitId: l.unitId!,
              outputType: l.outputType,
            ),
        ],
        labourCostPaisa:
            _labour.text.trim().isEmpty ? 0 : _parseMoney(_labour.text),
        electricityCostPaisa: _electricity.text.trim().isEmpty
            ? 0
            : _parseMoney(_electricity.text),
        otherCostPaisa:
            _other.text.trim().isEmpty ? 0 : _parseMoney(_other.text),
        costCashAccountId: _costAccountId,
        notes: _buildNotes(data),
      );

      final expected =
          double.tryParse(_expectedYield.text.trim().replaceAll('%', ''));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dCtx) {
          final dl10n = AppLocalizations.of(dCtx);
          return AlertDialog(
            title: Text(dl10n.production_resultTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.batchNo,
                    style: Theme.of(dCtx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  batch.yieldPct == null
                      ? dl10n.production_resultNoYield
                      : dl10n
                          .production_resultYield(formatQty(batch.yieldPct!)),
                  style: Theme.of(dCtx).textTheme.bodyLarge,
                ),
                if (expected != null && expected > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${dl10n.production_expectedYield}: '
                    '${formatQty(expected)}%',
                    style: Theme.of(dCtx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(dCtx).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(dl10n.common_ok),
              ),
            ],
          );
        },
      );
      if (mounted) Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.production_newBatch)),
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
          return _buildForm(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, _FormData data) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tag_outlined),
          title: Text(l10n.production_batchNo),
          subtitle: Text(l10n.production_batchAuto),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(l10n.production_date),
          subtitle: Text(dateFormat.format(_date)),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: _pickDate,
        ),
        SectionHeader(
          title: l10n.production_inputs,
          action: TextButton.icon(
            onPressed: () => setState(() => _inputs.add(_BatchLine())),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.production_addInput),
          ),
        ),
        if (data.products
            .where((p) => p.category == ProductCategory.rawMaterial)
            .isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.production_outOfStock,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ..._inputs.asMap().entries.map((e) => _LineCard(
              key: ValueKey('in${e.key}'),
              data: data,
              line: e.value,
              isInput: true,
              onPickProduct: () => _pickProduct(data, e.value, true),
              onRemove: _inputs.length > 1
                  ? () => setState(() {
                        e.value.dispose();
                        _inputs.removeAt(e.key);
                      })
                  : null,
            )),
        SectionHeader(
          title: l10n.production_outputs,
          action: TextButton.icon(
            onPressed: () => setState(() => _outputs.add(_BatchLine())),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.production_addOutput),
          ),
        ),
        ..._outputs.asMap().entries.map((e) => _LineCard(
              key: ValueKey('out${e.key}'),
              data: data,
              line: e.value,
              isInput: false,
              onPickProduct: () => _pickProduct(data, e.value, false),
              onRemove: _outputs.length > 1
                  ? () => setState(() {
                        e.value.dispose();
                        _outputs.removeAt(e.key);
                      })
                  : null,
              onOutputTypeChanged: (t) =>
                  setState(() => e.value.outputType = t),
            )),
        SectionHeader(title: l10n.production_wastage),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField.numeric(
                controller: _wastageQty,
                label: l10n.inventory_qty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: _wastageUnitId,
                decoration: InputDecoration(labelText: l10n.inventory_unit),
                items: [
                  for (final u in data.units)
                    DropdownMenuItem(
                        value: u.id, child: Text('${u.name} (${u.symbol})')),
                ],
                onChanged: (v) => setState(() => _wastageUnitId = v),
              ),
            ),
          ],
        ),
        SectionHeader(title: l10n.production_costBreakdown),
        AppTextField.numeric(
            controller: _labour, label: l10n.production_labourCost),
        const SizedBox(height: 12),
        AppTextField.numeric(
            controller: _electricity, label: l10n.production_electricityCost),
        const SizedBox(height: 12),
        AppTextField.numeric(
            controller: _other, label: l10n.production_otherCost),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: _costAccountId,
          decoration: InputDecoration(labelText: l10n.production_payCostsFrom),
          items: [
            DropdownMenuItem<int?>(
                value: null, child: Text(l10n.production_payCostsNone)),
            for (final a in data.accounts)
              DropdownMenuItem<int?>(
                  value: a.id,
                  child: Text(
                      '${a.name} (${cashAccountTypeLabel(l10n, a.type)})')),
          ],
          onChanged: (v) => setState(() => _costAccountId = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.production_costsCashHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField.numeric(
          controller: _expectedYield,
          label: l10n.production_expectedYield,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _notes,
          label: l10n.production_notes,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.production_postBatch,
          icon: Icons.factory_outlined,
          onPressed: _posting ? null : () => _post(data),
          isLoading: _posting,
          expanded: true,
        ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  final _FormData data;
  final _BatchLine line;
  final bool isInput;
  final VoidCallback onPickProduct;
  final VoidCallback? onRemove;
  final ValueChanged<OutputType>? onOutputTypeChanged;

  const _LineCard({
    super.key,
    required this.data,
    required this.line,
    required this.isInput,
    required this.onPickProduct,
    this.onRemove,
    this.onOutputTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product =
        data.products.where((p) => p.id == line.productId).firstOrNull;
    final baseSymbol = product == null
        ? ''
        : data.units
                .where((u) => u.id == product.baseUnitId)
                .firstOrNull
                ?.symbol ??
            '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickProduct,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text(
                      product?.name ?? l10n.production_selectProduct,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: l10n.production_removeLine,
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField.numeric(
                    controller: line.qty,
                    label: l10n.inventory_qty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _UnitDropdown(
                    data: data,
                    value: line.unitId,
                    onChanged: (v) => line.unitId = v,
                  ),
                ),
              ],
            ),
            if (isInput && product != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.production_available(
                  formatQty(product.stockQty),
                  baseSymbol,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            if (!isInput && product != null) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<OutputType>(
                initialValue: line.outputType,
                decoration:
                    InputDecoration(labelText: l10n.production_outputType),
                items: [
                  for (final t in OutputType.values)
                    DropdownMenuItem(
                        value: t, child: Text(outputTypeLabel(l10n, t))),
                ],
                onChanged: (v) {
                  if (v != null) onOutputTypeChanged?.call(v);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatefulWidget {
  final _FormData data;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _UnitDropdown(
      {required this.data, required this.value, required this.onChanged});

  @override
  State<_UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<_UnitDropdown> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      initialValue: widget.value,
      decoration: InputDecoration(labelText: l10n.inventory_unit),
      items: [
        for (final u in widget.data.units)
          DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.symbol})')),
      ],
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
    );
  }
}

class _ProductPickerDialog extends StatefulWidget {
  final String title;
  final List<Product> products;
  final Map<int, Unit> units;
  final String emptyMessage;

  const _ProductPickerDialog({
    required this.title,
    required this.products,
    required this.units,
    required this.emptyMessage,
  });

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = widget.products
        .where((p) => p.name.toLowerCase().contains(_query))
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.inventory_searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(widget.emptyMessage))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final p = list[index];
                        final symbol = widget.units[p.baseUnitId]?.symbol ?? '';
                        return ListTile(
                          title: Text(p.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${l10n.inventory_available}: '
                            '${formatQty(p.stockQty)} $symbol',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
