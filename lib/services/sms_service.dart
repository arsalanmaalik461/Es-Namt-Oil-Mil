import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:namt_oil_mil/core/app_exception.dart';

/// Sends SMS payment reminders to customers.
///
/// Two paths:
/// * [sendDirect] — sends via Android's SmsManager through a platform
///   channel (`namt_oil_mil/sms`). Needs SEND_SMS permission. Works without
///   leaving the app.
/// * [openSmsApp] — opens the phone's SMS app with number + message
///   prefilled via `sms:` URI. No permission needed. Always available.
///
/// The caller builds the message text with the builders in
/// `reminder_texts.dart` (EN/UR) and lets the user edit before
/// sending.
///
/// LEDGER PDF (user-requested 2026-10-25): a reminder must carry the
/// customer's ledger with it. A plain SMS cannot attach a file, so the
/// SMS text includes the compact ledger summary
/// (ReminderService.smsTextWithLedgerSummary) and the full statement PDF
/// is shared right after via [shareStatementPdf] (system share sheet).
class SmsService {
  SmsService._();
  static const MethodChannel _channel = MethodChannel('namt_oil_mil/sms');

  /// True when the native direct-send channel is available on this device.
  static Future<bool> canSendDirect() async {
    try {
      final ok = await _channel.invokeMethod<bool>('canSendSms');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Sends [message] to [phoneNumber] directly via SmsManager.
  ///
  /// Returns true when the OS accepted the send request. Throws
  /// [SmsException] with a localisable error key on failure (e.g. permission
  /// denied, no SIM).
  static Future<bool> sendDirect({
    required String phoneNumber,
    required String message,
  }) async {
    final number = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (number.isEmpty) {
      throw const SmsException('error.smsNoNumber');
    }
    if (message.trim().isEmpty) {
      throw const SmsException('error.smsEmptyMessage');
    }
    try {
      final sent =
          await _channel.invokeMethod<bool>('sendSms', <String, Object>{
        'number': number,
        'message': message,
      });
      return sent ?? false;
    } on PlatformException catch (e) {
      throw _friendlyError(e.code, e.message);
    } on MissingPluginException {
      throw const SmsException('error.smsChannelMissing');
    }
  }

  /// Opens the phone's SMS app with [phoneNumber] and [message] prefilled.
  /// The user taps send themselves. Works on every device, no permission.
  static Future<bool> openSmsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final number = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: <String, String>{'body': message},
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Shares the customer's full ledger statement PDF through the system
  /// share sheet — the fallback that lets an SMS reminder still deliver
  /// the PDF (user-requested 2026-10-25). Send the SMS first (its text
  /// carries the compact ledger summary), then call this so the user can
  /// forward the complete statement PDF to the same customer via
  /// WhatsApp/share target of their choice.
  ///
  /// Returns the share result status.
  static Future<ShareResultStatus> shareStatementPdf({
    required Uint8List pdfBytes,
    required String fileName,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final file = File(p.join(dir.path, safeName));
    await file.writeAsBytes(pdfBytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf', name: safeName)],
        text: text,
      ),
    );
    return result.status;
  }

  /// Maps a platform failure code to a localisable [SmsException]
  /// (`error.*` key, resolved by the UI via `errorText`).
  static SmsException _friendlyError(String code, String? details) {
    switch (code) {
      case 'PERMISSION_DENIED':
        return const SmsException('error.smsPermissionDenied');
      case 'NO_SMS_MANAGER':
        return const SmsException('error.smsNotAvailable');
      case 'SEND_FAILED':
        return SmsException(
            'error.smsSendFailed', {'details': (details ?? '').trim()});
      default:
        return details?.isNotEmpty == true
            ? SmsException('error.smsSendFailed', {'details': details!.trim()})
            : const SmsException('error.smsGeneric');
    }
  }
}

/// Localisable SMS failure. Carries an [AppException.messageKey]
/// (`error.*`); the UI translates it via `errorText` — never show it raw.
class SmsException extends AppException {
  const SmsException(super.messageKey, [super.params]);
}
