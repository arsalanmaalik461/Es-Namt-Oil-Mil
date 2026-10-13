import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/utils/keys.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

// ===========================================================================
// Generic sale/purchase form. Concrete modules supply party search, posting
// and labels. All money math is integer paisa via lib/utils/money.dart.
// Posting is idempotent (uuid v4 per form session) and the Save buttons are
// disabled while a post is in flight (duplicate-submit protection).
// ===========================================================================

abstract class InvoiceFormModule {
  String title(AppLocalizations l10n);
  String partyLabel(AppLocalizations l10n);
  String selectPartyLabel(AppLocalizations l10n);
  String searchPartyHint(AppLocalizations l10n);
  String noPartyMessage(AppLocalizations l10n);
  String noItemsMessage(AppLocalizations l10n);
  String postLabel(AppLocalizations l10n);
  String postedMessage(AppLocalizations l10n, String invoiceNo);
  String draftSavedMessage(AppLocalizations l10n, String invoiceNo);
  String confirmPostMessage(AppLocalizations l10n);

  void openDetail(BuildContext context, int id);

  Future<List<PartyRef>> searchParties(String query);
  Future<List<ProductRef>> searchProducts(String query);
  Future<PostedInvoice> post(InvoicePostArgs args);
  Future<PostedInvoice> createDraft(InvoicePostArgs args);
  Future<void> recordInitialPayment({
    required int partyId,
    required int invoiceId,
    required int amountPaisa,
    required DateTime date,
  });
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final InvoiceFormModule module;

