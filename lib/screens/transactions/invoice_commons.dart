import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';

// ===========================================================================
// Shared building blocks for the sales + purchases modules (Agent D).
// Thin wrapper screens live in lib/screens/sales/ and lib/screens/purchases/;
// the generic screens live in lib/screens/transactions/ and consume the
// module configs defined below.
// ===========================================================================

/// Lightweight party reference (customer or supplier).
class PartyRef {
  final int id;
  final String name;
  final String? phone;
  final int balancePaisa;

  const PartyRef({
    required this.id,
    required this.name,
    this.phone,
    this.balancePaisa = 0,
  });
}

/// Lightweight product reference for pickers / line editors.
class ProductRef {
  final int id;
  final String name;
  final String? sku;
  final int baseUnitId;
  final String baseUnitSymbol;
  final int defaultPricePaisa;
  final double stockQty;

  const ProductRef({
    required this.id,
    required this.name,
    this.sku,
    required this.baseUnitId,
    required this.baseUnitSymbol,
    required this.defaultPricePaisa,
    required this.stockQty,
  });
}

/// One editable invoice line in the sale/purchase form.
class InvoiceLineDraft {
  ProductRef? product;
  int? unitId;
  String unitSymbol;
  double qty;
  int unitPricePaisa;
  double discountPercent;

  InvoiceLineDraft({
    this.product,
    this.unitId,
    this.unitSymbol = '',
    this.qty = 1,
    this.unitPricePaisa = 0,
    this.discountPercent = 0,
  });

  bool get isValid =>
      product != null && unitId != null && qty > 0 && unitPricePaisa >= 0;

  int get lineTotal => lineTotalPaisa(
        unitPricePaisa: unitPricePaisa,
        qty: qty,
        discountPercent: discountPercent,
      );
}

/// Posting arguments, mapped to SaleLineInput/PurchaseLineInput by the module.
class LineArgs {
  final int productId;
  final double qty;
  final int unitId;
  final int unitPricePaisa;
  final double discountPercent;

  const LineArgs({
    required this.productId,
    required this.qty,
    required this.unitId,
    required this.unitPricePaisa,
    required this.discountPercent,
  });
}

class InvoicePostArgs {
  final int partyId;
  final DateTime date;
  final List<LineArgs> lines;
  final double discountPercent;
  final int taxPaisa;
  final String? notes;
  final String? idempotencyKey;

  const InvoicePostArgs({
    required this.partyId,
    required this.date,
    required this.lines,
    this.discountPercent = 0,
    this.taxPaisa = 0,
    this.notes,
    this.idempotencyKey,
  });
}

class PostedInvoice {
  final int id;
  final String invoiceNo;
  final int totalPaisa;

  const PostedInvoice({
    required this.id,
    required this.invoiceNo,
    required this.totalPaisa,
  });
}

/// One row in the invoice list screens.
class InvoiceRowData {
  final int id;
  final String invoiceNo;
  final String partyName;
  final DateTime date;
  final InvoiceStatus status;
  final int totalPaisa;
  final int paidPaisa;

  const InvoiceRowData({
    required this.id,
    required this.invoiceNo,
    required this.partyName,
    required this.date,
    required this.status,
    required this.totalPaisa,
    required this.paidPaisa,
  });

  int get duePaisa => (totalPaisa - paidPaisa).clamp(0, totalPaisa);
}

/// Line item shown on the invoice detail screen.
class InvoiceItemData {
  final int productId;
  final String productName;
  final double qty;
  final int unitId;
  final String unitSymbol;
  final int unitPricePaisa;
  final double discountPercent;
  final int lineTotalPaisa;

  const InvoiceItemData({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitId,
    required this.unitSymbol,
    required this.unitPricePaisa,
    required this.discountPercent,
    required this.lineTotalPaisa,
  });
}

/// Full invoice payload for the detail screen.
class InvoiceDetailData {
  final int id;
  final String invoiceNo;
  final int partyId;
  final String partyName;
  final DateTime date;
  final InvoiceStatus status;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int totalPaisa;
  final int paidPaisa;
  final String? notes;
  final List<InvoiceItemData> items;

  const InvoiceDetailData({
    required this.id,
    required this.invoiceNo,
    required this.partyId,
    required this.partyName,
    required this.date,
    required this.status,
    required this.subtotalPaisa,
    required this.discountPaisa,
    required this.taxPaisa,
    required this.totalPaisa,
    required this.paidPaisa,
    this.notes,
    required this.items,
  });

  int get duePaisa => (totalPaisa - paidPaisa).clamp(0, totalPaisa);
}

