import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// One label/value pair (meta header rows and the totals block).
class PdfMetaRow {
  final String label;
  final String value;

  const PdfMetaRow(this.label, this.value);
}

/// Complete, UI-independent description of one printable business document.
///
/// Screens assemble this from repositories (via `document_data.dart`) and
/// hand it to [PdfService.buildPdf]. Keeping the PDF layer free of database
/// imports makes every document unit-testable and keeps the branding in one
/// place.
class PdfDocumentData {
  /// Localized document title, e.g. "Sale Invoice" / "فروخت انوائس".
  final String title;

  /// Business branding (from the settings business profile).
  final String businessName;
  final String businessAddress;
  final String businessPhone;

  /// Header facts: invoice no, date, bill-to, account, …
  final List<PdfMetaRow> meta;

  /// Column headers of the line-items table (empty = no table).
  final List<String> columns;

  /// One list per table row; each entry maps to [columns] by index.
  final List<List<String>> rows;

  /// Totals block (subtotal, discount, tax, total, paid, due, …).
  final List<PdfMetaRow> totals;

  /// Optional trailing notes section.
  final String? notesTitle;
  final String? notes;

  /// Small print at the bottom, e.g. "Generated on 14 Oct 2026".
  final String? footerNote;

  const PdfDocumentData({
    required this.title,
    required this.businessName,
    this.businessAddress = '',
    this.businessPhone = '',
    this.meta = const [],
    this.columns = const [],
    this.rows = const [],
    this.totals = const [],
    this.notesTitle,
    this.notes,
    this.footerNote,
  });
}

/// Builds branded PDF documents for invoices, vouchers, receipts,
/// statements and production reports.
///
/// API choice (documented per the module brief): a single typed entry
/// point — [buildPdf] — taking a [PdfDocumentData]. Screens build the data
/// object from repositories; the service only lays it out. There is no
/// `buildPdf(documentType, dataMap)` stringly-typed dispatcher on purpose:
/// typed data keeps every document compile-time checked.
///
/// HONEST LIMITATION — Urdu/Arabic script in PDFs: package:pdf applies the
/// correct RTL text direction, but its complex-script shaping for
/// Arabic-script (Urdu) is limited, and the default built-in fonts do not
/// cover the full Urdu glyph range. Urdu strings are therefore rendered
/// as-is with `TextDirection.rtl` — layout direction is correct, but
/// character joining/shaping may be imperfect in some viewers. The
/// user-facing README carries this note; fully shaped Urdu PDFs would need
/// an embedded Urdu-capable font (a future enhancement).
class PdfService {
  /// Renders [document] to PDF bytes, following the app locale from [l10n]
  /// (Urdu → RTL layout).
  Future<Uint8List> buildPdf({
    required PdfDocumentData document,
    required AppLocalizations l10n,
  }) async {
    final isRtl = l10n.localeName.toLowerCase().startsWith('ur');
    final direction = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document();
    final base = pw.TextStyle(fontSize: 10, color: PdfColors.grey800);
    final labelStyle =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final titleStyle =
        pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final docTitleStyle =
        pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold);

    pw.Widget metaTable(List<PdfMetaRow> rows) {
      return pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(5)
        },
        children: rows
            .map(
              (r) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(r.label,
                        style: labelStyle, textDirection: direction),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child:
                        pw.Text(r.value, style: base, textDirection: direction),
                  ),
                ],
              ),
            )
            .toList(),
      );
    }

    pw.Widget itemsTable() {
      final header = pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: document.columns
            .map(
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c, style: labelStyle, textDirection: direction),
              ),
            )
            .toList(),
      );
      final body = document.rows.map(
        (row) => pw.TableRow(
          children: List.generate(
            document.columns.length,
            (i) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                i < row.length ? row[i] : '',
                style: base,
                textDirection: direction,
              ),
            ),
          ),
        ),
      );
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: [header, ...body],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: direction,
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(document.businessName,
                style: titleStyle, textDirection: direction),
            if (document.businessAddress.isNotEmpty)
              pw.Text(document.businessAddress,
                  style: base, textDirection: direction),
            if (document.businessPhone.isNotEmpty)
              pw.Text(document.businessPhone,
                  style: base, textDirection: direction),
            pw.SizedBox(height: 12),
            pw.Text(document.title,
                style: docTitleStyle, textDirection: direction),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(document.footerNote ?? '',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    textDirection: direction),
                pw.Text('${context.pageNumber} / ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        build: (context) {
          final content = <pw.Widget>[];
          if (document.meta.isNotEmpty) {
            content.add(metaTable(document.meta));
            content.add(pw.SizedBox(height: 12));
          }
          if (document.columns.isNotEmpty) {
            content.add(itemsTable());
            content.add(pw.SizedBox(height: 12));
          }
          if (document.totals.isNotEmpty) {
            content.add(
              pw.Align(
                alignment:
                    isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 260,
                  child: metaTable(document.totals),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 12));
          }
          if (document.notes != null && document.notes!.isNotEmpty) {
            if (document.notesTitle != null) {
              content.add(pw.Text(document.notesTitle!,
                  style: labelStyle, textDirection: direction));
              content.add(pw.SizedBox(height: 4));
            }
            content.add(pw.Text(document.notes!,
                style: base, textDirection: direction));
          }
          return content;
        },
      ),
    );

    return doc.save();
  }
}

/// Riverpod access to [PdfService].
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
