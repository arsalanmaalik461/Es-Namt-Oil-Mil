import 'package:sqflite/sqflite.dart';

import 'package:namt_oil_mil/models/inventory_movement.dart'
    show ReferenceTypes;
import 'package:namt_oil_mil/models/ledger_entry.dart';
import 'package:namt_oil_mil/repositories/cash_account_repository.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/repositories/purchase_repository.dart';
import 'package:namt_oil_mil/repositories/sales_repository.dart';
import 'package:namt_oil_mil/repositories/supplier_repository.dart';

// ===========================================================================
// Read-only journal query for the Transaction Center (Agent D).
//
// Groups raw ledger entries by journal_key so each business transaction
// (sale, payment, expense, ...) renders as ONE row. No balance math happens
// here — amounts shown are the journal's own debit totals straight from the
// ledger. Name/doc-no resolution is read-only via the CRUD repositories.
// ===========================================================================

/// One business transaction: all ledger entries sharing a journal key.
class JournalGroup {
  final String journalKey;
  final DateTime date;
  final String referenceType;
  final String description;
  final String entryNo;
  final List<LedgerEntry> entries;
  final int totalPaisa;
  final bool isReversal;
  final bool isReversed;
  final String? referenceLabel;
  final String? partyName;
  final Map<String, String> accountNames;

  /// For payments: true = money received, false = money paid, null = n/a.
  final bool? moneyIn;

  const JournalGroup({
    required this.journalKey,
    required this.date,
    required this.referenceType,
    required this.description,
    required this.entryNo,
    required this.entries,
    required this.totalPaisa,
    required this.isReversal,
    required this.isReversed,
    this.referenceLabel,
    this.partyName,
    this.accountNames = const {},
    this.moneyIn,
  });
}

/// Category filter for the transaction center, derived from referenceType.
enum JournalFilter {
  all,
  sale,
  purchase,
  paymentReceived,
  paymentPaid,
  expense,
  income,
  transfer,
  adjustment,
  ret,
}

extension JournalFilterMatch on JournalFilter {
  bool matches(JournalGroup g) {
    switch (this) {
      case JournalFilter.all:
        return true;
      case JournalFilter.sale:
        return g.referenceType == ReferenceTypes.sale;
      case JournalFilter.purchase:
        return g.referenceType == ReferenceTypes.purchase;
      case JournalFilter.paymentReceived:
        return g.referenceType == ReferenceTypes.payment && g.moneyIn == true;
      case JournalFilter.paymentPaid:
        return g.referenceType == ReferenceTypes.payment && g.moneyIn == false;
      case JournalFilter.expense:
        return g.referenceType == ReferenceTypes.expense;
      case JournalFilter.income:
        return g.referenceType == ReferenceTypes.income;
      case JournalFilter.transfer:
        return g.referenceType == ReferenceTypes.transfer;
      case JournalFilter.adjustment:
        return g.referenceType == ReferenceTypes.adjustment ||
            g.referenceType == ReferenceTypes.production;
      case JournalFilter.ret:
        return g.referenceType == ReferenceTypes.salesReturn ||
            g.referenceType == ReferenceTypes.purchaseReturn;
    }
  }
}

