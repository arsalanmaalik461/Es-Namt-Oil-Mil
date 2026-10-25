import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/keys.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/calculator_pad.dart';
import 'khata_providers.dart';

/// Direction of the money movement recorded by the sheet.
enum PartyTxnKind {
  /// Customer pays the business (reduces the receivable).
  receive,

  /// The business pays the supplier (reduces the payable).
  pay,
}

/// Bottom sheet that records a payment through [AccountingService]:
/// [AccountingService.postCustomerPayment] for [PartyTxnKind.receive],
/// [AccountingService.postSupplierPayment] for [PartyTxnKind.pay].
///
/// Fields: calculator amount entry, date, note, bill image, method
/// (cash/bank) and the cash/bank account.
/// Returns `true` when a payment was posted.
Future<bool> showPartyTxnSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool isCustomer,
  required int partyId,
  required PartyTxnKind kind,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _PartyTxnSheet(
      isCustomer: isCustomer,
      partyId: partyId,
      kind: kind,
    ),
  );
  return result ?? false;
}

class _PartyTxnSheet extends ConsumerStatefulWidget {
  final bool isCustomer;
  final int partyId;
  final PartyTxnKind kind;

  const _PartyTxnSheet({
    required this.isCustomer,
    required this.partyId,
    required this.kind,
  });

  @override
  ConsumerState<_PartyTxnSheet> createState() => _PartyTxnSheetState();
}

class _PartyTxnSheetState extends ConsumerState<_PartyTxnSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  double _calcValue = 0;
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.cash;
  int? _accountId;
  bool _saving = false;
  String? _billImagePath;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Manual date+time picker (user-requested 2026-10-25). The entry
  /// defaults to the REAL current date/time; the user can backdate the
  /// entry and also set the exact time. Previously this was a date-only
  /// picker that silently reset the time to midnight.
  Future<void> _pickDate() async {
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

  Future<void> _pickBillImage() async {
    final t = FragmentStrings.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(c).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.khata_imageAddKarein,
                  style: Theme.of(c)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text(t.khata_camera),
              onTap: () => Navigator.of(c).pop('camera'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: Text(t.khata_gallery),
              onTap: () => Navigator.of(c).pop('gallery'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'camera') {
      // No camera plugin in the offline dependency lockdown (pubspec is
      // Module-A owned); gallery picking works via file_picker.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.khata_noCamera)),
      );
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
    );
    final path = picked.isEmpty ? null : picked.first.path;
    if (path != null && mounted) {
      // Copy into the app's private bills dir before keeping the path:
      // the raw picker path lives in a cache the OS can clean, which
      // would silently orphan the attachment on the saved entry.
      final stored = await _persistBillCopy(path);
      if (!mounted) return;
      setState(() => _billImagePath = stored);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.khata_billAttached)),
      );
    }
  }

  /// Copies a picked bill image into the app's private `bills/` folder
  /// (the durable location BillAttachmentService also uses) and returns
  /// the stored path. Falls back to the original path when the copy fails.
  Future<String> _persistBillCopy(String sourcePath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'bills'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final name =
          'bill_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final dest = await File(sourcePath).copy(p.join(dir.path, name));
      return dest.path;
    } catch (_) {
      return sourcePath;
    }
  }

  void _invalidate() {
    ref.invalidate(customerDetailProvider);
    ref.invalidate(supplierDetailProvider);
    ref.invalidate(customerLedgerProvider);
    ref.invalidate(supplierLedgerProvider);
    ref.invalidate(khataSummaryProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(supplierListProvider);
  }

  Future<void> _save() async {
    final t = FragmentStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_calcValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).val_invalidAmount)),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.customers_selectAccount)),
      );
      return;
    }
    final amountPaisa = (_calcValue * 100).round();

    setState(() => _saving = true);
    try {
      final accounting = await ref.watch(accountingServiceProvider.future);
      final note = _note.text.trim();
      // The attached bill image is persisted on BOTH ledger legs of the
      // payment journal (ledger_entries.bill_image_path) so the entry's
      // detail views (Transaction Center, party detail) can show it.
      if (widget.kind == PartyTxnKind.receive) {
        await accounting.postCustomerPayment(
          customerId: widget.partyId,
          accountId: _accountId!,
          amountPaisa: amountPaisa,
          date: _date,
          method: _method,
          notes: note.isEmpty ? null : note,
          idempotencyKey: newIdempotencyKey(),
          billImagePath: _billImagePath,
        );
      } else {
        await accounting.postSupplierPayment(
          supplierId: widget.partyId,
          accountId: _accountId!,
          amountPaisa: amountPaisa,
          date: _date,
          method: _method,
          notes: note.isEmpty ? null : note,
          idempotencyKey: newIdempotencyKey(),
          billImagePath: _billImagePath,
        );
      }
      _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.customers_paymentSaved)),
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
    final t = FragmentStrings.of(context);
    final title = widget.kind == PartyTxnKind.receive
        ? t.customers_paymentTitleReceive
        : t.customers_paymentTitlePay;
    // Green for money in, red for money out — matches the Diye/Liye buttons.
    final saveColor = widget.kind == PartyTxnKind.receive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE85D5D);

    final accountsAsync = ref.watch(cashAccountRepositoryProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
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
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              CalculatorPad(
                onValue: (v) => setState(() => _calcValue = v),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _note,
                label: t.customers_note,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Date chip gets the larger share and its label scales
                  // down to fit: the full "25 Oct, 26 · 12:56 PM" must
                  // never ellipsize the AM/PM away (user-reported).
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // Date AND time (user-requested 2026-10-25).
                          '${DateFormat('d MMM, yy', Localizations.localeOf(context).toLanguageTag()).format(_date)} · ${DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(_date)}',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.khata_addBills,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      onPressed: _pickBillImage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_billImagePath != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_billImagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _billImagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(t.customers_method,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text(t.customers_cash),
                    icon: const Icon(Icons.money),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.bank,
                    label: Text(t.customers_bank),
                    icon: const Icon(Icons.account_balance),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (sel) => setState(() {
                  _method = sel.first;
                  _accountId = null;
                }),
              ),
              const SizedBox(height: 12),
              accountsAsync.when(
                data: (repo) => FutureBuilder<List<CashAccount>>(
                  future: repo.getAll(),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? const <CashAccount>[];
                    final wantType = _method == PaymentMethod.cash
                        ? CashAccountType.cash
                        : CashAccountType.bank;
                    final options =
                        all.where((a) => a.type == wantType).toList();
                    if (_accountId != null &&
                        !options.any((a) => a.id == _accountId)) {
                      _accountId = null;
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _accountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t.customers_account,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final a in options)
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _accountId = v),
                    );
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.error_generic),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: saveColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(l10n.common_save.toUpperCase()),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
