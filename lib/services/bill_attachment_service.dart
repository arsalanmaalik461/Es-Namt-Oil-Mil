import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Attaches a bill/receipt photo to a ledger transaction.
///
/// Flow: [pickBillImage] (Camera ya Gallery) → image is copied into the
/// app's private documents dir (`bills/`) → returned path is stored in
/// `ledger_entries.bill_image_path`. Thumbnails are shown from that path.
///
/// Private storage keeps bills with the app (included in local backup when
/// the DB is backed up; the files themselves travel with app data).
class BillAttachmentService {
  BillAttachmentService._();
  static final ImagePicker _picker = ImagePicker();

  /// Opens Camera or Gallery per [source] and returns the stored file path,
  /// or null when the user cancels.
  static Future<String?> pickBillImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return _storeBill(File(picked.path));
  }

  /// Copies [file] into the app's bills directory and returns the new path.
  static Future<String> _storeBill(File file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'bills'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final name =
        'bill_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final dest = File(p.join(dir.path, name));
    await file.copy(dest.path);
    return dest.path;
  }

  /// Deletes a stored bill image. Best-effort; never throws.
  static Future<void> deleteBillImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// True when [path] points to an existing image file.
  static Future<bool> exists(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }
}
