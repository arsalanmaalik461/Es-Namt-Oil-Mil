import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/date_filter_chips.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';

/// Cashbook: account selector, balance header, ledger entries with a date
/// filter. Receipts and payments are posted against customers/suppliers
/// (khata-correct: they move the party balance); transfers move money
/// between accounts and never touch income/expense.
class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookData {
  final List<CashAccount> accounts;
  final CashAccount? account;
  final LedgerStatement statement;

  const _CashbookData(this.accounts, this.account, this.statement);
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  int? _accountId;
  DateFilter _filter = DateFilter.month;
  late Future<_CashbookData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  (DateTime?, DateTime?) _range() {
    final now = DateTime.now();
    return switch (_filter) {
      DateFilter.today => (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1)
        ),
      DateFilter.week => (now.subtract(const Duration(days: 7)), null),
      DateFilter.month => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1)
        ),
      DateFilter.all => (null, null),
    };
  }

  Future<_CashbookData> _load() async {
    final accountsRepo = await ref.read(cashAccountRepositoryProvider.future);
    final accounting = await ref.read(accountingServiceProvider.future);
    final accounts = await accountsRepo.getAll();
    CashAccount? account;
    if (accounts.isNotEmpty) {
      account = accounts.where((a) => a.id == _accountId).firstOrNull ??
          accounts.first;
      _accountId = account.id;
    }
    final (from, to) = _range();
    final statement = account == null
        ? const LedgerStatement(
            accountType: AccountType.cash,
            accountId: 0,
            openingBalancePaisa: 0,
            lines: [],
          )
        : await accounting.ledgerWithRunningBalance(
            accountType: account.type == CashAccountType.cash
                ? AccountType.cash
                : AccountType.bank,
            accountId: account.id!,
            from: from,
            to: to,
          );
    return _CashbookData(accounts, account, statement);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashbook_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined),
            tooltip: l10n.cashbook_addAccount,
            onPressed: () async {
              final saved = await showDialog<bool>(
                context: context,
                builder: (_) => const _AccountDialog(account: null),
              );
              if (saved == true) _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<_CashbookData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            return ErrorState(
              message: err is AppException
                  ? errorText(context, err)
                  : l10n.error_generic,
              onRetry: _refresh,
            );
          }
          return _buildBody(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, _CashbookData data) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final account = data.account;
    if (account == null) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.cashbook_noAccounts,
        actionLabel: l10n.cashbook_addAccount,
        onAction: () async {
          final saved = await showDialog<bool>(
            context: context,
            builder: (_) => const _AccountDialog(account: null),
          );
          if (saved == true) _refresh();
        },
      );
    }
    final lines = data.statement.lines.reversed.toList();
    var totalIn = 0;
    var totalOut = 0;
    for (final line in data.statement.lines) {
      totalIn += line.entry.debitPaisa;
      totalOut += line.entry.creditPaisa;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: account.id,
                          decoration: InputDecoration(
                              labelText: l10n.cashbook_accounts),
                          items: [
                            for (final a in data.accounts)
                              DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                    '${a.name} (${cashAccountTypeLabel(l10n, a.type)})'),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _accountId = v;
                                _future = _load();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.cashbook_editAccount,
                        onPressed: () async {
                          final saved = await showDialog<bool>(
                            context: context,
                            builder: (_) => _AccountDialog(account: account),
                          );
                          if (saved == true) _refresh();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.cashbook_balance,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  AmountText(
                    paisa: data.statement.closingBalancePaisa,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TotalChip(
                          label: l10n.cashbook_totalIn,
                          paisa: totalIn,
                          positive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TotalChip(
                          label: l10n.cashbook_totalOut,
                          paisa: totalOut,
                          positive: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.cashbook_receipt,
                  icon: Icons.arrow_downward,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final saved = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          _PartyEntryDialog(isReceipt: true, account: account),
                    );
                    if (saved == true) _refresh();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: l10n.cashbook_payment,
                  icon: Icons.arrow_upward,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final saved = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          _PartyEntryDialog(isReceipt: false, account: account),
                    );
                    if (saved == true) _refresh();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: l10n.cashbook_transfer,
                  icon: Icons.swap_horiz,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final saved = await showDialog<bool>(
                      context: context,
                      builder: (_) => _TransferDialog(
                          accounts: data.accounts, fromAccount: account),
                    );
                    if (saved == true) _refresh();
                  },
                ),
              ),
            ],
          ),
        ),
        DateFilterChips(
          selected: _filter,
          onSelected: (f) => setState(() {
            _filter = f;
            _future = _load();
          }),
        ),
        Expanded(
          child: lines.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: l10n.cashbook_noEntries,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: lines.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final e = line.entry;
                    final isIn = e.debitPaisa > 0;
                    final description =
                        e.description ?? e.referenceType ?? e.entryNo;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (isIn
                                ? Colors.green
                                : Theme.of(context).colorScheme.error)
                            .withValues(alpha: 0.15),
                        child: Icon(
                          isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 20,
                          color: isIn
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      title: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${dateFormat.format(e.date)} • '
                        '${l10n.cashbook_balance}: '
                        '${formatPkr(line.runningBalancePaisa)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: AmountText(
                        paisa: isIn ? e.debitPaisa : e.creditPaisa,
                        positive: isIn ? true : false,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final int paisa;
  final bool positive;

  const _TotalChip(
      {required this.label, required this.paisa, required this.positive});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          AmountText(
              paisa: paisa,
              positive: positive,
              style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// Receipt (from customer) / payment (to supplier) dialog.
class _PartyEntryDialog extends ConsumerStatefulWidget {
  final bool isReceipt;
  final CashAccount account;

  const _PartyEntryDialog({required this.isReceipt, required this.account});

  @override
  ConsumerState<_PartyEntryDialog> createState() => _PartyEntryDialogState();
}

class _PartyEntryDialogState extends ConsumerState<_PartyEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  int? _partyId;
  late Future<List<_PartyOption>> _partiesFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _partiesFuture = () async {
      if (widget.isReceipt) {
        final repo = await ref.read(customerRepositoryProvider.future);
        final customers = await repo.search(limit: 500);
        return [for (final c in customers) _PartyOption(c.id!, c.name)];
      } else {
        final repo = await ref.read(supplierRepositoryProvider.future);
        final suppliers = await repo.search(limit: 500);
        return [for (final s in suppliers) _PartyOption(s.id!, s.name)];
      }
    }();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_partyId == null) return;
    setState(() => _saving = true);
    try {
      final amount = parsePkrToPaisa(_amount.text.trim());
      if (amount <= 0) throw ValidationException('error.invalidAmount');
      final accounting = await ref.read(accountingServiceProvider.future);
      final method = widget.account.type == CashAccountType.cash
          ? PaymentMethod.cash
          : PaymentMethod.bank;
      final reference =
          _reference.text.trim().isEmpty ? null : _reference.text.trim();
      final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
      if (widget.isReceipt) {
        await accounting.postCustomerPayment(
          customerId: _partyId!,
          accountId: widget.account.id!,
          amountPaisa: amount,
          date: _date,
          method: method,
          reference: reference,
          notes: notes,
        );
      } else {
        await accounting.postSupplierPayment(
          supplierId: _partyId!,
          accountId: widget.account.id!,
          amountPaisa: amount,
          date: _date,
          method: method,
          reference: reference,
          notes: notes,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cashbook_errInvalidAmount)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.isReceipt
          ? l10n.cashbook_addReceipt
          : l10n.cashbook_addPayment),
      content: FutureBuilder<List<_PartyOption>>(
        future: _partiesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
                height: 200, child: Center(child: LoadingState()));
          }
          final parties = snapshot.data!;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _partyId,
                    decoration: InputDecoration(
                      labelText: widget.isReceipt
                          ? l10n.cashbook_customer
                          : l10n.cashbook_supplier,
                    ),
                    items: [
                      for (final p in parties)
                        DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _partyId = v),
                    validator: (v) => v == null
                        ? (widget.isReceipt
                            ? l10n.cashbook_selectCustomer
                            : l10n.cashbook_selectSupplier)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField.numeric(
                    controller: _amount,
                    label: l10n.cashbook_amount,
                    autofocus: true,
                    validator: (v) {
                      try {
                        final a = parsePkrToPaisa((v ?? '').trim());
                        if (a <= 0) return l10n.cashbook_errInvalidAmount;
                      } on FormatException {
                        return l10n.cashbook_errInvalidAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title:
                        Text(DateFormat.yMMMd(l10n.localeName).format(_date)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                  AppTextField(
                      controller: _reference, label: l10n.cashbook_reference),
                  const SizedBox(height: 12),
                  AppTextField(controller: _notes, label: l10n.cashbook_notes),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.common_save),
        ),
      ],
    );
  }
}

