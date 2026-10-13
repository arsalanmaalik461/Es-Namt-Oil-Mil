import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/services/backup_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/widgets/confirm_dialog.dart';

/// Backup & restore (route: /backup).
///
/// 100% offline: the backup is a single versioned JSON file written with the
/// platform save dialog (or the share sheet as a fallback) — nothing is
/// uploaded anywhere. Restore validates structure + checksums *before*
/// touching the database and runs inside one transaction, so a failed
/// restore can never leave half-written data.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _status;

  String _fileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'namt-oil-mil-backup-$stamp.json';
  }

  /// backup_error* keys are not in error_text's map yet, so translate them
  /// locally; everything else goes through the shared contract.
  String _backupErrorText(FragmentStrings t, AppException e) {
    switch (e.messageKey) {
      case 'backup_errorInvalidFile':
        return t.backup_errorInvalidFile;
      case 'backup_errorUnsupportedVersion':
        return t.backup_errorUnsupportedVersion(
            version: e.params['version'] ?? '');
      case 'backup_errorMissingTables':
        return t.backup_errorMissingTables(tables: e.params['tables'] ?? '');
      case 'backup_errorChecksum':
        return t.backup_errorChecksum(table: e.params['table'] ?? '');
      default:
        return errorText(context, e);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createBackup() async {
    if (_busy) return;
    final t = FragmentStrings.of(context);
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final service = ref.read(backupServiceProvider);
      final doc = await service.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(doc)));
      final fileName = _fileName();

      bool saveSupported = true;
      Uri? uri;
      try {
        uri = await FilePicker.saveFile(
          fileName: fileName,
          bytes: bytes,
          mimeType: 'application/json',
          dialogTitle: t.backup_create,
        );
      } catch (_) {
        saveSupported = false;
      }
      if (!mounted) return;

      if (!saveSupported && !kIsWeb) {
        // No native save dialog on this platform: hand the file to the
        // share sheet so the user can still put it somewhere visible.
        await SharePlus.instance.share(ShareParams(
          text: fileName,
          files: [
            XFile.fromData(bytes, name: fileName, mimeType: 'application/json'),
          ],
        ));
        if (!mounted) return;
      } else if (uri == null) {
        return; // user cancelled the save dialog — stay silent.
      }

      final tables = doc['tables'] as Map;
      var rows = 0;
      for (final v in tables.values) {
        rows += (v as List).length;
      }
      final msg = t.backup_created(count: rows, tables: tables.length);
      setState(() => _status = msg);
      _snack(msg);
    } on AppException catch (e) {
      if (mounted) _snack(_backupErrorText(t, e));
    } catch (_) {
      if (mounted) {
        _snack(AppLocalizations.of(context).error_generic);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy) return;
    final t = FragmentStrings.of(context);
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final picked = await FilePicker.pickFiles(
        dialogTitle: t.backup_chooseFile,
        allowedExtensions: ['json'],
      );
      if (!mounted) return;
      if (picked.isEmpty) return; // user cancelled the picker.
      final bytes = await picked.first.readAsBytes();

      final service = ref.read(backupServiceProvider);
      // Throws a clean ValidationException on any invalid file — the
      // database is untouched at this point.
      final summary = await service.validateBackup(bytes);
      if (!mounted) return;

      final confirmed = await showConfirmDialog(
        context,
        title: t.backup_confirmTitle,
        message:
            '${t.backup_summaryTitle}\n${t.backup_exportedAt(date: summary.exportedAtIso)}\n'
            '${t.backup_tablesCount(count: summary.tableCount)} · '
            '${t.backup_recordsCount(count: summary.totalRows)}\n\n'
            '${t.backup_confirmMessage}',
        confirmLabel: t.backup_confirmRestore,
        danger: true,
      );
      if (confirmed != true || !mounted) return;

      final restored = await service.restoreBackup(bytes);
      // Drop cached reads so every screen reloads from the restored data.
      ref.invalidate(databaseProvider);
      ref.invalidate(reportRepositoryProvider);
      if (!mounted) return;
      final msg = t.backup_restored(count: restored);
      setState(() => _status = msg);
      _snack(msg);
    } on AppException catch (e) {
      if (mounted) _snack(_backupErrorText(t, e));
    } catch (_) {
      if (mounted) {
        _snack(AppLocalizations.of(context).error_generic);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.backup_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.backup_intro,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _createBackup,
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(_busy ? t.backup_creating : t.backup_create),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restoreBackup,
                    icon: const Icon(Icons.restore_outlined),
                    label: Text(t.backup_restore),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_status!)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
