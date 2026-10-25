import 'package:namt_oil_mil/utils/money.dart';

/// Payment-reminder message templates.
///
/// CONTRACT OWNED BY AGENT F (reports/PDF/backup module) — imported by
/// Agent C. Signatures are frozen:
///
/// ```dart
/// String buildReminderEn({required String partyName, required int balancePaisa});
/// String buildReminderUr({required String partyName, required int balancePaisa});
/// ```
///
/// Both builders take the party's display name and the outstanding balance
/// in paisa (> 0 means the party owes the business).
///
/// NOTE: these builders only *compose* the message text — nothing is sent
/// automatically. Actually sending via WhatsApp/SMS/share needs the user's
/// explicit action (and connectivity), which the calling screen handles.
String buildReminderEn({
  required String partyName,
  required int balancePaisa,
}) {
  final amount = formatPkr(balancePaisa);
  return 'Assalam-o-Alaikum $partyName,\n\n'
      'This is a gentle reminder from Namt Oil Mil that an amount of $amount '
      'is currently outstanding in your khata.\n\n'
      'Kindly arrange the payment at your earliest convenience. '
      'If you have already paid, please ignore this message.\n\n'
      'JazakAllah.';
}

String buildReminderUr({
  required String partyName,
  required int balancePaisa,
}) {
  final amount = formatPkr(balancePaisa);
  return 'السلام علیکم $partyName،\n\n'
      'نمت آئل مل کی طرف سے یہ ایک مؤدبانہ یاددہانی ہے کہ آپ کے کھاتے میں '
      'اس وقت $amount کی رقم بقایا ہے۔\n\n'
      'براہِ کرم جلد از جلد ادائیگی کا بندوبست فرمائیں۔ '
      'اگر آپ پہلے ہی ادائیگی کر چکے ہیں تو اس پیغام کو نظر انداز کر دیں۔\n\n'
      'جزاک اللہ۔';
}

/// Overdue-specific reminder with days-past-due. Available in English
/// and Urdu (script) — Roman Urdu was removed (user instruction
/// 2026-10-25: pure English + pure Urdu script only).
String buildOverdueReminderEn({
  required String partyName,
  required int balancePaisa,
  required int daysOverdue,
}) {
  final amount = formatPkr(balancePaisa);
  final dayWord = daysOverdue == 1 ? 'day' : 'days';
  return 'Assalam-o-Alaikum $partyName,\n\n'
      'This is a reminder from Namt Oil Mil that $amount has been overdue '
      'for $daysOverdue $dayWord.\n\n'
      'Kindly clear the dues as soon as possible to avoid any inconvenience. '
      'If already paid, please ignore this message.\n\n'
      'JazakAllah.';
}

String buildOverdueReminderUr({
  required String partyName,
  required int balancePaisa,
  required int daysOverdue,
}) {
  final amount = formatPkr(balancePaisa);
  return 'السلام علیکم $partyName،\n\n'
      'نمت آئل مل کی طرف سے یاددہانی ہے کہ $amount کی رقم $daysOverdue دن سے '
      'واجب الادا ہے۔\n\n'
      'براہِ کرم جلد از جلد بقایا جات ادا فرمائیں تاکہ کسی دقت سے بچا جا سکے۔ '
      'اگر ادائیگی ہو چکی ہے تو اس پیغام کو نظر انداز کر دیں۔\n\n'
      'جزاک اللہ۔';
}

/// Short one-line nudge for SMS (160-char friendly).
///
/// [script] is 'en' or 'ur'; a legacy 'roman' value falls back to the
/// Urdu-script text (Roman Urdu was removed — user instruction
/// 2026-10-25: English + Urdu script only).
String buildShortNudge({
  required int balancePaisa,
  String script = 'ur',
}) {
  final amount = formatPkr(balancePaisa);
  switch (script) {
    case 'en':
      return 'Namt Oil Mil: $amount is outstanding in your khata. Kindly pay soon. JazakAllah.';
    case 'ur':
    default:
      return 'نمت آئل مل: آپ کے ذمے $amount بقایا ہے۔ جلد ادائیگی فرمائیں۔ جزاک اللہ۔';
  }
}

/// One recent ledger line for the compact statement summary that rides
/// along with a reminder when the full PDF cannot be attached (SMS).
///
/// [debitPaisa] is the "Diye" side (goods/money given — the party owes
/// more), [creditPaisa] the "Liye" side (received — the party owes less),
/// matching the customer khata's DIYE/LIYE columns. [balanceAfterPaisa] is
/// the signed customer balance right after this entry (> 0 = party owes).
class StatementSummaryLine {
  final DateTime date;
  final String description;
  final int debitPaisa;
  final int creditPaisa;
  final int balanceAfterPaisa;

  const StatementSummaryLine({
    required this.date,
    required this.description,
    required this.debitPaisa,
    required this.creditPaisa,
    required this.balanceAfterPaisa,
  });
}

/// Compact plain-text ledger summary appended to an SMS reminder
/// (user-requested 2026-10-25: a reminder must carry the customer's ledger
/// with it — SMS cannot attach the PDF, so the SMS carries this summary
/// and the full statement PDF follows via the share sheet; WhatsApp
/// reminders attach the PDF directly).
///
/// Renders the most recent entries (oldest first) with running balances,
/// then the closing balance line. [script] is 'en' or 'ur'; a legacy
/// 'roman' value falls back to Urdu script (Roman Urdu was removed —
/// user instruction 2026-10-25).
String buildLedgerSummaryText({
  required List<StatementSummaryLine> lines,
  required int closingBalancePaisa,
  String script = 'ur',
}) {
  final (header, diyeLabel, liyeLabel, totalLabel) = switch (script) {
    'en' => ('Khata Summary — Namt Oil Mil', 'Given', 'Received', 'Total outstanding'),
    _ => ('کھاتہ خلاصہ — نمت آئل مل', 'دیے', 'لیے', 'کل بقایا'),
  };
  final buffer = StringBuffer()
    ..writeln()
    ..writeln('--- $header ---');
  for (final line in lines) {
    final d = line.date;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final amount = line.debitPaisa > 0
        ? '${formatPkr(line.debitPaisa)} ($diyeLabel)'
        : '${formatPkr(line.creditPaisa)} ($liyeLabel)';
    buffer.writeln(
        '$dateLabel ${line.description}: $amount — Bal ${formatPkr(line.balanceAfterPaisa)}');
  }
  buffer.write('$totalLabel: ${formatPkr(closingBalancePaisa)}');
  return buffer.toString();
}
