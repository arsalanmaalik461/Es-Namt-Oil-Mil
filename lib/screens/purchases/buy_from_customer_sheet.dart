import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/keys.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import '../khata/khata_providers.dart';

/// Bottom sheet that records buying goods FROM a customer — a person on
/// the customer list acting as the seller (user-requested 2026-10-25).
///
/// The regular purchase form only accepts suppliers
/// (`purchase_invoices.supplier_id` is a NOT NULL FK to suppliers), so
/// this sheet posts through [AccountingService.postPurchaseFromCustomer]:
/// stock moves IN at cost and the amount becomes a payable ON the
/// customer's own ledger, with the bought items named in the ledger
/// description. The payable is settled later with the normal customer
/// payment flows.
///
/// Fields: line items (product / qty / unit / price), date + time,
/// optional discount %, tax and note. Returns `true` when posted.
Future<bool> showBuyFromCustomerSheet(
  BuildContext context,
  WidgetRef ref, {
  required Customer customer,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _BuyFromCustomerSheet(customer: customer),
  );
  return result ?? false;
}

class _BuyLine {
  int? productId;
  int? unitId;
  final TextEditingController qty = TextEditingController();
  final TextEditingController price = TextEditingController();

  bool get isEmpty =>
      productId == null && qty.text.trim().isEmpty && price.text.trim().isEmpty;

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class _BuyFromCustomerSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const _BuyFromCustomerSheet({required this.customer});

  @override
  ConsumerState<_BuyFromCustomerSheet> createState() =>
      _BuyFromCustomerSheetState();
}

class _BuyFromCustomerSheetState
    extends ConsumerState<_BuyFromCustomerSheet> {
  final List<_BuyLine> _lines = [_BuyLine()];
  final TextEditingController _discount = TextEditingController();
  final TextEditingController _tax = TextEditingController();
  final TextEditingController _note = TextEditingController();
  List<Product> _products = const [];
  List<Unit> _units = const [];
  bool _loadingCatalog = true;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _discount.dispose();
    _tax.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final productRepo = await ref.read(productRepositoryProvider.future);
      final unitRepo = await ref.read(unitRepositoryProvider.future);
      final products = await productRepo.getAll();
      final units = await unitRepo.getAll();
      if (!mounted) return;
      setState(() {
        _products = products;
        _units = units;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  Product? _productById(int? id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _pickDate() async {
    // Date picker chained into a time picker (same pattern as
    // party_txn_sheet): the entry records date AND time.
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    // Time picker dismissed -> keep the previous time of day.
    final time = pickedTime ?? TimeOfDay.fromDateTime(_date);
    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  int _pricePaisaOf(_BuyLine line) {
    try {
      return parsePkrToPaisa(line.price.text);
    } on FormatException {
      return 0;
    }
  }

  int get _subtotalPaisa {
    var sum = 0;
    for (final line in _lines) {
      final qty = double.tryParse(line.qty.text.trim()) ?? 0;
      if (qty > 0) {
        sum += lineTotalPaisa(unitPricePaisa: _pricePaisaOf(line), qty: qty);
      }
    }
    return sum;
  }

  num get _discountPercent =>
      double.tryParse(_discount.text.trim()) ?? 0;

  int get _taxPaisa {
    try {
      return parsePkrToPaisa(_tax.text);
    } on FormatException {
      return 0;
    }
  }

  int get _totalPaisa =>
      _subtotalPaisa - percentOf(_subtotalPaisa, _discountPercent) + _taxPaisa;

  void _invalidate() {
    ref.invalidate(customerDetailProvider);
    ref.invalidate(customerLedgerProvider);
    ref.invalidate(khataSummaryProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(customerListProvider);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final lines = <PurchaseLineInput>[];
    for (final line in _lines) {
      if (line.isEmpty) continue;
      final qty = double.tryParse(line.qty.text.trim()) ?? 0;
      if (line.productId == null || line.unitId == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchases_noItems)),
        );
        return;
      }
      late final int pricePaisa;
      try {
        pricePaisa = parsePkrToPaisa(line.price.text);
      } on FormatException {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.val_invalidAmount)),
        );
        return;
      }
      lines.add(PurchaseLineInput(
        productId: line.productId!,
        qty: qty,
        unitId: line.unitId!,
        unitPricePaisa: pricePaisa,
      ));
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.purchases_noItems)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final accounting = await ref.read(accountingServiceProvider.future);
      final note = _note.text.trim();
      await accounting.postPurchaseFromCustomer(
        customerId: widget.customer.id!,
        date: _date,
        lines: lines,
        discountPercent: _discountPercent,
        taxPaisa: _taxPaisa,
        notes: note.isEmpty ? null : note,
        idempotencyKey: newIdempotencyKey(),
      );
      _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customers_saved)),
      );
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText(context, e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel =
        '${DateFormat.yMMMd(localeTag).format(_date)} · ${DateFormat.jm(localeTag).format(_date)}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.purchases_newPurchase} — ${widget.customer.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.customers_date),
              trailing: TextButton(
                onPressed: _pickDate,
                child: Text(dateLabel),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.purchases_lineItems,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_loadingCatalog)
              const LinearProgressIndicator()
            else if (_products.isEmpty)
              Text(l10n.inventory_noProducts)
            else
              for (var i = 0; i < _lines.length; i++) _buildLineEditor(i),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => setState(() => _lines.add(_BuyLine())),
                icon: const Icon(Icons.add),
                label: Text(l10n.transactions_addItem),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField.numeric(
                    controller: _discount,
                    label: l10n.transactions_discountPct,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField.numeric(
                    controller: _tax,
                    label: l10n.transactions_tax,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _note,
              label: l10n.customers_note,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.common_total,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  formatPkr(_totalPaisa),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: l10n.purchases_postPurchase,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
              expanded: true,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: l10n.common_cancel,
              variant: AppButtonVariant.secondary,
              onPressed:
                  _saving ? null : () => Navigator.of(context).pop(false),
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineEditor(int index) {
    final l10n = AppLocalizations.of(context);
    final line = _lines[index];
    final qty = double.tryParse(line.qty.text.trim()) ?? 0;
    final lineTotal = qty > 0
        ? lineTotalPaisa(unitPricePaisa: _pricePaisaOf(line), qty: qty)
        : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: line.productId,
                    decoration: InputDecoration(
                      labelText: l10n.inventory_name,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in _products)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                              line.productId = v;
                              final product = _productById(v);
                              if (product != null) {
                                line.unitId = product.baseUnitId;
                                if (line.price.text.trim().isEmpty &&
                                    product.avgCostPaisa > 0) {
                                  line.price.text =
                                      _paisaInput(product.avgCostPaisa);
                                }
                              }
                            }),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _lines[index].dispose();
                              _lines.removeAt(index);
                            }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField.numeric(
                    controller: line.qty,
                    label: l10n.reports_quantity,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: line.unitId,
                    decoration: InputDecoration(
                      labelText: l10n.transactions_unit,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final u in _units)
                        DropdownMenuItem(
                            value: u.id, child: Text('${u.name} (${u.symbol})')),
                    ],
                    onChanged:
                        _saving ? null : (v) => setState(() => line.unitId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AppTextField.numeric(
                    controller: line.price,
                    label: l10n.reports_doc_price,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatPkr(lineTotal),
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Plain rupee text for prefilling a price field from stored paisa.
  String _paisaInput(int paisa) {
    if (paisa % 100 == 0) return (paisa ~/ 100).toString();
    return (paisa / 100).toStringAsFixed(2);
  }
}
