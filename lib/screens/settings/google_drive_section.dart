import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/services/drive_backup_service.dart';
import 'package:namt_oil_mil/services/google_drive_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Settings section: Google Drive backup (user-requested 2026-10-18).
///
/// * "Connect with Google" → Google account picker + Drive consent.
/// * Auto-backup toggle → WorkManager 24h periodic upload (network only).
/// * "Backup now" → immediate full-database upload.
/// * "Export date range" → from/to picker → accounts JSON for that
///   range uploaded to Drive.
///
/// Fully opt-in: with no connection the section only shows the connect
/// button, and everything else stays hidden.
class GoogleDriveSection extends ConsumerStatefulWidget {
  const GoogleDriveSection({super.key});

  @override
  ConsumerState<GoogleDriveSection> createState() =>
      _GoogleDriveSectionState();
}

class _GoogleDriveSectionState extends ConsumerState<GoogleDriveSection> {
  bool _busy = false;
  String? _email;
  bool _autoBackup = false;
  DateTime? _lastBackup;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Opportunistic daily backup when the user opens Settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driveBackupServiceProvider).maybeRunDailyBackup().then((_) {
        if (mounted) _refresh();
      });
    });
  }

  Future<void> _refresh() async {
    final drive = ref.read(googleDriveServiceProvider);
    final email = await drive.connectedEmail();
    final auto = await drive.isAutoBackupEnabled();
    final last = await drive.lastBackupAt();
    if (!mounted) return;
    setState(() {
      _email = email;
      _autoBackup = auto;
      _lastBackup = last;
      _loaded = true;
    });
  }

  /// Resolves a [DriveBackupResult]'s localisable message key + params
  /// into text for the current locale.
  String _resultText(FragmentStrings t, DriveBackupResult result) {
    switch (result.messageKey) {
      case 'backup_driveBackupSaved':
        return t.backup_driveBackupSaved(name: result.params['name'] ?? '');
      case 'backup_driveBackupFailed':
        return t.backup_driveBackupFailed(
            error: result.params['error'] ?? '');
      case 'backup_driveExportSaved':
        return t.backup_driveExportSaved(name: result.params['name'] ?? '');
      case 'backup_driveExportFailed':
        return t.backup_driveExportFailed(
            error: result.params['error'] ?? '');
      case 'backup_driveConnectFailed':
      default:
        return t.backup_driveConnectFailed;
    }
  }

  Future<void> _connect() async {
    final t = FragmentStrings.of(context);
    setState(() => _busy = true);
    try {
      final email = await ref.read(googleDriveServiceProvider).signIn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.backup_driveConnected(email: email))),
      );
    } on GoogleDriveException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _disconnect() async {
    final t = FragmentStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.backup_driveDisconnectTitle),
        content: Text(t.backup_driveDisconnectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.backup_driveDisconnect),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(googleDriveServiceProvider).disconnect();
      await ref.read(driveBackupServiceProvider).cancelDailyScheduler();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final t = FragmentStrings.of(context);
    final drive = ref.read(googleDriveServiceProvider);
    final backup = ref.read(driveBackupServiceProvider);
    setState(() => _busy = true);
    try {
      await drive.setAutoBackupEnabled(value);
      if (value) {
        await backup.ensureDailyScheduler();
        // Run one now so the user doesn't wait 24h for the first backup.
        final result =
            await backup.runFullBackupNow(interactive: true);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_resultText(t, result))));
        }
      } else {
        await backup.cancelDailyScheduler();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _backupNow() async {
    final t = FragmentStrings.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(driveBackupServiceProvider)
          .runFullBackupNow(interactive: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_resultText(t, result))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _exportDateRange() async {
    final t = FragmentStrings.of(context);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(driveBackupServiceProvider).runDateRangeExport(
                from: picked.start,
                to: picked.end,
                interactive: true,
              );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_resultText(t, result))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = FragmentStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: t.backup_driveTitle),
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_email == null || _email!.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.backup_driveConnectIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: t.backup_driveConnect,
                  icon: Icons.cloud_upload_outlined,
                  onPressed: _busy ? null : _connect,
                  isLoading: _busy,
                  expanded: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          )
        else ...[
          ListTile(
            leading: Icon(Icons.cloud_done_outlined, color: scheme.primary),
            title: Text(_email!),
            subtitle: Text(_lastBackup == null
                ? t.backup_driveNoBackupYet
                : t.backup_driveLastBackup(
                    date: DateFormat.yMMMd().add_jm().format(_lastBackup!))),
            trailing: TextButton(
              onPressed: _busy ? null : _disconnect,
              child: Text(t.backup_driveDisconnect),
            ),
          ),
          SwitchListTile(
            title: Text(t.backup_driveAutoBackup),
            subtitle: Text(t.backup_driveAutoBackupHint),
            value: _autoBackup,
            onChanged: _busy ? null : _toggleAutoBackup,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: t.backup_driveBackupNow,
                  icon: Icons.backup_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _backupNow,
                  isLoading: _busy,
                  expanded: true,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: t.backup_driveExportRange,
                  icon: Icons.date_range_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _exportDateRange,
                  expanded: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
