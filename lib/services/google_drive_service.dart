import 'dart:async';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Google Drive backup for Namt Oil Mil (user-requested 2026-10-18).
///
/// 100% OPT-IN: nothing touches Google unless the user taps
/// "Google se connect karein" in Settings. The app works fully offline
/// without this; every method degrades gracefully when there is no
/// network, no Play Services, or the user never connected.
///
/// Auth model (google_sign_in 7.x):
/// * [signIn] — interactive: `authenticate()` then `authorizeScopes`
///   for [driveFileScope] (app-created files only — least privilege).
/// * [driveApiSilent] — non-interactive: lightweight auth + silent scope
///   authorization, for the 24h background worker. Returns null when it
///   cannot proceed without UI (then the worker skips and tries later).
/// * Connected state (account email) is kept in [FlutterSecureStorage];
///   Google manages the actual tokens internally.
class GoogleDriveService {
  GoogleDriveService({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Least-privilege scope: only files this app created.
  static const List<String> driveScopes = [drive.DriveApi.driveFileScope];

  static const String _keyAccountEmail = 'gdrive_account_email';
  static const String _keyAutoBackup = 'gdrive_auto_backup_enabled';
  static const String _keyLastBackupAt = 'gdrive_last_backup_at';

  /// Display name of the Drive folder that holds the backups.
  static const String backupFolderName = 'Namt Oil Mil Backup';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// The connected Google account email, or null when never connected.
  Future<String?> connectedEmail() => _storage.read(key: _keyAccountEmail);

  /// Whether the user is (still) connected. Uses lightweight auth only —
  /// never pops UI.
  Future<bool> isConnected() async {
    final email = await connectedEmail();
    if (email == null || email.isEmpty) return false;
    try {
      await _ensureInitialized();
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      return account != null;
    } catch (_) {
      // Offline / Play Services missing / revoked: treat as not connected
      // for now; the stored email remains so a later retry can succeed.
      return false;
    }
  }

  /// Interactive sign-in. Shows the Google account picker and the Drive
  /// consent screen. Returns the account email on success.
  ///
  /// Throws [GoogleDriveException] with a user-readable message on failure
  /// (including user cancellation).
  Future<String> signIn() async {
    await _ensureInitialized();
    GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw GoogleDriveException(_friendlySignInError(e.code.name));
    }
    try {
      await account.authorizationClient.authorizeScopes(driveScopes);
    } on GoogleSignInException catch (e) {
      throw GoogleDriveException(_friendlySignInError(e.code.name));
    }
    final email = account.email;
    await _storage.write(key: _keyAccountEmail, value: email);
    return email;
  }

  /// Signs out locally (keeps Drive authorization revoked separately via
  /// [disconnect]).
  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _storage.delete(key: _keyAccountEmail);
  }

  /// Revokes the app's Drive access entirely and signs out.
  Future<void> disconnect() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    await _storage.delete(key: _keyAccountEmail);
    await _storage.write(key: _keyAutoBackup, value: '0');
  }

  /// Silent (no-UI) Drive client. Used by the 24h background worker and by
  /// foreground code paths that must not interrupt the user.
  ///
  /// Returns null when silent auth is impossible (never connected, offline,
  /// revoked) — callers treat that as "skip for now".
  Future<drive.DriveApi?> driveApiSilent() async {
    try {
      await _ensureInitialized();
      final email = await connectedEmail();
      if (email == null || email.isEmpty) return null;
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account == null) return null;
      final authz = await account.authorizationClient
          .authorizationForScopes(driveScopes);
      if (authz == null) return null;
      return drive.DriveApi(authz.authClient(scopes: driveScopes));
    } catch (_) {
      return null;
    }
  }

  /// Interactive Drive client for foreground flows (user just tapped a
  /// button, so UI is allowed). Returns null when the user cancels.
  Future<drive.DriveApi?> driveApiInteractive() async {
    try {
      await _ensureInitialized();
      var account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      account ??= await GoogleSignIn.instance.authenticate();
      final authz =
          await account.authorizationClient.authorizeScopes(driveScopes);
      await _storage.write(key: _keyAccountEmail, value: account.email);
      return drive.DriveApi(authz.authClient(scopes: driveScopes));
    } on GoogleSignInException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Uploads [bytes] as [fileName] into [backupFolderName] on Drive.
  /// Creates the folder on first use. Returns the Drive file id.
  Future<String> uploadBackup({
    required drive.DriveApi api,
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/json',
  }) async {
    final folderId = await _findOrCreateFolder(api);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: mimeType,
    );
    final file = drive.File()
      ..name = fileName
      ..mimeType = mimeType
      ..parents = [folderId];
    final created = await api.files.create(file, uploadMedia: media);
    return created.id ?? '';
  }

  Future<String> _findOrCreateFolder(drive.DriveApi api) async {
    final q =
        "mimeType = 'application/vnd.google-apps.folder' and name = '$backupFolderName' and trashed = false";
    final list = await api.files.list(
      q: q,
      $fields: 'files(id, name)',
      spaces: 'drive',
    );
    final files = list.files ?? [];
    if (files.isNotEmpty && files.first.id != null) return files.first.id!;
    final folder = drive.File()
      ..name = backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder, $fields: 'id');
    return created.id ?? 'root';
  }

  // ------------------------------------------------------------ auto-backup

  /// Whether the 24h automatic backup is enabled (user toggle in Settings).
  Future<bool> isAutoBackupEnabled() async =>
      (await _storage.read(key: _keyAutoBackup)) == '1';

  Future<void> setAutoBackupEnabled(bool enabled) async =>
      _storage.write(key: _keyAutoBackup, value: enabled ? '1' : '0');

  /// ISO-8601 timestamp of the last successful Drive backup, or null.
  Future<DateTime?> lastBackupAt() async {
    final raw = await _storage.read(key: _keyLastBackupAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> recordBackupAt(DateTime when) async =>
      _storage.write(key: _keyLastBackupAt, value: when.toIso8601String());

  String _friendlySignInError(String code) {
    switch (code) {
      case 'canceled':
        return 'Google sign-in cancel kar diya gaya.';
      case 'interrupted':
        return 'Sign-in adhoora reh gaya — dobara koshish karein.';
      default:
        return 'Google se connect nahi ho saka. Internet check karke dobara koshish karein.';
    }
  }
}

/// User-readable error from the Google Drive flow.
class GoogleDriveException implements Exception {
  final String message;
  const GoogleDriveException(this.message);

  @override
  String toString() => message;
}

/// Riverpod access to [GoogleDriveService].
final googleDriveServiceProvider = Provider<GoogleDriveService>(
  (ref) => GoogleDriveService(),
);
