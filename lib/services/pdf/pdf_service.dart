import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Makes [input] safe to render with package:pdf's built-in fonts
/// (Helvetica, WinAnsi-flavoured).
///
/// EMPIRICAL BASIS (byte-level probe against pdf 3.13.1, 2026-10-25):
/// the built-in font's glyph map only passes through code points
/// U+0000–U+00FF as raw bytes (e.g. · U+00B7, × U+00D7, ÷ U+00F7 all
/// survive). Everything else is silently DROPPED from the content
/// stream — the package logs "Unable to find a font to draw …" and
/// viewers show a missing-glyph box. Verified dropped: – U+2013,
/// — U+2014, − U+2212, ' ' U+2018/2019, " " U+201C/201D, … U+2026,
/// • U+2022, → U+2192, ✓ U+2713, ≥ U+2265, ₨ U+20A8, NBSP U+00A0.
/// Those characters are mapped to ASCII equivalents below; any other
/// out-of-range symbol (emoji, CJK, …) is dropped rather than shown
/// as a broken glyph. Arabic-script code points are left untouched:
/// Urdu documents are a documented limitation of the built-in fonts
/// (see [PdfService]) and stripping them would blank Urdu PDFs.
String pdfSafeText(String input) {
  final buf = StringBuffer();
  for (final rune in input.runes) {
    switch (rune) {
      case 0x2013: // – en dash
      case 0x2014: // — em dash
      case 0x2212: // − minus sign
        buf.write('-');
        continue;
      case 0x2018: // '
      case 0x2019: // '
        buf.write("'");
        continue;
      case 0x201C: // "
      case 0x201D: // "
        buf.write('"');
        continue;
      case 0x2026: // …
        buf.write('...');
        continue;
      case 0x2022: // • bullet -> middle dot (U+00B7 renders fine)
        buf.write('\u00B7');
        continue;
      case 0x2192: // →
        buf.write('->');
        continue;
      case 0x2265: // ≥
        buf.write('>=');
        continue;
      case 0x2264: // ≤
        buf.write('<=');
        continue;
      case 0x20A8: // ₨
        buf.write('Rs');
        continue;
      case 0x00A0: // non-breaking space
        buf.write(' ');
        continue;
    }
    if (rune < 0x20 && rune != 0x0A) continue; // strip control chars
    if (rune <= 0xFF) {
      buf.writeCharCode(rune); // Latin-1 range renders as-is
      continue;
    }
    if ((rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
        (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
        (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation-A
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      // Arabic Presentation-B
      buf.writeCharCode(rune);
      continue;
    }
    // Anything else has no glyph in the built-in fonts — drop it.
  }
  return buf.toString();
}

/// True when [v] looks like a formatted money cell ("Rs 1,600.00",
/// "Rs -1,400.00" or the empty-cell dash) — used to give amount
/// columns narrower flex and right alignment in the items table.
bool _isPdfAmountCell(String v) {
  final s = v.trim();
  return s == '-' ||
      RegExp(r'^-?Rs\s?-?[\d,]+(\.\d{1,2})?$').hasMatch(s);
}

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

    // Every string that reaches the page passes through pdfSafeText so
    // the built-in fonts never meet a glyph they cannot draw (broken
    // boxes in shared PDFs — user report 2026-10-25).
    String s(String v) => pdfSafeText(v);
    PdfMetaRow sr(PdfMetaRow r) => PdfMetaRow(s(r.label), s(r.value));
    final businessName = s(document.businessName);
    final businessAddress = s(document.businessAddress);
    final businessPhone = s(document.businessPhone);
    final title = s(document.title);
    final meta = document.meta.map(sr).toList();
    final columns = document.columns.map(s).toList();
    final rows = document.rows
        .map((r) => r.map(s).toList())
        .toList();
    final totals = document.totals.map(sr).toList();
    final notesTitle =
        document.notesTitle == null ? null : s(document.notesTitle!);
    final notes = document.notes == null ? null : s(document.notes!);
    final footerNote =
        document.footerNote == null ? null : s(document.footerNote!);

    // Brand emerald (matches the app theme's emeraldDark 0xFF0A4F37).
    const brand = PdfColor.fromInt(0xff0a4f37);

    final doc = pw.Document();
    final base = pw.TextStyle(fontSize: 10, color: PdfColors.grey800);
    final labelStyle =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final titleStyle =
        pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final docTitleStyle = pw.TextStyle(
        fontSize: 15, fontWeight: pw.FontWeight.bold, color: brand);
    final amountEnd =
        isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;
    final textStart =
        isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;

    pw.Widget metaTable(List<PdfMetaRow> metaRows) {
      return pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(5)
        },
        children: metaRows
            .map(
              (r) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Text(r.label,
                        style: labelStyle, textDirection: direction),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child:
                        pw.Text(r.value, style: base, textDirection: direction),
                  ),
                ],
              ),
            )
            .toList(),
      );
    }

    /// Totals block: rule on top, bold right-aligned values — reads as
    /// one tidy summary instead of loose meta rows.
    pw.Widget totalsTable(List<PdfMetaRow> totalRows) {
      return pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
          ),
        ),
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2)
          },
          children: totalRows
              .map(
                (r) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(r.label,
                          style: labelStyle, textDirection: direction),
                    ),
                    pw.Container(
                      alignment: amountEnd,
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(r.value,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                          textDirection: direction),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      );
    }

    pw.Widget itemsTable() {
      // Column plan: amount columns (every non-empty cell money-like)
      // are narrow + right-aligned; the first text column is medium;
      // a description-like text column gets the most room.
      final amountCol = List<bool>.generate(columns.length, (i) {
        if (rows.isEmpty) return false;
        var saw = false;
        for (final r in rows) {
          final v = (i < r.length ? r[i] : '').trim();
          if (v.isEmpty) continue;
          saw = true;
          if (!_isPdfAmountCell(v)) return false;
        }
        return saw;
      });
      final textCount = amountCol.where((a) => !a).length;
      final widths = <int, pw.TableColumnWidth>{
        for (var i = 0; i < columns.length; i++)
          i: pw.FlexColumnWidth(amountCol[i]
              ? 1.5
              : (textCount == 1 ? 4 : (i == 0 ? 2.2 : 3.2))),
      };

      pw.Widget cell(String text,
          {required bool header, required bool amount}) {
        return pw.Container(
          alignment: amount ? amountEnd : textStart,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            style: header
                ? pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)
                : base,
            textDirection: direction,
          ),
        );
      }

      final header = pw.TableRow(
        decoration: const pw.BoxDecoration(color: brand),
        children: [
          for (var i = 0; i < columns.length; i++)
            cell(columns[i], header: true, amount: amountCol[i]),
        ],
      );
      final body = <pw.TableRow>[
        for (var ri = 0; ri < rows.length; ri++)
          pw.TableRow(
            decoration: ri.isOdd
                ? const pw.BoxDecoration(color: PdfColors.grey100)
                : null,
            children: List.generate(
              columns.length,
              (i) => cell(i < rows[ri].length ? rows[ri][i] : '',
                  header: false, amount: amountCol[i]),
            ),
          ),
      ];
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: widths,
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
            pw.Text(businessName,
                style: titleStyle, textDirection: direction),
            if (businessAddress.isNotEmpty)
              pw.Text(businessAddress,
                  style: base, textDirection: direction),
            if (businessPhone.isNotEmpty)
              pw.Text(businessPhone, style: base, textDirection: direction),
            pw.SizedBox(height: 12),
            pw.Text(title, style: docTitleStyle, textDirection: direction),
            pw.Divider(thickness: 1.5, color: brand),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(footerNote ?? '',
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
          if (meta.isNotEmpty) {
            content.add(metaTable(meta));
            content.add(pw.SizedBox(height: 12));
          }
          if (columns.isNotEmpty) {
            content.add(itemsTable());
            content.add(pw.SizedBox(height: 12));
          }
          if (totals.isNotEmpty) {
            content.add(
              pw.Align(
                alignment:
                    isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 260,
                  child: totalsTable(totals),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 12));
          }
          if (notes != null && notes.isNotEmpty) {
            if (notesTitle != null) {
              content.add(pw.Text(notesTitle,
                  style: labelStyle, textDirection: direction));
              content.add(pw.SizedBox(height: 4));
            }
            content.add(pw.Text(notes, style: base, textDirection: direction));
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
