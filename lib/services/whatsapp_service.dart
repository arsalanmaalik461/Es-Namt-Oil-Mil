import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp integration for customer statements (user-requested 2026-10-18).
///
/// Two flows, both pure-Dart (no native code):
/// * [openChat] — opens the customer's WhatsApp chat directly via a
///   `https://wa.me/<number>` link (external application).
/// * [shareStatementPdf] — writes the statement PDF to the temp directory
///   and opens the system share sheet so the user can send it through
///   WhatsApp (or any other app).
///
/// Phone numbers are normalized for Pakistan: leading `0` becomes `92`.
class WhatsAppService {
  /// Strips everything but digits and applies the Pakistan country code.
  ///
  /// Returns null when [raw] has no usable digits.
  String? normalizeNumber(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('92') && digits.length >= 12) return digits;
    if (digits.startsWith('0') && digits.length == 11) {
      return '92${digits.substring(1)}';
    }
    if (digits.length == 10) return '92$digits';
    return digits;
  }

  /// Builds the wa.me chat link for [rawNumber].
  Uri? chatUri(String? rawNumber, {String? message}) {
    final number = normalizeNumber(rawNumber);
    if (number == null) return null;
    return Uri.parse(
      'https://wa.me/$number${message == null || message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}'}',
    );
  }

  /// Opens the customer's WhatsApp chat directly. Returns false when the
  /// number is missing/invalid or no handler (e.g. WhatsApp not installed)
  /// could open the link.
  Future<bool> openChat(String? rawNumber, {String? message}) async {
    final uri = chatUri(rawNumber, message: message);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens the customer's WhatsApp chat with [message] prefilled
  /// (text-only path; named for the reminders screen's wiring).
  Future<bool> openChatWithText(String? rawNumber, String message) =>
      openChat(rawNumber, message: message);

  /// Shares [pdfBytes] as [fileName] through the system share sheet
  /// (user picks WhatsApp). Returns the share result status.
  Future<ShareResultStatus> shareStatementPdf({
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

  /// Sends a payment reminder WITH the customer's full ledger statement
  /// PDF attached (user-requested 2026-10-25: reminders must carry the
  /// ledger PDF, not text alone).
  ///
  /// WhatsApp deep links (wa.me) cannot attach files, so the PDF and the
  /// reminder text go together through the system share sheet — the user
  /// picks the customer's WhatsApp chat and both arrive in one message.
  /// [pdfBytes] come from the customer-statement PDF builder (reports/PDF
  /// module); [message] is the reminder text (see reminder_texts.dart),
  /// sent as the share text alongside the PDF.
  Future<ShareResultStatus> shareReminderWithStatement({
    required Uint8List pdfBytes,
    required String customerName,
    required String message,
  }) {
    final safeCustomer =
        customerName.replaceAll(RegExp(r'[^\w\- ]'), '_').trim();
    return shareStatementPdf(
      pdfBytes: pdfBytes,
      fileName: 'namt-oil-mil-statement-$safeCustomer.pdf',
      text: message,
    );
  }
}

/// Riverpod access to [WhatsAppService].
final whatsAppServiceProvider = Provider<WhatsAppService>(
  (ref) => WhatsAppService(),
);