/// A payment allocated (at least partly) to an invoice.
class InvoicePaymentData {
  final int id;
  final DateTime date;
  final int amountPaisa;
  final String accountName;
  final String? reference;

  const InvoicePaymentData({
    required this.id,
    required this.date,
    required this.amountPaisa,
    required this.accountName,
    this.reference,
  });
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

/// Locale-aware short date, e.g. 14/10/2026.
String formatDate(BuildContext context, DateTime date) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMd(tag).format(date);
}

/// Shows a localized error snackbar for an [AppException].
void showErrorSnack(BuildContext context, AppException e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorText(context, e))),
  );
}

/// Shows a plain localized message snackbar.
void showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Status chip for invoice lists / detail headers.
class InvoiceStatusChip extends StatelessWidget {
  final InvoiceStatus status;
  final String label;

  const InvoiceStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      InvoiceStatus.draft => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      InvoiceStatus.unpaid => (scheme.errorContainer, scheme.onErrorContainer),
      InvoiceStatus.partial => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      InvoiceStatus.paid => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      InvoiceStatus.returned => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      InvoiceStatus.cancelled => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Party picker (bottom sheet, searchable)
// ---------------------------------------------------------------------------

/// Generic searchable bottom-sheet picker for customers / suppliers.
Future<PartyRef?> showPartyPicker(
  BuildContext context, {
  required String title,
  required String hint,
  required Future<List<PartyRef>> Function(String query) search,
}) {
  return showModalBottomSheet<PartyRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _PartyPickerSheet(
      title: title,
      hint: hint,
      search: search,
    ),
  );
}

class _PartyPickerSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<PartyRef>> Function(String query) search;

  const _PartyPickerSheet({
    required this.title,
    required this.hint,
    required this.search,
  });

  @override
  State<_PartyPickerSheet> createState() => _PartyPickerSheetState();
}

