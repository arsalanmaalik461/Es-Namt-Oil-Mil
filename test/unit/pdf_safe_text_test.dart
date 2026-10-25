// Regression tests for PDF glyph safety (user report 2026-10-25: the
// shared Customer Statement PDF showed missing-glyph boxes for the
// period separator and the empty Debit/Credit cells).
//
// Byte-level probe evidence against package:pdf 3.13.1's built-in
// Helvetica: code points U+0000-U+00FF pass through as raw bytes
// (middle dot, multiplication sign, etc. render fine), but every
// tested character above that range whose WinAnsi byte would sit in
// 0x80-0x9F — en dash, em dash, curly quotes, ellipsis, bullet — plus
// the Unicode minus, arrows, check marks and the rupee sign is
// silently DROPPED from the content stream ("Unable to find a font
// to draw" in the package log). pdfSafeText maps those characters to
// ASCII equivalents before anything reaches the PDF.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations_en.dart';
import 'package:namt_oil_mil/services/pdf/pdf_service.dart';

String _inflateStreams(List<int> bytes) {
  final out = StringBuffer();
  var i = 0;
  while (true) {
    final s = _indexOf(bytes, 'stream'.codeUnits, i);
    if (s < 0) break;
    var start = s + 6;
    if (start < bytes.length && bytes[start] == 13) start++;
    if (start < bytes.length && bytes[start] == 10) start++;
    final e = _indexOf(bytes, 'endstream'.codeUnits, start);
    if (e < 0) break;
    var chunk = bytes.sublist(start, e);
    while (chunk.isNotEmpty && (chunk.last == 10 || chunk.last == 13)) {
      chunk = chunk.sublist(0, chunk.length - 1);
    }
    try {
      out.write(latin1Decode(ZLibDecoder().convert(chunk)));
      out.write('\n');
    } catch (_) {
      // Not a flate stream (e.g. an embedded font) — skip.
    }
    i = e + 9;
  }
  return out.toString();
}

String latin1Decode(List<int> bytes) =>
    String.fromCharCodes(bytes.map((b) => b & 0xFF));

