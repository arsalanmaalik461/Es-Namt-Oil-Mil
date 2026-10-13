import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/models/supplier.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'khata_providers.dart';

/// Which kind of party the form edits.
enum PartyKind { customer, supplier }

/// Bottom sheet for creating or editing a customer / supplier.
///
/// Fields: name, phone, address, code, business name, notes and (on create
/// only) the opening balance. Parties are created through the repository
/// (CRUD-only, per `docs/API.md`); the opening balance is stored on the
/// party row, balances themselves stay ledger-owned.
///
/// Returns `true` when a party was saved.
Future<bool> showPartyFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required PartyKind kind,
  Customer? customer,
  Supplier? supplier,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _PartyFormSheet(
      kind: kind,
      customer: customer,
      supplier: supplier,
    ),
  );
  return result ?? false;
}

class _PartyFormSheet extends ConsumerStatefulWidget {
  final PartyKind kind;
  final Customer? customer;
  final Supplier? supplier;

  const _PartyFormSheet({
    required this.kind,
    this.customer,
    this.supplier,
  });

  @override
  ConsumerState<_PartyFormSheet> createState() => _PartyFormSheetState();
}

class _PartyFormSheetState extends ConsumerState<_PartyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _code;
  late final TextEditingController _businessName;
  late final TextEditingController _notes;
  late final TextEditingController _openingBalance;
  bool _saving = false;

  bool get _isCustomer => widget.kind == PartyKind.customer;
  bool get _isEdit => widget.customer != null || widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final s = widget.supplier;
    _name = TextEditingController(text: c?.name ?? s?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? s?.phone ?? '');
    _address = TextEditingController(text: c?.address ?? s?.address ?? '');
    _code = TextEditingController(text: c?.code ?? s?.code ?? '');
    _businessName =
        TextEditingController(text: c?.businessName ?? s?.businessName ?? '');
    _notes = TextEditingController(text: c?.notes ?? s?.notes ?? '');
    final opening = c?.openingBalancePaisa ?? s?.openingBalancePaisa ?? 0;
    _openingBalance = TextEditingController(
      text: opening == 0 ? '' : formatPkr(opening).replaceFirst('Rs ', ''),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _code.dispose();
    _businessName.dispose();
    _notes.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  void _invalidateLists() {
    ref.invalidate(customerListProvider);
    ref.invalidate(supplierListProvider);
    ref.invalidate(khataSummaryProvider);
    ref.invalidate(dashboardDataProvider);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    int openingPaisa = 0;
    final openingText = _openingBalance.text.trim();
    if (openingText.isNotEmpty) {
      try {
        openingPaisa = parsePkrToPaisa(openingText);
      } on FormatException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.val_invalidAmount)),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      if (_isCustomer) {
        final repo = await ref.watch(customerRepositoryProvider.future);
        if (widget.customer != null) {
          await repo.update(widget.customer!.copyWith(
            name: _name.text.trim(),
            phone: _nullIfEmpty(_phone.text),
            address: _nullIfEmpty(_address.text),
            code: _nullIfEmpty(_code.text),
            businessName: _nullIfEmpty(_businessName.text),
            notes: _nullIfEmpty(_notes.text),
          ));
        } else {
          await repo.insert(Customer(
            name: _name.text.trim(),
            phone: _nullIfEmpty(_phone.text),
            address: _nullIfEmpty(_address.text),
            code: _nullIfEmpty(_code.text),
            businessName: _nullIfEmpty(_businessName.text),
            notes: _nullIfEmpty(_notes.text),
            openingBalancePaisa: openingPaisa,
          ));
        }
      } else {
        final repo = await ref.watch(supplierRepositoryProvider.future);
        if (widget.supplier != null) {
          await repo.update(widget.supplier!.copyWith(
            name: _name.text.trim(),
            phone: _nullIfEmpty(_phone.text),
            address: _nullIfEmpty(_address.text),
            code: _nullIfEmpty(_code.text),
            businessName: _nullIfEmpty(_businessName.text),
            notes: _nullIfEmpty(_notes.text),
          ));
        } else {
          await repo.insert(Supplier(
            name: _name.text.trim(),
            phone: _nullIfEmpty(_phone.text),
            address: _nullIfEmpty(_address.text),
            code: _nullIfEmpty(_code.text),
            businessName: _nullIfEmpty(_businessName.text),
            notes: _nullIfEmpty(_notes.text),
            openingBalancePaisa: openingPaisa,
          ));
        }
      }
      _invalidateLists();
      if (!mounted) return;
      final t = FragmentStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.customers_saved)),
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

  String? _nullIfEmpty(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = FragmentStrings.of(context);
    final title = _isEdit
        ? (_isCustomer ? t.customers_editCustomer : t.customers_editSupplier)
        : (_isCustomer ? t.customers_newCustomer : t.customers_newSupplier);

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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: t.customers_name,
                validator: AppValidators.required(context),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phone,
                label: t.customers_phone,
                keyboardType: TextInputType.phone,
                validator: AppValidators.phone(context),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _businessName,
                label: t.customers_businessName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _code,
                label: t.customers_code,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: t.customers_address,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notes,
                label: t.customers_notes,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                AppTextField.numeric(
                  controller: _openingBalance,
                  label: t.customers_openingBalance,
                  hint: t.customers_openingBalanceHint,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 6),
                Text(
                  _isCustomer
                      ? t.customers_openingHelpCustomer
                      : t.customers_openingHelpSupplier,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(
                label: l10n.common_save,
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
      ),
    );
  }
}
