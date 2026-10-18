import 'package:flutter_contacts/flutter_contacts.dart';

/// Imports customers from the phone's contact list.
///
/// Flow: [requestPermission] → [pickContact] (native picker) → caller
/// prefills the Add-Customer form with [ImportedContact.name] and
/// [ImportedContact.phone].
///
/// Needs READ_CONTACTS permission on Android (declared in AndroidManifest).
class ContactImportService {
  ContactImportService._();

  /// True when the app may read contacts (already granted or just granted).
  static Future<bool> requestPermission() async {
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  /// Opens the native contact picker. Returns null when the user cancels.
  ///
  /// The native picker is permissionless — no permission dialog is shown.
  static Future<ImportedContact?> pickContact() async {
    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone},
    );
    if (contact == null) return null;
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final name = contact.displayName?.trim() ?? '';
    if (name.isEmpty && phone.isEmpty) return null;
    return ImportedContact(
      name: name.isEmpty ? phone : name,
      phone: _digitsOnly(phone),
    );
  }

  /// Searches contacts by [query] (for an in-app search UI).
  static Future<List<ImportedContact>> search(String query) async {
    final granted = await requestPermission();
    if (!granted) return const [];
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );
    final q = query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    final out = <ImportedContact>[];
    for (final c in contacts) {
      final name = c.displayName?.trim() ?? '';
      final phone =
          c.phones.isNotEmpty ? _digitsOnly(c.phones.first.number) : '';
      if (q.isEmpty ||
          name.toLowerCase().contains(q) ||
          (qDigits.isNotEmpty && phone.contains(qDigits))) {
        if (name.isNotEmpty || phone.isNotEmpty) {
          out.add(ImportedContact(
            name: name.isEmpty ? phone : name,
            phone: phone,
          ));
        }
      }
      if (out.length >= 50) break;
    }
    return out;
  }

  static String _digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'[^\d+]'), '');
}

/// A phone contact mapped onto customer fields.
class ImportedContact {
  final String name;
  final String phone;
  const ImportedContact({required this.name, required this.phone});
}