class _PartyOption {
  final int id;
  final String name;

  const _PartyOption(this.id, this.name);
}

/// Transfer dialog: from -> to accounts. Never income/expense.
class _TransferDialog extends ConsumerStatefulWidget {
  final List<CashAccount> accounts;
  final CashAccount fromAccount;

  const _TransferDialog({required this.accounts, required this.fromAccount});

  @override
  ConsumerState<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  late int _fromId;
  int? _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.fromAccount.id!;
    _toId = widget.accounts.where((a) => a.id != _fromId).firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_toId == null || _toId == _fromId) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.cashbook_errTransferSame)));
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = parsePkrToPaisa(_amount.text.trim());
      final accounting = await ref.read(accountingServiceProvider.future);
      await accounting.postTransfer(
        fromAccountId: _fromId,
        toAccountId: _toId!,
        amountPaisa: amount,
        date: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cashbook_errInvalidAmount)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String accountLabel(CashAccount a) =>
        '${a.name} (${cashAccountTypeLabel(l10n, a.type)})';
    return AlertDialog(
      title: Text(l10n.cashbook_newTransfer),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.cashbook_transferInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _fromId,
                decoration: InputDecoration(labelText: l10n.cashbook_from),
                items: [
                  for (final a in widget.accounts)
                    DropdownMenuItem(value: a.id, child: Text(accountLabel(a))),
                ],
                onChanged: (v) => setState(() {
                  _fromId = v ?? _fromId;
                  if (_toId == _fromId) _toId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _toId,
                decoration: InputDecoration(labelText: l10n.cashbook_to),
                items: [
                  for (final a in widget.accounts.where((a) => a.id != _fromId))
                    DropdownMenuItem(value: a.id, child: Text(accountLabel(a))),
                ],
                onChanged: (v) => setState(() => _toId = v),
                validator: (v) =>
                    v == null ? l10n.cashbook_errTransferSame : null,
              ),
              const SizedBox(height: 12),
              AppTextField.numeric(
                controller: _amount,
                label: l10n.cashbook_amount,
                autofocus: true,
                validator: (v) {
                  try {
                    final a = parsePkrToPaisa((v ?? '').trim());
                    if (a <= 0) return l10n.cashbook_errInvalidAmount;
                  } on FormatException {
                    return l10n.cashbook_errInvalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat.yMMMd(l10n.localeName).format(_date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              AppTextField(controller: _notes, label: l10n.cashbook_notes),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.common_save),
        ),
      ],
    );
  }
}