int _indexOf(List<int> hay, List<int> needle, int from) {
  outer:
  for (var i = from; i + needle.length <= hay.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// Reconstructs the document's text from a content stream: the pdf
/// package emits one TJ op per word, so the literal strings are
/// collected in order and joined with spaces.
String _extractText(String content) {
  final words = <String>[];
  final re = RegExp(r'\(((?:\\.|[^\\()])*)\)\]?\s*TJ');
  for (final m in re.allMatches(content)) {
    words.add(m
        .group(1)!
        .replaceAll('\\(', '(')
        .replaceAll('\\)', ')')
        .replaceAll('\\\\', '\\'));
  }
  return words.join(' ');
}

/// Every character the built-in PDF fonts can actually draw: the
/// Latin-1 range (control chars excluded) — Arabic script is left
/// alone by design (documented Urdu limitation, see PdfService).
bool _isPdfSafe(String s) {
  for (final r in s.runes) {
    if (r < 0x20 && r != 0x0A) return false;
    if (r <= 0xFF) continue;
    if (r >= 0x0600 && r <= 0x06FF) continue;
    return false;
  }
  return true;
}

void main() {
  group('pdfSafeText', () {
    test('maps the characters that broke the statement PDF', () {
      // Period separator: en dash dropped by the built-in font.
      expect(pdfSafeText('Jan 1, 2000 \u2013 Dec 31, 2099'),
          'Jan 1, 2000 - Dec 31, 2099');
      // Empty Debit/Credit cells: em dash dropped.
      expect(pdfSafeText('\u2014'), '-');
      // Product labels and purchase descriptions used em dashes.
      expect(pdfSafeText('Sarson Oil \u2014 40 kg'), 'Sarson Oil - 40 kg');
      expect(pdfSafeText('Purchase: Sarson Seed x80 kg \u2014 payable'),
          'Purchase: Sarson Seed x80 kg - payable');
    });

    test('maps other dropped punctuation to ASCII equivalents', () {
      expect(pdfSafeText('it\u2019s'), "it's");
      expect(pdfSafeText('\u201Cquoted\u201D'), '"quoted"');
      expect(pdfSafeText('wait\u2026'), 'wait...');
      expect(pdfSafeText('a \u2022 b'), 'a \u00B7 b'); // bullet -> middle dot
      expect(pdfSafeText('5 \u2212 3'), '5 - 3'); // Unicode minus
      expect(pdfSafeText('go \u2192 there'), 'go -> there');
      expect(pdfSafeText('\u2265 10'), '>= 10');
      expect(pdfSafeText('\u20A8 500'), 'Rs 500');
      expect(pdfSafeText('a\u00A0b'), 'a b'); // NBSP dropped -> space
      expect(pdfSafeText('done \u2713'), 'done '); // check mark dropped
    });

    test('keeps characters the built-in fonts can draw', () {
      // Middle dot (date/time separator), multiplication, division,
      // Latin-1 letters all pass through byte-verified.
      expect(pdfSafeText('Oct 25, 2026 \u00B7 12:54 PM'),
          'Oct 25, 2026 \u00B7 12:54 PM');
      expect(pdfSafeText('40 \u00D7 2 \u00F7 4'), '40 \u00D7 2 \u00F7 4');
      expect(pdfSafeText('Rs -1,400.00'), 'Rs -1,400.00');
    });

    test('output never contains a character the fonts cannot draw', () {
      const messy =
          'Sale \u2014 \u201Cbest\u201D oil \u2026 \u2265 40kg \u2192 '
          '\u20A8 1,000 \u2713 \u{1F600}';
      expect(_isPdfSafe(pdfSafeText(messy)), isTrue);
    });
  });

  group('statement-shaped document', () {
    test('renders with the fixed strings present in the content stream',
        () async {
      // Mirrors what document_data.dart now emits for a statement:
      // period joined with "to", empty cells "-", date-time with the
      // (safe) middle dot, and a purchase description that still
      // arrives with an em dash from the accounting layer.
      final doc = PdfDocumentData(
        title: 'Customer Statement',
        businessName: 'Namt Oil Mil',
        meta: const [
          PdfMetaRow('Customer', 'arslan'),
          PdfMetaRow('Period', 'Jan 1, 2000 to Dec 31, 2099'),
        ],
        columns: const ['Date', 'Description', 'Debit', 'Credit', 'Balance'],
        rows: const [
          [
            'Oct 25, 2026 \u00B7 12:54 PM',
            'Payment received from arslan',
            '-',
            'Rs 1,600.00',
            'Rs -1,600.00'
          ],
          [
            'Oct 25, 2026 \u00B7 12:54 PM',
            'Purchase: Sarson Seed x80 kg \u2014 payable to arslan',
            'Rs 200.00',
            '-',
            'Rs -1,400.00'
          ],
        ],
        totals: const [
          PdfMetaRow('Opening balance', 'Rs 0.00'),
          PdfMetaRow('Closing balance', 'Rs -1,400.00'),
        ],
        footerNote: 'Generated on Oct 25, 2026',
      );
      final bytes = await PdfService()
          .buildPdf(document: doc, l10n: AppLocalizationsEn());
      expect(bytes.length, greaterThan(1000));
      final text = _extractText(_inflateStreams(bytes));
      expect(text, contains('Jan 1, 2000 to Dec 31, 2099'));
      expect(text, contains('Rs -1,400.00'));
      expect(text, contains('Closing balance'));
      // The em dash from the accounting description was sanitised to
      // an ASCII hyphen instead of being dropped (broken glyph), and
      // the date/time separator middle dot survives.
      expect(text, contains('kg - payable to arslan'));
      expect(text, contains('Oct 25, 2026 \u00B7 12:54 PM'));
      expect(text, isNot(contains('\u2014')));
      expect(text, isNot(contains('\u2013')));
    });
  });
}
