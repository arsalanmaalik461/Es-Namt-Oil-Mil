import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:namt_oil_mil/core/app_exception.dart';
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
/// Fields: amount, date, source account (cash/bank picker), optional note.
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
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
    final dateLabel =
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(_date);

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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(t.customers_date),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 4),
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
                      decoration: InputDecoration(
                        labelText: t.customers_account,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final a in options)
                          DropdownMenuItem(value: a.id, child: Text(a.name)),
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
