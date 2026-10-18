import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// `reminder_texts.dart` (EN/UR/Roman-Urdu) and lets the user edit before
/// sending.
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
  /// [SmsException] with a user-readable reason on failure (e.g. permission
  /// denied, no SIM).
  static Future<bool> sendDirect({
    required String phoneNumber,
    required String message,
  }) async {
    final number = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (number.isEmpty) {
      throw SmsException('Phone number missing hai.');
    }
    if (message.trim().isEmpty) {
      throw SmsException('Message khaali hai.');
    }
    try {
      final sent =
          await _channel.invokeMethod<bool>('sendSms', <String, Object>{
        'number': number,
        'message': message,
      });
      return sent ?? false;
    } on PlatformException catch (e) {
      throw SmsException(_friendlyError(e.code, e.message));
    } on MissingPluginException {
      throw SmsException('SMS channel maujood nahi — SMS app khol kar bhejein.');
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

  static String _friendlyError(String code, String? details) {
    switch (code) {
      case 'PERMISSION_DENIED':
        return 'SMS permission nahi mili. Settings mein SMS ki ijazat dein.';
      case 'NO_SMS_MANAGER':
        return 'Is device par SMS bhejna mumkin nahi.';
      case 'SEND_FAILED':
        return 'SMS nahi bheja ja saka. ${details ?? ''}'.trim();
      default:
        return details?.isNotEmpty == true
            ? details!
            : 'SMS bhejne mein masla hua.';
    }
  }
}

/// User-readable SMS failure.
class SmsException implements Exception {
  final String message;
  const SmsException(this.message);
  @override
  String toString() => 'SmsException: $message';
}
