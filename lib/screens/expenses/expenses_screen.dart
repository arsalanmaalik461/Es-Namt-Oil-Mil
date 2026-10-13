import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/expense_category.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';

/// Expenses & income: tabs, category chips (expenses), entry form and a
/// summary header with today / this month / this year totals.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.expenses_title),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.expenses_tabExpenses),
              Tab(text: l10n.expenses_tabIncome),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EntriesTab(isIncome: false),
            _EntriesTab(isIncome: true),
          ],
        ),
      ),
    );
  }
}

class _EntryRow {
  final DateTime date;
  final String title;
  final String subtitle;
  final int paisa;

  const _EntryRow(this.date, this.title, this.subtitle, this.paisa);
}

class _TabData {
  final List<ExpenseCategory> categories;
  final List<CashAccount> accounts;
  final List<_EntryRow> entries;
  final int todayPaisa;
  final int monthPaisa;
  final int yearPaisa;

  const _TabData({
    required this.categories,
    required this.accounts,
    required this.entries,
    required this.todayPaisa,
    required this.monthPaisa,
    required this.yearPaisa,
  });
}

class _EntriesTab extends ConsumerStatefulWidget {
  final bool isIncome;

  const _EntriesTab({required this.isIncome});

  @override
  ConsumerState<_EntriesTab> createState() => _EntriesTabState();
}

