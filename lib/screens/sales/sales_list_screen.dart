import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/sales_invoice.dart' show InvoiceStatus;
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/sales/sale_form_screen.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_commons.dart';
import 'package:namt_oil_mil/screens/transactions/invoice_list.dart';

/// Sales invoice list (/sales). Owned by Agent D (Module D).
class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InvoiceListScreen(module: _SalesListModule(ref));
  }
}

class _SalesListModule extends InvoiceListModule {
  _SalesListModule(this.ref);
  final WidgetRef ref;

  @override
  String title(AppLocalizations l10n) => l10n.sales_title;

  @override
  String searchHint(AppLocalizations l10n) => l10n.sales_searchHint;

  @override
  String emptyTitle(AppLocalizations l10n) => l10n.sales_emptyTitle;

  @override
  String newLabel(AppLocalizations l10n) => l10n.sales_newSale;

  @override
  String statusLabel(AppLocalizations l10n, InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.draft => l10n.sales_statusDraft,
      InvoiceStatus.unpaid => l10n.sales_statusUnpaid,
      InvoiceStatus.partial => l10n.sales_statusPartial,
      InvoiceStatus.paid => l10n.sales_statusPaid,
      InvoiceStatus.returned => l10n.sales_statusReturned,
      InvoiceStatus.cancelled => l10n.sales_statusCancelled,
    };
  }

  @override
  Future<List<InvoiceRowData>> load({
    String? query,
    DateTime? from,
    DateTime? to,
    InvoiceStatus? status,
  }) async {
    final db = await ref.read(databaseProvider.future);
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('i.date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('i.date < ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (status != null) {
      where.add('i.status = ?');
      args.add(status.dbValue);
    }
    if (query != null && query.isNotEmpty) {
      where.add('(i.invoice_no LIKE ? OR c.name LIKE ?)');
      args.add('%$query%');
      args.add('%$query%');
    }
    final rows = await db.rawQuery(
      'SELECT i.id, i.invoice_no, i.date, i.status, i.total_paisa, '
      'i.paid_paisa, c.name AS customer_name '
      'FROM sales_invoices i '
      'LEFT JOIN customers c ON c.id = i.customer_id '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
      'ORDER BY i.date DESC, i.id DESC LIMIT 300',
      args,
    );
    return [
      for (final r in rows)
        InvoiceRowData(
          id: r['id'] as int,
          invoiceNo: r['invoice_no'] as String,
          partyName: (r['customer_name'] as String?) ?? '—',
          date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
          status: InvoiceStatus.fromDb(r['status'] as String?),
          totalPaisa: (r['total_paisa'] as num).toInt(),
          paidPaisa: (r['paid_paisa'] as num).toInt(),
        ),
    ];
  }

  @override
  void openNew(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SaleFormScreen()),
    );
  }

  @override
  void openDetail(BuildContext context, int id) {
    Navigator.of(context).pushNamed(Routes.saleDetail, arguments: id);
  }
}