  const InvoiceFormScreen({super.key, required this.module});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _LineCtrls {
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  final discount = TextEditingController();

  void dispose() {
    qty.dispose();
    price.dispose();
    discount.dispose();
  }
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  PartyRef? _party;
  DateTime _date = DateTime.now();
  final List<InvoiceLineDraft> _lines = [];
  final Map<InvoiceLineDraft, _LineCtrls> _ctrls = {};
  final _invoiceDiscount = TextEditingController();
  final _taxPct = TextEditingController();
  final _paid = TextEditingController();
  final _notes = TextEditingController();

  List<Unit>? _units;
  bool _posting = false;
  late final String _sessionKey = newIdempotencyKey();

  @override
  void initState() {
    super.initState();
    _addLine();
    ref.read(unitRepositoryProvider.future).then((repo) async {
      final units = await repo.getAll();
      if (mounted) setState(() => _units = units);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _invoiceDiscount.dispose();
    _taxPct.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _addLine() {
    final line = InvoiceLineDraft();
    setState(() {
      _lines.add(line);
      _ctrls[line] = _LineCtrls();
    });
  }

  void _removeLine(InvoiceLineDraft line) {
    if (_lines.length == 1) return;
    setState(() {
      _lines.remove(line);
      _ctrls.remove(line)?.dispose();
    });
  }

  double get _discountPctVal =>
      double.tryParse(_invoiceDiscount.text.trim()) ?? 0;
  double get _taxPctVal => double.tryParse(_taxPct.text.trim()) ?? 0;

  int get _subtotal => _lines.fold(0, (sum, l) => sum + l.lineTotal);
  int get _discountPaisa => percentOf(_subtotal, _discountPctVal);
  int get _taxPaisa => percentOf(_subtotal - _discountPaisa, _taxPctVal);
  int get _total => _subtotal - _discountPaisa + _taxPaisa;

  int _paidPaisa() {
    final t = _paid.text.trim();
    if (t.isEmpty) return 0;
    try {
      return parsePkrToPaisa(t);
    } on FormatException {
      return 0;
    }
  }

  int get _due => (_total - _paidPaisa()).clamp(0, _total);

  bool _validate(AppLocalizations l10n) {
    if (_party == null) {
      showInfoSnack(context, widget.module.noPartyMessage(l10n));
      return false;
    }
    if (_lines.isEmpty || _lines.any((l) => !l.isValid)) {
      showInfoSnack(context, widget.module.noItemsMessage(l10n));
      return false;
    }
    if (_total <= 0) {
      showInfoSnack(context, l10n.transactions_invalidPrice);
      return false;
    }
    return true;
  }

  InvoicePostArgs _buildArgs() {
    return InvoicePostArgs(
      partyId: _party!.id,
      date: _date,
      lines: [
        for (final l in _lines)
          LineArgs(
            productId: l.product!.id,
            qty: l.qty,
            unitId: l.unitId!,
            unitPricePaisa: l.unitPricePaisa,
            discountPercent: l.discountPercent,
          ),
      ],
      discountPercent: _discountPctVal,
      taxPaisa: _taxPaisa,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      idempotencyKey: _sessionKey,
    );
  }

  Future<void> _saveDraft() async {
    final l10n = AppLocalizations.of(context);
    if (_posting || !_validate(l10n)) return;
    setState(() => _posting = true);
    try {
      final posted = await widget.module.createDraft(_buildArgs());
      if (!mounted) return;
      showInfoSnack(
          context, widget.module.draftSavedMessage(l10n, posted.invoiceNo));
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context);
    if (_posting || !_validate(l10n)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: widget.module.postLabel(l10n),
      message: widget.module.confirmPostMessage(l10n),
      confirmLabel: widget.module.postLabel(l10n),
      danger: false,
    );
    if (!confirmed || !mounted) return;
    setState(() => _posting = true);
    try {
      final posted = await widget.module.post(_buildArgs());
      final paid = _paidPaisa();
      if (paid > 0) {
        await widget.module.recordInitialPayment(
          partyId: _party!.id,
          invoiceId: posted.id,
          amountPaisa: paid,
          date: _date,
        );
      }
      if (!mounted) return;
      showInfoSnack(
          context, widget.module.postedMessage(l10n, posted.invoiceNo));
      // Capture the navigator before popping: the form's context is
      // deactivated by pop() and must not be used afterwards.
      final navigator = Navigator.of(context);
      navigator.pop();
      widget.module.openDetail(navigator.context, posted.id);
    } on AppException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pickParty() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showPartyPicker(
      context,
      title: widget.module.selectPartyLabel(l10n),
      hint: widget.module.searchPartyHint(l10n),
      search: widget.module.searchParties,
    );
    if (picked != null) setState(() => _party = picked);
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

  Future<void> _pickProduct(InvoiceLineDraft line) async {
    final picked = await showProductPicker(
      context,
      search: widget.module.searchProducts,
    );
    if (picked == null) return;
    final ctrls = _ctrls[line]!;
    setState(() {
      line.product = picked;
      line.unitId = picked.baseUnitId;
      line.unitSymbol = picked.baseUnitSymbol;
      line.unitPricePaisa = picked.defaultPricePaisa;
      ctrls.price.text =
          (picked.defaultPricePaisa / paisaPerRupee).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final module = widget.module;
    return Scaffold(
      appBar: AppBar(title: Text(module.title(l10n))),
      body: _units == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionHeader(title: module.partyLabel(l10n)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title:
                            Text(_party?.name ?? module.selectPartyLabel(l10n)),
                        subtitle:
                            _party?.phone == null ? null : Text(_party!.phone!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _posting ? null : _pickParty,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(formatDate(context, _date)),
                        subtitle: Text(l10n.common_date),
                        onTap: _posting ? null : _pickDate,
                      ),
                    ],
                  ),
                ),
                SectionHeader(
                  title: l10n.transactions_addItem,
                  action: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _posting ? null : _addLine,
                    tooltip: l10n.transactions_addItem,
                  ),
                ),
                for (final line in _lines)
                  _LineCard(
                    line: line,
                    ctrls: _ctrls[line]!,
                    units: _units!,
                    onPickProduct: () => _pickProduct(line),
                    onRemove: () => _removeLine(line),
                    onChanged: () => setState(() {}),
                    canRemove: _lines.length > 1 && !_posting,
                    enabled: !_posting,
                  ),
                SectionHeader(title: l10n.transactions_total),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField.numeric(
                              controller: _invoiceDiscount,
                              label: l10n.transactions_invoiceDiscount,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField.numeric(
                              controller: _taxPct,
                              label: l10n.transactions_taxPct,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TotalRow(
                          label: l10n.transactions_subtotal, paisa: _subtotal),
                      _TotalRow(
                          label: l10n.transactions_discount,
                          paisa: _discountPaisa),
                      _TotalRow(label: l10n.transactions_tax, paisa: _taxPaisa),
                      const Divider(),
                      _TotalRow(
                        label: l10n.transactions_total,
                        paisa: _total,
                        bold: true,
                      ),
                      const SizedBox(height: 12),
                      AppTextField.numeric(
                        controller: _paid,
                        label: l10n.transactions_paidAmount,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      _TotalRow(label: l10n.transactions_due, paisa: _due),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _notes,
                        label: l10n.transactions_notes,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: l10n.transactions_saveDraft,
                              variant: AppButtonVariant.secondary,
                              onPressed: _posting ? null : _saveDraft,
                              isLoading: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: module.postLabel(l10n),
                              onPressed: _posting ? null : _post,
                              isLoading: _posting,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final int paisa;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.paisa,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : null,
                  ),
            ),
          ),
          AmountText(
            paisa: paisa,
            style: (bold
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
              fontWeight: bold ? FontWeight.w800 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final InvoiceLineDraft line;
  final _LineCtrls ctrls;
  final List<Unit> units;
  final VoidCallback onPickProduct;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final bool canRemove;
  final bool enabled;

  const _LineCard({
    required this.line,
    required this.ctrls,
    required this.units,
    required this.onPickProduct,
    required this.onRemove,
    required this.onChanged,
    required this.canRemove,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled ? onPickProduct : null,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text(
                      line.product?.name ?? l10n.transactions_selectProduct,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.transactions_removeLine,
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
                    controller: ctrls.qty,
                    label: l10n.transactions_qty,
                    onChanged: (v) {
                      line.qty = double.tryParse(v.trim()) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: line.unitId,
                    decoration: InputDecoration(
                      labelText: l10n.transactions_unit,
                      border: const OutlineInputBorder(),
                    ),
                    items: units
                        .map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(u.symbol),
                            ))
                        .toList(),
                    onChanged: enabled
                        ? (id) {
                            if (id == null) return;
                            final u = units.firstWhere((e) => e.id == id);
                            line.unitId = id;
                            line.unitSymbol = u.symbol;
                            onChanged();
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField.numeric(
                    controller: ctrls.price,
                    label: l10n.transactions_unitPrice,
                    onChanged: (v) {
                      try {
                        line.unitPricePaisa = parsePkrToPaisa(v.trim());
                      } on FormatException {
                        // keep previous value until valid
                      }
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField.numeric(
                    controller: ctrls.discount,
                    label: l10n.transactions_discountPct,
                    onChanged: (v) {
                      line.discountPercent = double.tryParse(v.trim()) ?? 0;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${l10n.transactions_lineTotal}: ${formatPkr(line.lineTotal)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