/// Loads the most recent journal groups in [from]..[to) (to exclusive).
Future<List<JournalGroup>> fetchJournalGroups(
  DatabaseExecutor db, {
  DateTime? from,
  DateTime? to,
  int limit = 250,
}) async {
  final where = <String>[];
  final args = <Object?>[];
  if (from != null) {
    where.add('date >= ?');
    args.add(from.millisecondsSinceEpoch);
  }
  if (to != null) {
    where.add('date < ?');
    args.add(to.millisecondsSinceEpoch);
  }
  final rows = await db.query(
    'ledger_entries',
    where: where.isEmpty ? null : where.join(' AND '),
    whereArgs: args.isEmpty ? null : args,
    orderBy: 'date DESC, id DESC',
    limit: limit,
  );
  final entries = rows.map(LedgerEntry.fromMap).toList();

  final grouped = <String, List<LedgerEntry>>{};
  for (final e in entries) {
    grouped.putIfAbsent(e.journalKey, () => <LedgerEntry>[]).add(e);
  }

  final sales = SalesRepository(db);
  final purchases = PurchaseRepository(db);
  final customers = CustomerRepository(db);
  final suppliers = SupplierRepository(db);
  final accounts = CashAccountRepository(db);

  final groups = <JournalGroup>[];
  for (final kv in grouped.entries) {
    final list = kv.value..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final first = list.first;
    final total = list.fold<int>(0, (s, e) => s + e.debitPaisa);
    final isReversal = list.any((e) => e.reversedById != null);

    bool? moneyIn;
    if (first.referenceType == ReferenceTypes.payment) {
      final hasSupplier =
          list.any((e) => e.accountType == AccountType.supplier);
      final hasCustomer =
          list.any((e) => e.accountType == AccountType.customer);
      if (hasSupplier) {
        moneyIn = false;
      } else if (hasCustomer) {
        moneyIn = true;
      }
    }

    String? referenceLabel;
    final refId = first.referenceId;
    if (refId != null) {
      referenceLabel = switch (first.referenceType) {
        ReferenceTypes.sale => (await sales.getById(refId))?.invoiceNo,
        ReferenceTypes.purchase => (await purchases.getById(refId))?.invoiceNo,
        ReferenceTypes.payment => 'PMT-$refId',
        ReferenceTypes.salesReturn => (await _salesReturnNo(db, refId)),
        ReferenceTypes.purchaseReturn => (await _purchaseReturnNo(db, refId)),
        _ => null,
      };
    }

    String? partyName;
    final accountNames = <String, String>{};
    for (final e in list) {
      final key = '${e.accountType.dbValue}:${e.accountId}';
      if (accountNames.containsKey(key)) continue;
      final name = switch (e.accountType) {
        AccountType.customer => (await customers.getById(e.accountId))?.name,
        AccountType.supplier => (await suppliers.getById(e.accountId))?.name,
        AccountType.cash ||
        AccountType.bank =>
          (await accounts.getById(e.accountId))?.name,
        _ => null,
      };
      if (name != null) {
        accountNames[key] = name;
        partyName ??= (e.accountType == AccountType.customer ||
                e.accountType == AccountType.supplier)
            ? name
            : partyName;
      }
    }

    groups.add(JournalGroup(
      journalKey: kv.key,
      date: first.date,
      referenceType: first.referenceType ?? '',
      description: first.description ?? '',
      entryNo: first.entryNo,
      entries: list,
      totalPaisa: total,
      isReversal: isReversal,
      isReversed: false, // filled in below
      referenceLabel: referenceLabel,
      partyName: partyName,
      accountNames: accountNames,
      moneyIn: moneyIn,
    ));
  }

  // Mark journals that were later reversed.
  final allIds = entries.map((e) => e.id).whereType<int>().toList();
  final reversedTargets = <int>{};
  for (var i = 0; i < allIds.length; i += 500) {
    final chunk = allIds.sublist(i, (i + 500).clamp(0, allIds.length));
    final placeholders = List.filled(chunk.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT DISTINCT reversed_by_id AS rid FROM ledger_entries '
      'WHERE reversed_by_id IN ($placeholders)',
      chunk,
    );
    for (final r in rows) {
      final rid = r['rid'] as int?;
      if (rid != null) reversedTargets.add(rid);
    }
  }

  return groups
      .map(
        (g) => JournalGroup(
          journalKey: g.journalKey,
          date: g.date,
          referenceType: g.referenceType,
          description: g.description,
          entryNo: g.entryNo,
          entries: g.entries,
          totalPaisa: g.totalPaisa,
          isReversal: g.isReversal,
          isReversed: g.entries.any((e) => reversedTargets.contains(e.id)),
          referenceLabel: g.referenceLabel,
          partyName: g.partyName,
          accountNames: g.accountNames,
          moneyIn: g.moneyIn,
        ),
      )
      .toList();
}

Future<String?> _salesReturnNo(DatabaseExecutor db, int id) async {
  final rows = await db.query('sales_returns',
      columns: ['return_no'], where: 'id = ?', whereArgs: [id], limit: 1);
  return rows.isEmpty ? null : rows.first['return_no'] as String?;
}

Future<String?> _purchaseReturnNo(DatabaseExecutor db, int id) async {
  final rows = await db.query('purchase_returns',
      columns: ['return_no'], where: 'id = ?', whereArgs: [id], limit: 1);
  return rows.isEmpty ? null : rows.first['return_no'] as String?;
}
