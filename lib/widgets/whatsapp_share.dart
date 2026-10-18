import 'package:share_plus/share_plus.dart';

/// WhatsApp sharing helpers for the v2 khata screens.
///
/// Today this shares through the system share sheet (the user picks
/// WhatsApp and the chat). It is intentionally a thin seam: Team 3
/// (features) upgrades [shareStatement] to open the customer's WhatsApp
/// chat directly via a `wa.me` deep link once a URL-launcher route is
/// approved — callers do not need to change.
class WhatsAppShare {
  const WhatsAppShare._();

  /// Shares [text] (e.g. a khata reminder / statement summary).
  static Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Shares a generated PDF statement file.
  static Future<void> sharePdf(String filePath, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: text,
      ),
    );
  }
}