/// Add / edit cash or bank account.
class _AccountDialog extends ConsumerStatefulWidget {
  final CashAccount? account;

  const _AccountDialog({required this.account});

  @override
  ConsumerState<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController();
  CashAccountType _type = CashAccountType.cash;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _name.text = a.name;
      _type = a.type;
      if (a.openingBalancePaisa > 0) {
        _opening.text = (a.openingBalancePaisa / paisaPerRupee).toString();
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = await ref.read(cashAccountRepositoryProvider.future);
      final opening = _opening.text.trim().isEmpty
          ? 0
          : parsePkrToPaisa(_opening.text.trim());
      final existing = widget.account;
      if (existing == null) {
        await repo.insert(CashAccount(
          name: _name.text.trim(),
          type: _type,
          openingBalancePaisa: opening,
        ));
      } else {
        await repo.update(existing.copyWith(
          name: _name.text.trim(),
          type: _type,
          openingBalancePaisa: opening,
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cashbook_errInvalidAmount)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.account == null
          ? l10n.cashbook_addAccount
          : l10n.cashbook_editAccount),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _name,
              label: l10n.cashbook_accountName,
              autofocus: true,
              validator: AppValidators.required(context),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CashAccountType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.cashbook_accountType),
              items: [
                for (final t in CashAccountType.values)
                  DropdownMenuItem(
                      value: t, child: Text(cashAccountTypeLabel(l10n, t))),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            AppTextField.numeric(
              controller: _opening,
              label: l10n.cashbook_openingBalance,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                try {
                  final a = parsePkrToPaisa(v.trim());
                  if (a < 0) return l10n.cashbook_errInvalidAmount;
                } on FormatException {
                  return l10n.cashbook_errInvalidAmount;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.common_save),
        ),
      ],
    );
  }
}