class _EntriesTabState extends ConsumerState<_EntriesTab> {
  late Future<_TabData> _future;
  int? _categoryId; // null = all (expenses tab only)

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TabData> _load() async {
    final l10n = AppLocalizations.of(context);
    final accounting = await ref.read(accountingServiceProvider.future);
    final accountsRepo = await ref.read(cashAccountRepositoryProvider.future);
    final accounts = await accountsRepo.getAll();
    final accountNames = {for (final a in accounts) a.id!: a.name};
    final now = DateTime.now();
    final isIncome = widget.isIncome;

    List<ExpenseCategory> categories = const [];
    List<_EntryRow> entries;
    int today, month, year;
    if (!isIncome) {
      final repo = await ref.read(expenseRepositoryProvider.future);
      categories = await repo.getCategories();
      final catNames = {for (final c in categories) c.id!: c.name};
      final all = await repo.list(limit: 1000000);
      entries = [
        for (final e in all)
          _EntryRow(
            e.date,
            (e.description?.trim().isEmpty ?? true)
                ? (catNames[e.categoryId] ?? '')
                : e.description!.trim(),
            accountNames[e.accountId] ?? '',
            e.amountPaisa,
          ),
      ];
      final daily = await accounting.dailySummary(now);
      final monthly = await accounting.monthlySummary(now.year, now.month);
      today = daily.expensesPaisa;
      month = monthly.expensesPaisa;
      year = all
          .where((e) => e.date.year == now.year)
          .fold(0, (s, e) => s + e.amountPaisa);
    } else {
      final repo = await ref.read(incomeRepositoryProvider.future);
      final all = await repo.list(limit: 1000000);
      entries = [
        for (final e in all)
          _EntryRow(
            e.date,
            (e.description?.trim().isEmpty ?? true)
                ? ((e.category?.trim().isEmpty ?? true)
                    ? l10n.expenses_tabIncome
                    : e.category!.trim())
                : e.description!.trim(),
            accountNames[e.accountId] ?? '',
            e.amountPaisa,
          ),
      ];
      final daily = await accounting.dailySummary(now);
      final monthly = await accounting.monthlySummary(now.year, now.month);
      today = daily.incomePaisa;
      month = monthly.incomePaisa;
      year = all
          .where((e) => e.date.year == now.year)
          .fold(0, (s, e) => s + e.amountPaisa);
    }

    return _TabData(
      categories: categories,
      accounts: accounts,
      entries: entries,
      todayPaisa: today,
      monthPaisa: month,
      yearPaisa: year,
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await showDialog<bool>(
            context: context,
            builder: (_) => _EntryDialog(
              isIncome: widget.isIncome,
              preselectedCategoryId: _categoryId,
            ),
          );
          if (saved == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: Text(widget.isIncome
            ? l10n.expenses_addIncome
            : l10n.expenses_addExpense),
      ),
      body: FutureBuilder<_TabData>(
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

  Widget _buildBody(BuildContext context, _TabData data) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    return Column(
      children: [
        _SummaryHeader(data: data, isIncome: widget.isIncome),
        if (!widget.isIncome)
          _CategoryChips(
            categories: data.categories,
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
            onAdd: () async {
              final added = await showDialog<bool>(
                context: context,
                builder: (_) => const _CategoryDialog(),
              );
              if (added == true) _refresh();
            },
          ),
        Expanded(
          child: FutureBuilder<List<_EntryRow>>(
            future: _filteredEntries(data),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingState();
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: l10n.expenses_noEntries,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6),
                      child: Icon(
                        widget.isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      row.title.isEmpty
                          ? (widget.isIncome
                              ? l10n.expenses_tabIncome
                              : l10n.expenses_tabExpenses)
                          : row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${dateFormat.format(row.date)}'
                      '${row.subtitle.isEmpty ? '' : ' • ${row.subtitle}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: AmountText(
                      paisa: row.paisa,
                      positive: widget.isIncome ? true : false,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Applies the selected category filter (expenses tab) by reloading the
  /// filtered list from the repository — cheap and always correct.
  Future<List<_EntryRow>> _filteredEntries(_TabData data) async {
    if (widget.isIncome || _categoryId == null) return data.entries;
    final repo = await ref.read(expenseRepositoryProvider.future);
    final accountNames = {for (final a in data.accounts) a.id!: a.name};
    final catNames = {for (final c in data.categories) c.id!: c.name};
    final all = await repo.list(categoryId: _categoryId, limit: 1000000);
    return [
      for (final e in all)
        _EntryRow(
          e.date,
          (e.description?.trim().isEmpty ?? true)
              ? (catNames[e.categoryId] ?? '')
              : e.description!.trim(),
          accountNames[e.accountId] ?? '',
          e.amountPaisa,
        ),
    ];
  }
}

class _SummaryHeader extends StatelessWidget {
  final _TabData data;
  final bool isIncome;

  const _SummaryHeader({required this.data, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
              child: _SummaryCard(
                  label: l10n.expenses_today, paisa: data.todayPaisa)),
          const SizedBox(width: 8),
          Expanded(
              child: _SummaryCard(
                  label: l10n.expenses_thisMonth, paisa: data.monthPaisa)),
          const SizedBox(width: 8),
          Expanded(
              child: _SummaryCard(
                  label: l10n.expenses_thisYear, paisa: data.yearPaisa)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int paisa;

  const _SummaryCard({required this.label, required this.paisa});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          AmountText(
            paisa: paisa,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final VoidCallback onAdd;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(l10n.inventory_all),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                onSelected: (_) => onSelected(c.id),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l10n.expenses_addCategory),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Entry form dialog: date, category, amount, account, description, reference.
class _EntryDialog extends ConsumerStatefulWidget {
  final bool isIncome;
  final int? preselectedCategoryId;

  const _EntryDialog({required this.isIncome, this.preselectedCategoryId});

  @override
  ConsumerState<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends ConsumerState<_EntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _incomeCategory = TextEditingController();
  final _description = TextEditingController();
  final _reference = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  int? _accountId;
  late Future<_DialogData> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.preselectedCategoryId;
    _future = _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _incomeCategory.dispose();
    _description.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<_DialogData> _load() async {
    final accountsRepo = await ref.read(cashAccountRepositoryProvider.future);
    final accounts = await accountsRepo.getAll();
    List<ExpenseCategory> categories = const [];
    if (!widget.isIncome) {
      final expenseRepo = await ref.read(expenseRepositoryProvider.future);
      categories = await expenseRepo.getCategories();
    }
    return _DialogData(accounts, categories);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) return;
    if (!widget.isIncome && _categoryId == null) return;
    setState(() => _saving = true);
    try {
      final amount = parsePkrToPaisa(_amount.text.trim());
      if (amount <= 0) throw ValidationException('error.invalidAmount');
      final accounting = await ref.read(accountingServiceProvider.future);
      final description =
          _description.text.trim().isEmpty ? null : _description.text.trim();
      final reference =
          _reference.text.trim().isEmpty ? null : _reference.text.trim();
      if (widget.isIncome) {
        final category = _incomeCategory.text.trim().isEmpty
            ? null
            : _incomeCategory.text.trim();
        await accounting.postIncome(
          accountId: _accountId!,
          amountPaisa: amount,
          date: _date,
          category: category,
          description: description,
          reference: reference,
        );
      } else {
        await accounting.postExpense(
          categoryId: _categoryId!,
          accountId: _accountId!,
          amountPaisa: amount,
          date: _date,
          description: description,
          reference: reference,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isIncome
              ? l10n.expenses_incomeSaved
              : l10n.expenses_expenseSaved)));
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenses_errInvalidAmount)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
          widget.isIncome ? l10n.expenses_addIncome : l10n.expenses_addExpense),
      content: FutureBuilder<_DialogData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
                height: 240, child: Center(child: LoadingState()));
          }
          final data = snapshot.data!;
          _accountId ??= data.accounts.firstOrNull?.id;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(l10n.expenses_date),
                    subtitle:
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
                  if (widget.isIncome)
                    AppTextField(
                      controller: _incomeCategory,
                      label: l10n.expenses_incomeCategory,
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration:
                          InputDecoration(labelText: l10n.expenses_category),
                      items: [
                        for (final c in data.categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? l10n.val_required : null,
                    ),
                  const SizedBox(height: 12),
                  AppTextField.numeric(
                    controller: _amount,
                    label: l10n.expenses_amount,
                    autofocus: true,
                    validator: (v) {
                      try {
                        final a = parsePkrToPaisa((v ?? '').trim());
                        if (a <= 0) {
                          return l10n.expenses_errInvalidAmount;
                        }
                      } on FormatException {
                        return l10n.expenses_errInvalidAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    decoration:
                        InputDecoration(labelText: l10n.expenses_account),
                    items: [
                      for (final a in data.accounts)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                              '${a.name} (${cashAccountTypeLabel(l10n, a.type)})'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _accountId = v),
                    validator: (v) => v == null ? l10n.val_required : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                      controller: _description,
                      label: l10n.expenses_description),
                  const SizedBox(height: 12),
                  AppTextField(
                      controller: _reference, label: l10n.expenses_reference),
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

class _DialogData {
  final List<CashAccount> accounts;
  final List<ExpenseCategory> categories;

  const _DialogData(this.accounts, this.categories);
}

/// New custom expense category dialog.
class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog();

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.insertCategory(ExpenseCategory(name: _name.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.expenses_categorySaved)));
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.expenses_addCategory),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _name,
          label: l10n.expenses_categoryName,
          autofocus: true,
          validator: AppValidators.required(context),
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
