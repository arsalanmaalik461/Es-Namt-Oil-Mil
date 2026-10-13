import 'package:file_picker/file_picker.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/repositories/report_repository.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/cash_account.dart';
import 'package:namt_oil_mil/models/payment.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/screens/reports/document_data.dart';
import 'package:namt_oil_mil/screens/reports/report_definitions.dart';
import 'package:namt_oil_mil/screens/reports/report_pickers.dart';
import 'package:namt_oil_mil/services/pdf/pdf_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/date_filter_chips.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/ledger_row.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';
import 'package:namt_oil_mil/widgets/summary_card.dart';
import 'package:namt_oil_mil/widgets/txn_row.dart';

// ===========================================================================
// ReportDetailScreen — serves BOTH modes of /report-detail:
//   {'report': <key>, ...}   -> analytical report with filters
//   {'document': <type>, 'id': <id>} -> branded document preview + PDF actions
// ===========================================================================

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const ReportDetailScreen({super.key, this.args = const {}});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final reportKey = args['report'];
    if (reportKey is String) {
      return _ReportView(reportKey: reportKey);
    }
    final documentType = args['document'];
    final id = args['id'];
    if (documentType is String && id is int) {
      return _DocumentView(
        documentType: documentType,
        id: id,
        from: args['from'] is DateTime ? args['from'] as DateTime : null,
        to: args['to'] is DateTime ? args['to'] as DateTime : null,
      );
    }
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ErrorState(
        message: l10n.error_generic,
        onRetry: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ===========================================================================
// Report view models (UI-only; all figures come from AccountingService /
// ReportRepository / repositories per docs/API.md — never computed ad hoc)
// ===========================================================================

class _Kpi {
  final String label;
  final int? paisa;
  final String? text;
  final bool? positive;

  const _Kpi({required this.label, this.paisa, this.text, this.positive});
}

class _Line {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int? paisa;
  final bool? positive;
  final String? trailingText;

  /// Ledger-style rendering (running balance) when non-null.
  final int? runningBalancePaisa;
  final bool? isDebit;

  /// Copy-to-clipboard action (payment reminders).
  final String? copyText;

  /// Tap navigates to a document preview: {'document': ..., 'id': ...}.
  final Map<String, dynamic>? documentArgs;

  const _Line({
    required this.icon,
    required this.title,
    this.subtitle,
    this.paisa,
    this.positive,
    this.trailingText,
    this.runningBalancePaisa,
    this.isDebit,
    this.copyText,
    this.documentArgs,
  });
}

class _Section {
  final String title;
  final List<_Line> lines;

  const _Section(this.title, this.lines);
}

class _ReportResult {
  final List<_Kpi> kpis;
  final List<_Section> sections;

  /// P&L-style disclaimer shown under the KPIs.
  final String? note;

  /// Shown instead of data when a required filter (party/product/account)
  /// has not been picked yet.
  final String? prompt;
  final String? promptActionLabel;
  final Future<void> Function()? onPromptAction;

  const _ReportResult({
    this.kpis = const [],
    this.sections = const [],
    this.note,
    this.prompt,
    this.promptActionLabel,
    this.onPromptAction,
  });

  bool get isEmpty =>
      prompt == null && kpis.isEmpty && sections.every((s) => s.lines.isEmpty);
}

// ===========================================================================
// _ReportView
// ===========================================================================

class _ReportView extends ConsumerStatefulWidget {
  final String reportKey;

  const _ReportView({required this.reportKey});

  @override
  ConsumerState<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<_ReportView> {
  DateFilter _dateFilter = DateFilter.month;
  bool _customRange = false;
  DateTime? _customFrom;
  DateTime? _customTo;
  DateTime _singleDate = DateTime.now();
  DateTime _monthDate = DateTime.now();

  int? _partyId;
  String? _partyName;
  int? _productId;
  String? _productName;
  List<CashAccount> _accounts = [];
  int? _accountId;

  late Future<_ReportResult> _future;

  // Name caches to avoid N+1 provider reads on rebuilds.
  final _customerNames = <int, String>{};
  final _supplierNames = <int, String>{};
  final _accountNames = <int, String>{};
  final _unitSymbols = <int, String>{};

  bool get _needsRange => !{
        ReportKeys.dailySummary,
        ReportKeys.monthlySummary,
        ReportKeys.receivables,
        ReportKeys.payables,
        ReportKeys.cashBankBalances,
        ReportKeys.inventoryValuation,
        ReportKeys.lowStock,
        ReportKeys.outstandingInvoices,
        ReportKeys.trialBalance,
      }.contains(widget.reportKey);

  bool get _needsSingleDate =>
      widget.reportKey == ReportKeys.dailySummary ||
      widget.reportKey == ReportKeys.daybook;

  bool get _needsMonth => widget.reportKey == ReportKeys.monthlySummary;

  bool get _needsCustomer => {
        ReportKeys.customerLedger,
        ReportKeys.sales,
        ReportKeys.paymentsReceived,
        ReportKeys.salesReturns,
      }.contains(widget.reportKey);

  bool get _needsSupplier => {
        ReportKeys.supplierLedger,
        ReportKeys.purchase,
        ReportKeys.paymentsMade,
        ReportKeys.purchaseReturns,
      }.contains(widget.reportKey);

  bool get _needsProduct => widget.reportKey == ReportKeys.stockMovement;

  bool get _needsAccount => widget.reportKey == ReportKeys.cashbook;

  bool get _partyRequired =>
      widget.reportKey == ReportKeys.customerLedger ||
      widget.reportKey == ReportKeys.supplierLedger;

  @override
  void initState() {
    super.initState();
    _future = _loadReport();
    if (_needsAccount) _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final repo = await ref.read(cashAccountRepositoryProvider.future);
      final accounts = await repo.getAll();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _accountId ??= accounts.isNotEmpty ? accounts.first.id : null;
      });
      _refresh();
    } on AppException {
      // The report load surfaces the error; the dropdown just stays empty.
    }
  }

  void _refresh() {
    setState(() {
      _future = _loadReport();
    });
  }

  (DateTime, DateTime) _range() {
    if (_customRange && _customFrom != null && _customTo != null) {
      final f =
          DateTime(_customFrom!.year, _customFrom!.month, _customFrom!.day);
      final t0 = DateTime(_customTo!.year, _customTo!.month, _customTo!.day);
      return (f, t0.add(const Duration(days: 1)));
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case DateFilter.today:
        return (today, today.add(const Duration(days: 1)));
      case DateFilter.week:
        return (
          today.subtract(const Duration(days: 6)),
          today.add(const Duration(days: 1))
        );
      case DateFilter.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1)
        );
      case DateFilter.all:
        return (DateTime(2000), DateTime(2100));
    }
  }

  String _fmtQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  Future<String> _customerName(int id) async {
    final cached = _customerNames[id];
    if (cached != null) return cached;
    final repo = await ref.read(customerRepositoryProvider.future);
    final name = (await repo.getById(id))?.name ?? '#$id';
    _customerNames[id] = name;
    return name;
  }

  Future<String> _supplierName(int id) async {
    final cached = _supplierNames[id];
    if (cached != null) return cached;
    final repo = await ref.read(supplierRepositoryProvider.future);
    final name = (await repo.getById(id))?.name ?? '#$id';
    _supplierNames[id] = name;
    return name;
  }

  Future<String> _accountName(int id) async {
    final cached = _accountNames[id];
    if (cached != null) return cached;
    final repo = await ref.read(cashAccountRepositoryProvider.future);
    final name = (await repo.getById(id))?.name ?? '#$id';
    _accountNames[id] = name;
    return name;
  }

  Future<String> _unitSymbol(int id) async {
    final cached = _unitSymbols[id];
    if (cached != null) return cached;
    final repo = await ref.read(unitRepositoryProvider.future);
    final symbol = (await repo.getById(id))?.symbol ?? '';
    _unitSymbols[id] = symbol;
    return symbol;
  }

  String _invoiceStatusLabel(FragmentStrings t, InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.paid:
        return t.reports_paid;
      case InvoiceStatus.unpaid:
        return t.reports_unpaid;
      case InvoiceStatus.partial:
        return t.reports_partial;
      default:
        return s.dbValue;
    }
  }

  // ------------------------------------------------------------ data loading

  Future<_ReportResult> _loadReport() async {
    final t = FragmentStrings.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    String fmt(DateTime d) => DateFormat.yMMMd(localeCode).format(d);

    // Required pickers not chosen yet -> prompt instead of data.
    if (_partyRequired && _partyId == null) {
      final isCustomer = widget.reportKey == ReportKeys.customerLedger;
      return _ReportResult(
        prompt:
            isCustomer ? t.reports_selectCustomer : t.reports_selectSupplier,
        promptActionLabel: t.reports_change,
        onPromptAction: () => _pickParty(),
      );
    }
    if (_needsProduct && _productId == null) {
      return _ReportResult(
        prompt: t.reports_selectProduct,
        promptActionLabel: t.reports_change,
        onPromptAction: () async {
          final id = await pickProductId(context);
          if (id != null && mounted) {
            final repo = await ref.read(productRepositoryProvider.future);
            final p = await repo.getById(id);
            setState(() {
              _productId = id;
              _productName = p?.name;
            });
          }
        },
      );
    }
    if (_needsAccount && _accountId == null) {
      return _ReportResult(prompt: t.reports_selectAccount);
    }

    final accounting = await ref.read(accountingServiceProvider.future);
    final reports = await ref.read(reportRepositoryProvider.future);
    final key = widget.reportKey;

    switch (key) {
      case ReportKeys.dailySummary:
        return _dailySummary(accounting, t, fmt);
      case ReportKeys.monthlySummary:
        return _monthlySummary(accounting, t, fmt);
      case ReportKeys.customerLedger:
        return _partyLedger(reports, t, fmt, isCustomer: true);
      case ReportKeys.supplierLedger:
        return _partyLedger(reports, t, fmt, isCustomer: false);
      case ReportKeys.receivables:
        return _receivables(accounting, t);
      case ReportKeys.payables:
        return _payables(accounting, t);
      case ReportKeys.sales:
        return _sales(reports, t, fmt);
      case ReportKeys.purchase:
        return _purchases(reports, t, fmt);
      case ReportKeys.paymentsReceived:
        return _payments(t, fmt, received: true);
      case ReportKeys.paymentsMade:
        return _payments(t, fmt, received: false);
      case ReportKeys.expense:
        return _expenses(reports, t, fmt);
      case ReportKeys.income:
        return _income(reports, t, fmt);
      case ReportKeys.cashbook:
        return _cashbook(reports, t, fmt);
      case ReportKeys.cashBankBalances:
        return _cashBankBalances(accounting, t);
      case ReportKeys.inventoryValuation:
        return _inventoryValuation(reports, t);
      case ReportKeys.stockMovement:
        return _stockMovement(t, fmt);
      case ReportKeys.lowStock:
        return _lowStock(reports, t);
      case ReportKeys.production:
        return _production(t, fmt, yieldOnly: false);
      case ReportKeys.yieldReport:
        return _production(t, fmt, yieldOnly: true);
      case ReportKeys.salesReturns:
        return _salesReturns(t, fmt);
      case ReportKeys.purchaseReturns:
        return _purchaseReturns(t, fmt);
      case ReportKeys.outstandingInvoices:
        return _outstandingInvoices(t, fmt);
      case ReportKeys.profitLoss:
        return _profitLoss(reports, t);
      case ReportKeys.trialBalance:
        return _trialBalance(accounting, t);
      case ReportKeys.daybook:
        return _daybook(t, fmt);
      default:
        return const _ReportResult();
    }
  }

  Future<_ReportResult> _dailySummary(AccountingService accounting,
      FragmentStrings t, String Function(DateTime) fmt) async {
    final s = await accounting.dailySummary(_singleDate);
    return _ReportResult(kpis: [
      _Kpi(label: t.reports_totalSales, paisa: s.salesPaisa),
      _Kpi(label: t.reports_totalPurchases, paisa: s.purchasesPaisa),
      _Kpi(
          label: t.reports_totalReceived,
          paisa: s.receivedPaisa,
          positive: true),
      _Kpi(label: t.reports_totalPaid, paisa: s.paidPaisa, positive: false),
      _Kpi(
          label: t.reports_totalExpenses,
          paisa: s.expensesPaisa,
          positive: false),
      _Kpi(label: t.reports_totalIncome, paisa: s.incomePaisa, positive: true),
    ]);
  }

  Future<_ReportResult> _monthlySummary(AccountingService accounting,
      FragmentStrings t, String Function(DateTime) fmt) async {
    final s =
        await accounting.monthlySummary(_monthDate.year, _monthDate.month);
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_totalSales, paisa: s.salesPaisa),
        _Kpi(label: t.reports_totalPurchases, paisa: s.purchasesPaisa),
        _Kpi(
            label: t.reports_totalReceived,
            paisa: s.receivedPaisa,
            positive: true),
        _Kpi(label: t.reports_totalPaid, paisa: s.paidPaisa, positive: false),
        _Kpi(
            label: t.reports_totalExpenses,
            paisa: s.expensesPaisa,
            positive: false),
        _Kpi(
            label: t.reports_totalIncome, paisa: s.incomePaisa, positive: true),
      ],
      sections: [
        _Section(t.reports_invoices, [
          _Line(
            icon: Icons.point_of_sale_outlined,
            title: t.reports_saleInvoices,
            subtitle: t.reports_recordsCount(count: s.salesCount),
            paisa: s.salesPaisa,
          ),
          _Line(
            icon: Icons.shopping_cart_outlined,
            title: t.reports_purchaseInvoices,
            subtitle: t.reports_recordsCount(count: s.purchaseCount),
            paisa: s.purchasesPaisa,
          ),
        ]),
      ],
    );
  }

  Future<_ReportResult> _partyLedger(
    ReportRepository reports,
    FragmentStrings t,
    String Function(DateTime) fmt, {
    required bool isCustomer,
  }) async {
    final (from, to) = _range();
    final statement = isCustomer
        ? await reports.customerLedger(_partyId!, from: from, to: to)
        : await reports.supplierLedger(_partyId!, from: from, to: to);
    return _ReportResult(
      kpis: [
        _Kpi(
            label: t.reports_openingBalance,
            paisa: statement.openingBalancePaisa),
        _Kpi(
            label: t.reports_closingBalance,
            paisa: statement.closingBalancePaisa),
      ],
      sections: [
        _Section(
          _partyName ?? '',
          [
            for (final line in statement.lines)
              _Line(
                icon: Icons.receipt_outlined,
                title: line.entry.description ?? line.entry.entryNo,
                subtitle: fmt(line.entry.date),
                paisa: line.entry.debitPaisa > 0
                    ? line.entry.debitPaisa
                    : line.entry.creditPaisa,
                isDebit: line.entry.debitPaisa > 0,
                runningBalancePaisa: line.runningBalancePaisa,
              ),
          ],
        ),
      ],
    );
  }

  Future<_ReportResult> _receivables(
      AccountingService accounting, FragmentStrings t) async {
    final list = await accounting.receivables();
    var total = 0;
    final lines = <_Line>[];
    for (final c in list) {
      total += c.balancePaisa;
      lines.add(_Line(
        icon: Icons.person_outline,
        title: c.name,
        subtitle: c.phone,
        paisa: c.balancePaisa,
        positive: false,
        copyText: _reminderText(t, c.name, c.balancePaisa),
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_receivables, paisa: total, positive: false)],
      sections: [_Section(t.reports_receivables, lines)],
    );
  }

  Future<_ReportResult> _payables(
      AccountingService accounting, FragmentStrings t) async {
    final list = await accounting.payables();
    var total = 0;
    final lines = <_Line>[];
    for (final s in list) {
      total += s.balancePaisa;
      lines.add(_Line(
        icon: Icons.person_outline,
        title: s.name,
        subtitle: s.phone,
        paisa: s.balancePaisa,
        positive: false,
        copyText: _reminderText(t, s.name, s.balancePaisa),
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_payables, paisa: total, positive: false)],
      sections: [_Section(t.reports_payables, lines)],
    );
  }

  String _reminderText(FragmentStrings t, String name, int balance) {
    final isUr = Localizations.localeOf(context).languageCode == 'ur';
    return isUr
        ? buildReminderUr(partyName: name, balancePaisa: balance)
        : buildReminderEn(partyName: name, balancePaisa: balance);
  }

  Future<_ReportResult> _sales(ReportRepository reports, FragmentStrings t,
      String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final totals = await reports.salesSummary(from, to);
    final salesRepo = await ref.read(salesRepositoryProvider.future);
    final invoices = await salesRepo.list(
      customerId: _partyId,
      from: from,
      to: to,
      limit: 100000,
    );
    final lines = <_Line>[];
    for (final inv in invoices) {
      lines.add(_Line(
        icon: Icons.point_of_sale_outlined,
        title: inv.invoiceNo,
        subtitle:
            '${await _customerName(inv.customerId)} · ${fmt(inv.date)} · ${_invoiceStatusLabel(t, inv.status)}',
        paisa: inv.totalPaisa,
        documentArgs: {
          'document': DocumentKeys.saleInvoice,
          'id': inv.id!,
        },
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_totalSales, paisa: totals.totalPaisa),
        _Kpi(label: t.reports_paid, paisa: totals.paidPaisa, positive: true),
        _Kpi(label: t.reports_due, paisa: totals.duePaisa, positive: false),
      ],
      sections: [_Section(t.reports_saleInvoices, lines)],
    );
  }

  Future<_ReportResult> _purchases(ReportRepository reports, FragmentStrings t,
      String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final totals = await reports.purchaseSummary(from, to);
    final purchaseRepo = await ref.read(purchaseRepositoryProvider.future);
    final invoices = await purchaseRepo.list(
      supplierId: _partyId,
      from: from,
      to: to,
      limit: 100000,
    );
    final lines = <_Line>[];
    for (final inv in invoices) {
      lines.add(_Line(
        icon: Icons.shopping_cart_outlined,
        title: inv.invoiceNo,
        subtitle:
            '${await _supplierName(inv.supplierId)} · ${fmt(inv.date)} · ${_invoiceStatusLabel(t, inv.status)}',
        paisa: inv.totalPaisa,
        documentArgs: {
          'document': DocumentKeys.purchaseVoucher,
          'id': inv.id!,
        },
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_totalPurchases, paisa: totals.totalPaisa),
        _Kpi(label: t.reports_paid, paisa: totals.paidPaisa, positive: true),
        _Kpi(label: t.reports_due, paisa: totals.duePaisa, positive: false),
      ],
      sections: [_Section(t.reports_purchaseInvoices, lines)],
    );
  }

  Future<_ReportResult> _payments(
    FragmentStrings t,
    String Function(DateTime) fmt, {
    required bool received,
  }) async {
    final (from, to) = _range();
    final paymentRepo = await ref.read(paymentRepositoryProvider.future);
    final all = await paymentRepo.list(
      partyType: received ? PartyType.customer : PartyType.supplier,
      partyId: _partyId,
      from: from,
      to: to,
      limit: 100000,
    );
    final payments = all
        .where((p) =>
            p.direction ==
            (received ? PaymentDirection.received : PaymentDirection.paid))
        .toList();
    var total = 0;
    final lines = <_Line>[];
    for (final p in payments) {
      total += p.amountPaisa;
      final partyName = received
          ? await _customerName(p.partyId)
          : await _supplierName(p.partyId);
      lines.add(_Line(
        icon: received
            ? Icons.arrow_circle_down_outlined
            : Icons.arrow_circle_up_outlined,
        title: partyName,
        subtitle:
            '${await _accountName(p.accountId)} · ${fmt(p.date)} · ${_methodLabel(t, p.method)}',
        paisa: p.amountPaisa,
        positive: received,
        documentArgs: {
          'document': received
              ? DocumentKeys.paymentReceipt
              : DocumentKeys.supplierPaymentVoucher,
          'id': p.id!,
        },
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(
          label: received ? t.reports_totalReceived : t.reports_totalPaid,
          paisa: total,
          positive: received,
        ),
      ],
      sections: [
        _Section(
          received ? t.reports_paymentsReceived : t.reports_paymentsMade,
          lines,
        ),
      ],
    );
  }

  String _methodLabel(FragmentStrings t, PaymentMethod m) =>
      m == PaymentMethod.cash ? t.reports_doc_cash : t.reports_doc_bank;

  Future<_ReportResult> _expenses(ReportRepository reports, FragmentStrings t,
      String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final byCategory = await reports.expensesByCategory(from, to);
    final expenseRepo = await ref.read(expenseRepositoryProvider.future);
    final entries = await expenseRepo.list(from: from, to: to, limit: 100000);
    final categories = await expenseRepo.getCategories(activeOnly: false);
    final catNames = {for (final c in categories) c.id!: c.name};
    var total = 0;
    final lines = <_Line>[];
    for (final e in entries) {
      total += e.amountPaisa;
      lines.add(_Line(
        icon: Icons.money_off_outlined,
        title: (e.description?.isNotEmpty ?? false)
            ? e.description!
            : (catNames[e.categoryId] ?? ''),
        subtitle: '${await _accountName(e.accountId)} · ${fmt(e.date)}',
        paisa: e.amountPaisa,
        positive: false,
        documentArgs: {
          'document': DocumentKeys.expenseVoucher,
          'id': e.id!,
        },
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_totalExpenses, paisa: total, positive: false)
      ],
      sections: [
        _Section(
          t.reports_expensesByCategory,
          [
            for (final c in byCategory)
              _Line(
                icon: Icons.category_outlined,
                title: c.categoryName,
                subtitle: t.reports_recordsCount(count: c.count),
                paisa: c.totalPaisa,
                positive: false,
              ),
          ],
        ),
        _Section(t.reports_expense, lines),
      ],
    );
  }

  Future<_ReportResult> _income(ReportRepository reports, FragmentStrings t,
      String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final total = await reports.otherIncomeTotal(from, to);
    final incomeRepo = await ref.read(incomeRepositoryProvider.future);
    final entries = await incomeRepo.list(from: from, to: to, limit: 100000);
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_totalIncome, paisa: total, positive: true)],
      sections: [
        _Section(
          t.reports_income,
          [
            for (final e in entries)
              _Line(
                icon: Icons.attach_money_outlined,
                title: (e.description?.isNotEmpty ?? false)
                    ? e.description!
                    : (e.category ?? ''),
                subtitle: '${await _accountName(e.accountId)} · ${fmt(e.date)}',
                paisa: e.amountPaisa,
                positive: true,
                documentArgs: {
                  'document': DocumentKeys.cashReceipt,
                  'id': e.id!,
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<_ReportResult> _cashbook(ReportRepository reports, FragmentStrings t,
      String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final statement = await reports.cashBook(_accountId!, from: from, to: to);
    final accountName = _accounts
        .where((a) => a.id == _accountId)
        .map((a) => a.name)
        .firstOrNull;
    return _ReportResult(
      kpis: [
        _Kpi(
            label: t.reports_openingBalance,
            paisa: statement.openingBalancePaisa),
        _Kpi(
            label: t.reports_closingBalance,
            paisa: statement.closingBalancePaisa),
      ],
      sections: [
        _Section(
          accountName ?? '',
          [
            for (final line in statement.lines)
              _Line(
                icon: Icons.receipt_outlined,
                title: line.entry.description ?? line.entry.entryNo,
                subtitle: fmt(line.entry.date),
                paisa: line.entry.debitPaisa > 0
                    ? line.entry.debitPaisa
                    : line.entry.creditPaisa,
                isDebit: line.entry.debitPaisa > 0,
                runningBalancePaisa: line.runningBalancePaisa,
              ),
          ],
        ),
      ],
    );
  }

  Future<_ReportResult> _cashBankBalances(
      AccountingService accounting, FragmentStrings t) async {
    final cashRepo = await ref.read(cashAccountRepositoryProvider.future);
    final accounts = await cashRepo.getAll();
    var total = 0;
    final lines = <_Line>[];
    for (final a in accounts) {
      final bal = await accounting.getAccountBalancePaisa(a.id!);
      total += bal;
      lines.add(_Line(
        icon: a.type == CashAccountType.bank
            ? Icons.account_balance_outlined
            : Icons.wallet_outlined,
        title: a.name,
        subtitle: a.type == CashAccountType.bank
            ? t.reports_doc_bank
            : t.reports_doc_cash,
        paisa: bal,
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_grandTotal, paisa: total)],
      sections: [_Section(t.reports_accounts, lines)],
    );
  }

  Future<_ReportResult> _inventoryValuation(
      ReportRepository reports, FragmentStrings t) async {
    final products = await reports.stockReport();
    final units = await ref.read(unitRepositoryProvider.future);
    final unitMap = {for (final u in await units.getAll()) u.id!: u.symbol};
    var total = 0;
    final lines = <_Line>[];
    for (final p in products) {
      final value = (p.stockQty * p.avgCostPaisa).round();
      total += value;
      lines.add(_Line(
        icon: Icons.inventory_2_outlined,
        title: p.name,
        subtitle:
            '${_fmtQty(p.stockQty)} ${unitMap[p.baseUnitId] ?? ''} · ${t.reports_avgCost} ${formatPkr(p.avgCostPaisa)}',
        paisa: value,
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_stockValue, paisa: total)],
      sections: [_Section(t.reports_inventoryValuation, lines)],
    );
  }

  Future<_ReportResult> _stockMovement(
      FragmentStrings t, String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final inventoryRepo = await ref.read(inventoryRepositoryProvider.future);
    final movements =
        await inventoryRepo.movementsForProduct(_productId!, limit: 10000);
    final inRange = movements
        .where((m) => !m.date.isBefore(from) && m.date.isBefore(to))
        .toList();
    double totalIn = 0, totalOut = 0;
    final lines = <_Line>[];
    for (final m in inRange) {
      if (m.qtyChangeBase >= 0) {
        totalIn += m.qtyChangeBase;
      } else {
        totalOut -= m.qtyChangeBase;
      }
      final symbol = await _unitSymbol(m.unitId);
      lines.add(_Line(
        icon: m.qtyChangeBase >= 0
            ? Icons.arrow_circle_down_outlined
            : Icons.arrow_circle_up_outlined,
        title: m.movementType,
        subtitle: fmt(m.date),
        trailingText:
            '${m.qtyChangeBase >= 0 ? '+' : ''}${_fmtQty(m.qtyChange)} $symbol'
                .trim(),
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: '${t.reports_quantity} (+)', text: _fmtQty(totalIn)),
        _Kpi(label: '${t.reports_quantity} (−)', text: _fmtQty(totalOut)),
      ],
      sections: [_Section(_productName ?? '', lines)],
    );
  }

  Future<_ReportResult> _lowStock(
      ReportRepository reports, FragmentStrings t) async {
    final products = await reports.lowStockReport();
    final units = await ref.read(unitRepositoryProvider.future);
    final unitMap = {for (final u in await units.getAll()) u.id!: u.symbol};
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_lowStock, text: '${products.length}'),
      ],
      sections: [
        _Section(
          t.reports_lowStock,
          [
            for (final p in products)
              _Line(
                icon: Icons.warning_amber_outlined,
                title: p.name,
                subtitle:
                    '${t.reports_onHand}: ${_fmtQty(p.stockQty)} ${unitMap[p.baseUnitId] ?? ''} · ${t.reports_reorderLevel}: ${_fmtQty(p.reorderLevelQty)}',
                positive: false,
              ),
          ],
        ),
      ],
    );
  }

  Future<_ReportResult> _production(
    FragmentStrings t,
    String Function(DateTime) fmt, {
    required bool yieldOnly,
  }) async {
    final (from, to) = _range();
    final productionRepo = await ref.read(productionRepositoryProvider.future);
    final batches =
        await productionRepo.list(from: from, to: to, limit: 100000);
    final withYield = batches.where((b) => b.yieldPct != null).toList();
    final lines = <_Line>[];
    for (final b in yieldOnly ? withYield : batches) {
      lines.add(_Line(
        icon: Icons.factory_outlined,
        title: b.batchNo,
        subtitle: fmt(b.date),
        trailingText:
            b.yieldPct == null ? '—' : '${b.yieldPct!.toStringAsFixed(1)}%',
        documentArgs: {
          'document': DocumentKeys.productionReport,
          'id': b.id!,
        },
      ));
    }
    final avgYield = withYield.isEmpty
        ? null
        : withYield.map((b) => b.yieldPct!).reduce((a, b) => a + b) /
            withYield.length;
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_batches, text: '${batches.length}'),
        if (avgYield != null)
          _Kpi(
              label: t.reports_avgYield,
              text: '${avgYield.toStringAsFixed(1)}%'),
      ],
      sections: [
        _Section(
          yieldOnly ? t.reports_yield : t.reports_production,
          lines,
        ),
      ],
    );
  }

  Future<_ReportResult> _salesReturns(
      FragmentStrings t, String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final returnRepo = await ref.read(returnRepositoryProvider.future);
    final returns = await returnRepo.listSalesReturns(
      customerId: _partyId,
      from: from,
      to: to,
      limit: 100000,
    );
    var total = 0;
    final lines = <_Line>[];
    for (final r in returns) {
      total += r.totalPaisa;
      lines.add(_Line(
        icon: Icons.assignment_return_outlined,
        title: r.returnNo,
        subtitle: '${await _customerName(r.customerId)} · ${fmt(r.date)}',
        paisa: r.totalPaisa,
        positive: false,
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_totalPaid, paisa: total, positive: false)],
      sections: [_Section(t.reports_salesReturns, lines)],
    );
  }

  Future<_ReportResult> _purchaseReturns(
      FragmentStrings t, String Function(DateTime) fmt) async {
    final (from, to) = _range();
    final returnRepo = await ref.read(returnRepositoryProvider.future);
    final returns = await returnRepo.listPurchaseReturns(
      supplierId: _partyId,
      from: from,
      to: to,
      limit: 100000,
    );
    var total = 0;
    final lines = <_Line>[];
    for (final r in returns) {
      total += r.totalPaisa;
      lines.add(_Line(
        icon: Icons.assignment_returned_outlined,
        title: r.returnNo,
        subtitle: '${await _supplierName(r.supplierId)} · ${fmt(r.date)}',
        paisa: r.totalPaisa,
        positive: false,
      ));
    }
    return _ReportResult(
      kpis: [_Kpi(label: t.reports_totalPaid, paisa: total, positive: false)],
      sections: [_Section(t.reports_purchaseReturns, lines)],
    );
  }

  Future<_ReportResult> _outstandingInvoices(
      FragmentStrings t, String Function(DateTime) fmt) async {
    final salesRepo = await ref.read(salesRepositoryProvider.future);
    final purchaseRepo = await ref.read(purchaseRepositoryProvider.future);
    final saleUnpaid =
        await salesRepo.list(status: InvoiceStatus.unpaid, limit: 100000);
    final salePartial =
        await salesRepo.list(status: InvoiceStatus.partial, limit: 100000);
    final purUnpaid =
        await purchaseRepo.list(status: InvoiceStatus.unpaid, limit: 100000);
    final purPartial =
        await purchaseRepo.list(status: InvoiceStatus.partial, limit: 100000);

    var saleDue = 0;
    final saleLines = <_Line>[];
    for (final inv in [...saleUnpaid, ...salePartial]) {
      final due = inv.totalPaisa - inv.paidPaisa;
      saleDue += due;
      saleLines.add(_Line(
        icon: Icons.receipt_long_outlined,
        title: inv.invoiceNo,
        subtitle:
            '${await _customerName(inv.customerId)} · ${fmt(inv.date)} · ${_invoiceStatusLabel(t, inv.status)}',
        paisa: due,
        positive: false,
        documentArgs: {'document': DocumentKeys.saleInvoice, 'id': inv.id!},
      ));
    }
    var purDue = 0;
    final purLines = <_Line>[];
    for (final inv in [...purUnpaid, ...purPartial]) {
      final due = inv.totalPaisa - inv.paidPaisa;
      purDue += due;
      purLines.add(_Line(
        icon: Icons.receipt_long_outlined,
        title: inv.invoiceNo,
        subtitle:
            '${await _supplierName(inv.supplierId)} · ${fmt(inv.date)} · ${_invoiceStatusLabel(t, inv.status)}',
        paisa: due,
        positive: false,
        documentArgs: {'document': DocumentKeys.purchaseVoucher, 'id': inv.id!},
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_receivables, paisa: saleDue, positive: false),
        _Kpi(label: t.reports_payables, paisa: purDue, positive: false),
      ],
      sections: [
        _Section(t.reports_saleInvoices, saleLines),
        _Section(t.reports_purchaseInvoices, purLines),
      ],
    );
  }

  Future<_ReportResult> _profitLoss(
      ReportRepository reports, FragmentStrings t) async {
    final (from, to) = _range();
    final pl = await reports.profitLoss(from, to);
    return _ReportResult(
      kpis: [
        _Kpi(
            label: t.reports_totalIncome,
            paisa: pl.incomePaisa,
            positive: true),
        _Kpi(
            label: t.reports_totalExpenses,
            paisa: pl.expensePaisa,
            positive: false),
        _Kpi(
          label: pl.netPaisa >= 0 ? t.reports_netProfit : t.reports_netLoss,
          paisa: pl.netPaisa,
          positive: pl.netPaisa >= 0,
        ),
      ],
      // P&L comes from the ledger, but without per-unit cost tracking the
      // "profit" mixes cash and accrual effects — label it estimated.
      note: t.reports_estimatedNote,
    );
  }

  Future<_ReportResult> _trialBalance(
      AccountingService accounting, FragmentStrings t) async {
    final customerRepo = await ref.read(customerRepositoryProvider.future);
    final supplierRepo = await ref.read(supplierRepositoryProvider.future);
    final cashRepo = await ref.read(cashAccountRepositoryProvider.future);

    var totalRecv = 0;
    final cLines = <_Line>[];
    for (final c in await customerRepo.search(query: '', limit: 100000)) {
      final bal = await accounting.getCustomerBalancePaisa(c.id!);
      if (bal == 0) continue;
      totalRecv += bal;
      cLines.add(_Line(
        icon: Icons.person_outline,
        title: c.name,
        paisa: bal,
        positive: bal < 0,
      ));
    }
    var totalPay = 0;
    final sLines = <_Line>[];
    for (final s in await supplierRepo.search(query: '', limit: 100000)) {
      final bal = await accounting.getSupplierBalancePaisa(s.id!);
      if (bal == 0) continue;
      totalPay += bal;
      sLines.add(_Line(
        icon: Icons.person_outline,
        title: s.name,
        paisa: bal,
        positive: bal < 0,
      ));
    }
    var totalCash = 0;
    final aLines = <_Line>[];
    for (final a in await cashRepo.getAll()) {
      final bal = await accounting.getAccountBalancePaisa(a.id!);
      totalCash += bal;
      aLines.add(_Line(
        icon: a.type == CashAccountType.bank
            ? Icons.account_balance_outlined
            : Icons.wallet_outlined,
        title: a.name,
        paisa: bal,
      ));
    }
    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_receivables, paisa: totalRecv, positive: false),
        _Kpi(label: t.reports_payables, paisa: totalPay, positive: false),
        _Kpi(label: t.reports_cashBankBalances, paisa: totalCash),
      ],
      sections: [
        _Section(t.reports_customers, cLines),
        _Section(t.reports_suppliers, sLines),
        _Section(t.reports_accounts, aLines),
      ],
    );
  }

  Future<_ReportResult> _daybook(
      FragmentStrings t, String Function(DateTime) fmt) async {
    final day = DateTime(_singleDate.year, _singleDate.month, _singleDate.day);
    final from = day;
    final to = day.add(const Duration(days: 1));

    final salesRepo = await ref.read(salesRepositoryProvider.future);
    final purchaseRepo = await ref.read(purchaseRepositoryProvider.future);
    final paymentRepo = await ref.read(paymentRepositoryProvider.future);
    final expenseRepo = await ref.read(expenseRepositoryProvider.future);
    final incomeRepo = await ref.read(incomeRepositoryProvider.future);
    final returnRepo = await ref.read(returnRepositoryProvider.future);
    final productionRepo = await ref.read(productionRepositoryProvider.future);

    final sales = await salesRepo.list(from: from, to: to, limit: 100000);
    final purchases =
        await purchaseRepo.list(from: from, to: to, limit: 100000);
    final payments = await paymentRepo.list(from: from, to: to, limit: 100000);
    final expenses = await expenseRepo.list(from: from, to: to, limit: 100000);
    final incomes = await incomeRepo.list(from: from, to: to, limit: 100000);
    final saleReturns =
        await returnRepo.listSalesReturns(from: from, to: to, limit: 100000);
    final purReturns =
        await returnRepo.listPurchaseReturns(from: from, to: to, limit: 100000);
    final batches =
        await productionRepo.list(from: from, to: to, limit: 100000);

    var salesTotal = 0, recvTotal = 0, paidTotal = 0, expTotal = 0;
    for (final s in sales) {
      salesTotal += s.totalPaisa;
    }
    for (final p in payments) {
      if (p.direction == PaymentDirection.received) {
        recvTotal += p.amountPaisa;
      } else {
        paidTotal += p.amountPaisa;
      }
    }
    for (final e in expenses) {
      expTotal += e.amountPaisa;
    }

    final sections = <_Section>[];
    if (sales.isNotEmpty) {
      sections.add(_Section(t.reports_sales, [
        for (final s in sales)
          _Line(
            icon: Icons.point_of_sale_outlined,
            title: s.invoiceNo,
            paisa: s.totalPaisa,
            documentArgs: {
              'document': DocumentKeys.saleInvoice,
              'id': s.id!,
            },
          ),
      ]));
    }
    if (purchases.isNotEmpty) {
      sections.add(_Section(t.reports_purchase, [
        for (final p in purchases)
          _Line(
            icon: Icons.shopping_cart_outlined,
            title: p.invoiceNo,
            paisa: p.totalPaisa,
            documentArgs: {
              'document': DocumentKeys.purchaseVoucher,
              'id': p.id!,
            },
          ),
      ]));
    }
    if (payments.isNotEmpty) {
      sections.add(_Section(t.reports_paymentsReceived, [
        for (final p in payments)
          _Line(
            icon: p.direction == PaymentDirection.received
                ? Icons.arrow_circle_down_outlined
                : Icons.arrow_circle_up_outlined,
            title: p.direction == PaymentDirection.received
                ? await _customerName(p.partyId)
                : await _supplierName(p.partyId),
            paisa: p.amountPaisa,
            positive: p.direction == PaymentDirection.received,
          ),
      ]));
    }
    if (expenses.isNotEmpty || incomes.isNotEmpty) {
      sections.add(_Section(t.reports_expense, [
        for (final e in expenses)
          _Line(
            icon: Icons.money_off_outlined,
            title: e.description ?? '',
            paisa: e.amountPaisa,
            positive: false,
          ),
        for (final i in incomes)
          _Line(
            icon: Icons.attach_money_outlined,
            title: i.description ?? '',
            paisa: i.amountPaisa,
            positive: true,
          ),
      ]));
    }
    if (saleReturns.isNotEmpty || purReturns.isNotEmpty) {
      sections.add(_Section(t.reports_salesReturns, [
        for (final r in saleReturns)
          _Line(
              icon: Icons.assignment_return_outlined,
              title: r.returnNo,
              paisa: r.totalPaisa,
              positive: false),
        for (final r in purReturns)
          _Line(
              icon: Icons.assignment_returned_outlined,
              title: r.returnNo,
              paisa: r.totalPaisa,
              positive: false),
      ]));
    }
    if (batches.isNotEmpty) {
      sections.add(_Section(t.reports_production, [
        for (final b in batches)
          _Line(
            icon: Icons.factory_outlined,
            title: b.batchNo,
            documentArgs: {
              'document': DocumentKeys.productionReport,
              'id': b.id!,
            },
          ),
      ]));
    }

    return _ReportResult(
      kpis: [
        _Kpi(label: t.reports_totalSales, paisa: salesTotal),
        _Kpi(label: t.reports_totalReceived, paisa: recvTotal, positive: true),
        _Kpi(label: t.reports_totalPaid, paisa: paidTotal, positive: false),
        _Kpi(label: t.reports_totalExpenses, paisa: expTotal, positive: false),
      ],
      sections: sections,
    );
  }

  // ------------------------------------------------------------------ picks

  Future<void> _pickParty() async {
    final isCustomer = widget.reportKey == ReportKeys.customerLedger ||
        {
          ReportKeys.sales,
          ReportKeys.paymentsReceived,
          ReportKeys.salesReturns,
        }.contains(widget.reportKey);
    final id = isCustomer
        ? await pickCustomerId(context)
        : await pickSupplierId(context);
    if (id == null || !mounted) return;
    final name = isCustomer ? await _customerName(id) : await _supplierName(id);
    setState(() {
      _partyId = id;
      _partyName = name;
    });
    _refresh();
  }

  Future<void> _pickCustomRange() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
      helpText: l10n.common_date,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = true;
      _customFrom = picked.start;
      _customTo = picked.end;
    });
    _refresh();
  }

  Future<void> _pickSingleDate() async {
    final t = FragmentStrings.of(context);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _singleDate,
      helpText: t.reports_pickDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _singleDate = picked);
    _refresh();
  }

  Future<void> _pickMonth() async {
    final t = FragmentStrings.of(context);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _monthDate,
      helpText: t.reports_pickMonth,
    );
    if (picked == null || !mounted) return;
    setState(() => _monthDate = picked);
    _refresh();
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(reportTitle(t, widget.reportKey))),
      body: Column(
        children: [
          _buildFilters(t),
          Expanded(
            child: FutureBuilder<_ReportResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  final e = snapshot.error;
                  final msg = e is AppException
                      ? errorText(context, e)
                      : AppLocalizations.of(context).error_generic;
                  return ErrorState(message: msg, onRetry: _refresh);
                }
                final result = snapshot.data!;
                if (result.prompt != null) {
                  return EmptyState(
                    icon: Icons.tune_outlined,
                    message: result.prompt,
                    actionLabel: result.promptActionLabel,
                    onAction: () async {
                      await result.onPromptAction?.call();
                      _refresh();
                    },
                  );
                }
                if (result.isEmpty) {
                  return EmptyState(
                    icon: Icons.inbox_outlined,
                    message: t.reports_noData,
                  );
                }
                return _buildResult(t, result);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(FragmentStrings t) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    String fmt(DateTime d) => DateFormat.yMMMd(localeCode).format(d);

    final rows = <Widget>[];

    if (_needsRange) {
      rows.add(DateFilterChips(
        selected: _customRange ? DateFilter.all : _dateFilter,
        onSelected: (f) {
          setState(() {
            _dateFilter = f;
            _customRange = false;
          });
          _refresh();
        },
      ));
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pickCustomRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _customRange && _customFrom != null && _customTo != null
                    ? '${fmt(_customFrom!)} – ${fmt(_customTo!)}'
                    : t.reports_customRange,
              ),
            ),
          ),
        ),
      );
    }

    if (_needsSingleDate) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pickSingleDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(fmt(_singleDate)),
            ),
          ),
        ),
      );
    }

    if (_needsMonth) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(DateFormat.yMMM(localeCode).format(_monthDate)),
            ),
          ),
        ),
      );
    }

    if (_needsCustomer || _needsSupplier) {
      final isCustomer = _needsCustomer;
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _partyName ??
                      (isCustomer
                          ? t.reports_selectCustomer
                          : t.reports_selectSupplier),
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _pickParty,
                child:
                    Text(_partyId == null ? l10n.common_add : t.reports_change),
              ),
              if (_partyId != null && !_partyRequired)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _partyId = null;
                      _partyName = null;
                    });
                    _refresh();
                  },
                  child: Text(t.reports_all),
                ),
            ],
          ),
        ),
      );
    }

    if (_needsProduct) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _productName ?? t.reports_selectProduct,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final id = await pickProductId(context);
                  if (id == null || !mounted) return;
                  final repo = await ref.read(productRepositoryProvider.future);
                  final p = await repo.getById(id);
                  setState(() {
                    _productId = id;
                    _productName = p?.name;
                  });
                  _refresh();
                },
                child: Text(
                    _productId == null ? l10n.common_add : t.reports_change),
              ),
            ],
          ),
        ),
      );
    }

    if (_needsAccount && _accounts.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<int>(
            initialValue: _accountId,
            decoration: InputDecoration(labelText: t.reports_selectAccount),
            items: [
              for (final a in _accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) {
              setState(() => _accountId = v);
              _refresh();
            },
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildResult(FragmentStrings t, _ReportResult result) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - 16 * 2 - 12) / 2;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (result.kpis.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final kpi in result.kpis)
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(kpi: kpi),
                  ),
              ],
            ),
          ),
        if (result.note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.note!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        for (final section in result.sections)
          if (section.lines.isNotEmpty) ...[
            SectionHeader(title: section.title),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < section.lines.length; i++) ...[
                    _buildLine(t, section.lines[i]),
                    if (i < section.lines.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildLine(FragmentStrings t, _Line line) {
    final copyButton = line.copyText == null
        ? null
        : IconButton(
            tooltip: t.reports_copyReminder,
            icon: const Icon(Icons.content_copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: line.copyText!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.reports_copied)),
              );
            },
          );

    void openDocument() {
      if (line.documentArgs != null) {
        Navigator.pushNamed(
          context,
          Routes.reportDetail,
          arguments: line.documentArgs,
        );
      }
    }

    if (line.isDebit != null) {
      return LedgerRow(
        title: line.title,
        dateLabel: line.subtitle ?? '',
        paisa: line.paisa ?? 0,
        isDebit: line.isDebit!,
        runningBalancePaisa: line.runningBalancePaisa,
        onTap: line.documentArgs == null ? null : openDocument,
      );
    }
    return TxnRow(
      icon: line.icon,
      title: line.title,
      subtitle: line.subtitle,
      paisa: line.paisa,
      positive: line.positive,
      onTap: line.documentArgs == null ? null : openDocument,
      trailing: copyButton ??
          (line.trailingText == null
              ? null
              : Text(
                  line.trailingText!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textDirection: TextDirection.ltr,
                )),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;

  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    if (kpi.paisa != null) {
      return SummaryCard(
        label: kpi.label,
        paisa: kpi.paisa!,
        icon: Icons.account_balance_wallet_outlined,
        positive: kpi.positive,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kpi.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              kpi.text ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// _DocumentView — branded document preview with Save PDF / Share / Print.
// ===========================================================================

class _DocumentView extends ConsumerStatefulWidget {
  final String documentType;
  final int id;
  final DateTime? from;
  final DateTime? to;

  const _DocumentView({
    required this.documentType,
    required this.id,
    this.from,
    this.to,
  });

  @override
  ConsumerState<_DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends ConsumerState<_DocumentView> {
  late Future<PdfDocumentData> _future;
  PdfDocumentData? _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PdfDocumentData> _load() async {
    final t = FragmentStrings.of(context);
    final business = ref.read(businessProfileProvider);
    final localeCode = Localizations.localeOf(context).languageCode;
    String fmt(DateTime d) => DateFormat.yMMMd(localeCode).format(d);
    final data = await buildDocumentData(
      ref: ref,
      documentType: widget.documentType,
      id: widget.id,
      t: t,
      business: business,
      formatDate: fmt,
      from: widget.from,
      to: widget.to,
    );
    // Rebuild so the action bar (which depends on _data) appears.
    if (mounted) setState(() => _data = data);
    return data;
  }

  void _refresh() {
    setState(() {
      _data = null;
      _future = _load();
    });
  }

  Future<Uint8List> _pdfBytes() {
    final l10n = AppLocalizations.of(context);
    return ref.read(pdfServiceProvider).buildPdf(document: _data!, l10n: l10n);
  }

  String get _fileName =>
      'namt-oil-mil-${widget.documentType}-${widget.id}.pdf';

  void _showError(Object e) {
    final msg = e is AppException
        ? errorText(context, e)
        : AppLocalizations.of(context).error_generic;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Save PDF to a user-visible location. Falls back to the share sheet on
  /// platforms without a save dialog. Confirms only after the call returns.
  Future<void> _savePdf() async {
    if (_busy || _data == null) return;
    final t = FragmentStrings.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await _pdfBytes();
      bool saveSupported = true;
      Uri? uri;
      try {
        uri = await FilePicker.saveFile(
          fileName: _fileName,
          bytes: bytes,
          mimeType: 'application/pdf',
          dialogTitle: t.reports_doc_savePdf,
        );
      } catch (_) {
        saveSupported = false;
      }
      if (!mounted) return;
      if (!saveSupported) {
        // No native save dialog: hand the file to the share sheet so the
        // user can still put it somewhere visible.
        await SharePlus.instance.share(ShareParams(
          text: _data!.title,
          files: [
            XFile.fromData(bytes, name: _fileName, mimeType: 'application/pdf'),
          ],
        ));
      } else if (uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.reports_doc_pdfSaved)),
        );
      }
      // uri == null && saveSupported -> user cancelled: stay silent.
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Share the PDF. The share sheet itself is the confirmation.
  Future<void> _sharePdf() async {
    if (_busy || _data == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _pdfBytes();
      await SharePlus.instance.share(ShareParams(
        text: _data!.title,
        files: [
          XFile.fromData(bytes, name: _fileName, mimeType: 'application/pdf'),
        ],
      ));
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Real print flow via the printing package. Nothing is confirmed until
  /// the platform print dialog call returns.
  Future<void> _printPdf() async {
    if (_busy || _data == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _pdfBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: _data!.title,
      );
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(documentTitle(t, widget.documentType))),
      body: FutureBuilder<PdfDocumentData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: _errorMessage(snapshot.error),
              onRetry: _refresh,
            );
          }
          return _buildPreview(t, snapshot.data!);
        },
      ),
      bottomNavigationBar: _data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _savePdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(t.reports_doc_savePdf),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _sharePdf,
                        icon: const Icon(Icons.share_outlined),
                        label: Text(t.reports_doc_share),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _printPdf,
                        icon: const Icon(Icons.print_outlined),
                        label: Text(t.reports_doc_print),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _errorMessage(Object? e) {
    if (e is AppException) return errorText(context, e);
    return AppLocalizations.of(context).error_generic;
  }

  Widget _buildPreview(FragmentStrings t, PdfDocumentData data) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business branding.
              Text(
                data.businessName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              if (data.businessAddress.isNotEmpty)
                Text(data.businessAddress,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
              if (data.businessPhone.isNotEmpty)
                Text(data.businessPhone,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
              const Divider(height: 28),
              Text(
                data.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              // Meta facts.
              for (final m in data.meta)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          m.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(m.value, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              // Line items.
              if (data.columns.isNotEmpty) ...[
                const SizedBox(height: 16),
                Table(
                  border: TableBorder.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  columnWidths: {
                    0: const FlexColumnWidth(4),
                    for (var i = 1; i < data.columns.length; i++)
                      i: const FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                      ),
                      children: [
                        for (final c in data.columns)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              c,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    for (final row in data.rows)
                      TableRow(
                        children: [
                          for (var i = 0; i < data.columns.length; i++)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                i < row.length ? row[i] : '',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
              // Totals.
              if (data.totals.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        for (final m in data.totals)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.label,
                                    style: theme.textTheme.bodyMedium),
                                AmountTextPreview(value: m.value),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              // Notes.
              if (data.notes != null && data.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (data.notesTitle != null)
                  Text(
                    data.notesTitle!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 4),
                Text(data.notes!, style: theme.textTheme.bodyMedium),
              ],
              if (data.footerNote != null) ...[
                const SizedBox(height: 16),
                Text(
                  data.footerNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Amount text inside the preview totals (values are pre-formatted strings).
class AmountTextPreview extends StatelessWidget {
  final String value;

  const AmountTextPreview({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontWeight: FontWeight.w700),
      textDirection: TextDirection.ltr,
    );
  }
}
