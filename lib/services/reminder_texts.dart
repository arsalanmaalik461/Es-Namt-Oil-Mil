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

/// Roman-Urdu reminder (for users who prefer Latin script).
///
/// New in v2 — does not affect the frozen EN/UR builders above.
String buildReminderRomanUrdu({
  required String partyName,
  required int balancePaisa,
}) {
  final amount = formatPkr(balancePaisa);
  return 'Assalam-o-Alaikum $partyName,\n\n'
      'Namt Oil Mil ki taraf se ye ek adabana yaad-dahani hai ke aap ke '
      'khaate mein is waqt $amount ki raqam baqaya hai.\n\n'
      'Barah-e-karam jald az jald adaigi ka bandobast farmayein. '
      'Agar aap pehle hi adaigi kar chuke hain to is paigham ko nazar-andaz kar dein.\n\n'
      'JazakAllah.';
}

/// Overdue-specific reminder with days-past-due. Available in all 3 scripts.
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

String buildOverdueReminderRomanUrdu({
  required String partyName,
  required int balancePaisa,
  required int daysOverdue,
}) {
  final amount = formatPkr(balancePaisa);
  return 'Assalam-o-Alaikum $partyName,\n\n'
      'Namt Oil Mil ki taraf se yaad-dahani hai ke $amount ki raqam '
      '$daysOverdue din se wajib-ul-ada hai.\n\n'
      'Barah-e-karam jald az jald baqaya-jaat ada farmayein taake kisi '
      'diqqat se bacha ja sake. Agar adaigi ho chuki hai to is paigham ko '
      'nazar-andaz kar dein.\n\n'
      'JazakAllah.';
}

/// Short one-line nudge for SMS (160-char friendly).
String buildShortNudge({
  required int balancePaisa,
  String script = 'roman',
}) {
  final amount = formatPkr(balancePaisa);
  switch (script) {
    case 'ur':
      return 'نمت آئل مل: آپ کے ذمے $amount بقایا ہے۔ جلد ادائیگی فرمائیں۔ جزاک اللہ۔';
    case 'en':
      return 'Namt Oil Mil: $amount is outstanding in your khata. Kindly pay soon. JazakAllah.';
    case 'roman':
    default:
      return 'Namt Oil Mil: Aap ke zimme $amount baqaya hai. Jald adaigi farmayein. JazakAllah.';
  }
}
