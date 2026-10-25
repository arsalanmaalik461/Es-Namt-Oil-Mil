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
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'khata_providers.dart';

/// Bottom sheet that records cash udhaar (a loan given) to a customer via
/// [AccountingService.postCustomerUdhaar]: Dr Customer / Cr Cash|Bank,
/// category 'udhaar' — NOT a goods sale.
///
/// Fields: amount, date, bill image (optional), source account (cash/bank
/// picker), optional note. The bill image is persisted on the udhaar
/// journal's ledger entries (`bill_image_path`) and shown in entry details.
/// Returns `true` when the udhaar was posted.
Future<bool> showUdhaarSheet(
  BuildContext context,
  WidgetRef ref, {
  required int customerId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _UdhaarSheet(customerId: customerId),
  );
  return result ?? false;
}

class _UdhaarSheet extends ConsumerStatefulWidget {
  final int customerId;

  const _UdhaarSheet({required this.customerId});

  @override
  ConsumerState<_UdhaarSheet> createState() => _UdhaarSheetState();
}

class _UdhaarSheetState extends ConsumerState<_UdhaarSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.cash;
  int? _accountId;
  bool _saving = false;
  String? _billImagePath;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Date picker chained into a time picker (same fix as
    // party_txn_sheet): picking a date must not silently reset the entry
    // to midnight — entries record date AND time.
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

  /// Bill photo attach — same flow as the payment sheet: pick from the
  /// gallery, copy into the app's private bills dir, keep the stored path
  /// so it can be persisted on the udhaar journal at save time.
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
      // Same as the payment sheet: no direct camera capture in this
      // flow; gallery picking works via file_picker.
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
      // Copy into the app's private bills dir: the raw picker path lives
      // in a cache the OS can clean, which would orphan the attachment.
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
    ref.invalidate(customerLedgerProvider);
    ref.invalidate(khataSummaryProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(customerListProvider);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.customers_selectAccount)),
      );
      return;
    }
    late final int amountPaisa;
    try {
      amountPaisa = parsePkrToPaisa(_amount.text);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.val_invalidAmount)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final accounting = await ref.watch(accountingServiceProvider.future);
      final note = _note.text.trim();
      await accounting.postCustomerUdhaar(
        customerId: widget.customerId,
        accountId: _accountId!,
        amountPaisa: amountPaisa,
        date: _date,
        note: note.isEmpty ? null : note,
        idempotencyKey: newIdempotencyKey(),
        billImagePath: _billImagePath,
      );
      _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.udhaar_saved)),
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
    final t = AppLocalizations.of(context);
    final ft = FragmentStrings.of(context);
    // Date AND time, e.g. "25 Oct, 26 · 11:39 AM" (same compact chip
    // format as the payment sheet so the AM/PM always fits).
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel =
        '${DateFormat('d MMM, yy', localeTag).format(_date)} · ${DateFormat.jm(localeTag).format(_date)}';

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
              Text(t.udhaar_title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField.numeric(
                controller: _amount,
                label: t.customers_amount,
                validator: AppValidators.amount(context),
                textInputAction: TextInputAction.next,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              // Date chip + Add bills chip, mirroring the payment sheet.
              // The date label sits in a FittedBox so the full
              // "25 Oct, 26 · 12:56 PM" is always visible at 360px.
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          dateLabel,
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
                          ft.khata_addBills,
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
                error: (_, __) => Text(t.error_generic),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _note,
                label: t.customers_note,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: t.common_save,
                onPressed: _saving ? null : _save,
                isLoading: _saving,
                expanded: true,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: t.common_cancel,
                variant: AppButtonVariant.secondary,
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(false),
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