class _PartyPickerSheetState extends State<_PartyPickerSheet> {
  final _controller = TextEditingController();
  late Future<List<PartyRef>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() => _future = widget.search(q));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchBar(
              controller: _controller,
              hint: widget.hint,
              onChanged: _onQuery,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<PartyRef>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final e = snapshot.error;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        e is AppException
                            ? errorText(context, e)
                            : l10n.error_generic,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final parties = snapshot.data ?? const <PartyRef>[];
                if (parties.isEmpty) {
                  return Center(child: Text(l10n.empty_default));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: parties.length,
                  itemBuilder: (context, i) {
                    final p = parties[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          p.name.isEmpty ? '?' : p.name.characters.first,
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: p.phone == null || p.phone!.isEmpty
                          ? null
                          : Text(p.phone!),
                      trailing: AmountText(
                        paisa: p.balancePaisa,
                        positive: p.balancePaisa <= 0 ? true : false,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product picker (bottom sheet, searchable)
// ---------------------------------------------------------------------------

Future<ProductRef?> showProductPicker(
  BuildContext context, {
  required Future<List<ProductRef>> Function(String query) search,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<ProductRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _ProductPickerSheet(
      title: l10n.transactions_selectProduct,
      hint: l10n.transactions_searchProduct,
      search: search,
    ),
  );
}

class _ProductPickerSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<ProductRef>> Function(String query) search;

  const _ProductPickerSheet({
    required this.title,
    required this.hint,
    required this.search,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _controller = TextEditingController();
  late Future<List<ProductRef>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchBar(
              controller: _controller,
              hint: widget.hint,
              onChanged: (q) => setState(() => _future = widget.search(q)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<ProductRef>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final e = snapshot.error;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        e is AppException
                            ? errorText(context, e)
                            : l10n.error_generic,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final products = snapshot.data ?? const <ProductRef>[];
                if (products.isEmpty) {
                  return Center(child: Text(l10n.empty_default));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.stockQty.toStringAsFixed(2)} ${p.baseUnitSymbol}'
                        ' · ${formatPkr(p.defaultPricePaisa)}',
                      ),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment sheet (record payment against an invoice / party)
// ---------------------------------------------------------------------------

class PaymentSheetResult {
  final int amountPaisa;
  final int accountId;
  final PaymentMethod method;
  final String? reference;
  final String? notes;

  const PaymentSheetResult({
    required this.amountPaisa,
    required this.accountId,
    required this.method,
    this.reference,
    this.notes,
  });
}

/// Bottom sheet to record a payment. Returns null when cancelled.
Future<PaymentSheetResult?> showPaymentSheet(
  BuildContext context, {
  required int duePaisa,
  required List<CashAccount> accounts,
}) {
  return showModalBottomSheet<PaymentSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PaymentSheet(duePaisa: duePaisa, accounts: accounts),
  );
}

class _PaymentSheet extends StatefulWidget {
  final int duePaisa;
  final List<CashAccount> accounts;

  const _PaymentSheet({required this.duePaisa, required this.accounts});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  late CashAccount _account;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.duePaisa > 0
          ? (widget.duePaisa / paisaPerRupee).toStringAsFixed(2)
          : '',
    );
    _account = widget.accounts.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    int amount;
    try {
      amount = parsePkrToPaisa(_amount.text);
    } on FormatException {
      return;
    }
    if (amount <= 0) return;
    final method = _account.type == CashAccountType.cash
        ? PaymentMethod.cash
        : PaymentMethod.bank;
    Navigator.of(context).pop(PaymentSheetResult(
      amountPaisa: amount,
      accountId: _account.id!,
      method: method,
      reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.transactions_paymentTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.transactions_due}: ${formatPkr(widget.duePaisa)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              AppTextField.numeric(
                controller: _amount,
                label: l10n.transactions_paymentAmount,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.transactions_invalidPrice;
                  }
                  try {
                    if (parsePkrToPaisa(v) <= 0) {
                      return l10n.transactions_invalidPrice;
                    }
                  } on FormatException {
                    return l10n.transactions_invalidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CashAccount>(
                initialValue: _account,
                decoration: InputDecoration(
                  labelText: l10n.transactions_paymentAccount,
                  border: const OutlineInputBorder(),
                ),
                items: widget.accounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            '${a.name} (${a.type == CashAccountType.cash ? l10n.transactions_cash : l10n.transactions_bank})',
                          ),
                        ))
                    .toList(),
                onChanged: (a) {
                  if (a != null) setState(() => _account = a);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(formatDate(context, _date)),
                subtitle: Text(l10n.common_date),
                onTap: _pickDate,
              ),
              AppTextField(
                controller: _reference,
                label: l10n.transactions_paymentReference,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notes,
                label: l10n.transactions_notes,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.transactions_submitPayment,
                onPressed: _submit,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Return sheet (per-item quantities + reason)
// ---------------------------------------------------------------------------

class ReturnItemDraft {
  final int productId;
  final String productName;
  final int unitId;
  final String unitSymbol;
  final double maxQty;
  final int unitPricePaisa;
  double qty;

  ReturnItemDraft({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitSymbol,
    required this.maxQty,
    required this.unitPricePaisa,
    this.qty = 0,
  });
}

class ReturnSheetResult {
  final List<ReturnLineInput> lines;
  final String? reason;

  const ReturnSheetResult({required this.lines, this.reason});
}

/// Bottom sheet to enter return quantities. Returns null when cancelled.
Future<ReturnSheetResult?> showReturnSheet(
  BuildContext context, {
  required String title,
  required List<ReturnItemDraft> items,
}) {
  return showModalBottomSheet<ReturnSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReturnSheet(title: title, items: items),
  );
}

class _ReturnSheet extends StatefulWidget {
  final String title;
  final List<ReturnItemDraft> items;

  const _ReturnSheet({required this.title, required this.items});

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  final _reason = TextEditingController();
  final _qtyControllers = <ReturnItemDraft, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _qtyControllers[item] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final lines = <ReturnLineInput>[];
    for (final item in widget.items) {
      final text = _qtyControllers[item]!.text.trim();
      if (text.isEmpty) continue;
      final qty = double.tryParse(text);
      if (qty == null || qty <= 0 || qty > item.maxQty + 1e-9) continue;
      lines.add(ReturnLineInput(
        productId: item.productId,
        qty: qty,
        unitId: item.unitId,
        unitPricePaisa: item.unitPricePaisa,
      ));
    }
    if (lines.isEmpty) return;
    Navigator.of(context).pop(ReturnSheetResult(
      lines: lines,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final item in widget.items) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.productName),
                      subtitle: Text(
                        l10n.transactions_maxQty(
                          '${item.maxQty.toStringAsFixed(2)} ${item.unitSymbol}',
                        ),
                      ),
                      trailing: SizedBox(
                        width: 110,
                        child: AppTextField.numeric(
                          controller: _qtyControllers[item],
                          hint: l10n.transactions_qty,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _reason,
                    label: l10n.transactions_returnReason,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: l10n.transactions_submitReturn,
                    onPressed: _submit,
                    expanded: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads active cash/bank accounts for payment sheets.
Future<List<CashAccount>> loadActiveAccounts(WidgetRef ref) {
  return ref
      .read(cashAccountRepositoryProvider.future)
      .then((repo) => repo.getAll(activeOnly: true));
}
