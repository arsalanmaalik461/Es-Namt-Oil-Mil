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
