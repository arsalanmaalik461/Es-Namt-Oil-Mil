import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/screens/security/pin_setup_screen.dart';
import 'package:namt_oil_mil/services/app_lock_service.dart';

/// Security settings: PIN lock on/off, change PIN, biometric toggle,
/// auto-lock timeout. Standalone screen so other teams can link to it
/// without editing this file.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool? _pinEnabled;
  bool? _bioEnabled;
  bool? _bioAvailable;
  AutoLockTimeout? _timeout;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(appLockServiceProvider);
    final pin = await svc.isPinEnabled;
    final bio = await svc.isBiometricEnabled;
    final avail = await svc.canUseBiometric;
    final timeout = await svc.autoLockTimeout;
    if (!mounted) return;
    setState(() {
      _pinEnabled = pin;
      _bioEnabled = bio;
      _bioAvailable = avail;
      _timeout = timeout;
    });
  }

  Future<void> _togglePin(bool value) async {
    final l10n = AppLocalizations.of(context);
    final svc = ref.read(appLockServiceProvider);
    if (value) {
      final set = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (set == true && mounted) {
        setState(() => _pinEnabled = true);
      }
    } else {
      await svc.clearPin();
      if (!mounted) return;
      setState(() => _pinEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.security_pinRemoved)),
      );
    }
  }

  Future<void> _toggleBio(bool value) async {
    final l10n = AppLocalizations.of(context);
    final svc = ref.read(appLockServiceProvider);
    if (value && !(_bioAvailable ?? false)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.security_biometricNotAvailable)),
      );
      return;
    }
    await svc.setBiometricEnabled(value);
    setState(() => _bioEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = _pinEnabled == null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.security_title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l10n.security_pinLock),
                  subtitle: Text(l10n.security_pinLockDesc),
                  secondary: const Icon(Icons.pin_outlined),
                  value: _pinEnabled!,
                  onChanged: _togglePin,
                ),
                if (_pinEnabled!)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.security_changePin),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PinSetupScreen()),
                    ),
                  ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.security_biometric),
                  subtitle: Text(
                    (_bioAvailable ?? false)
                        ? l10n.security_biometricDesc
                        : l10n.security_biometricNotAvailable,
                  ),
                  secondary: const Icon(Icons.fingerprint),
                  value: _bioEnabled!,
                  onChanged: (_bioAvailable ?? false) ? _toggleBio : null,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l10n.security_autoLock,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                RadioGroup<AutoLockTimeout>(
                  groupValue: _timeout!,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref
                        .read(appLockServiceProvider)
                        .setAutoLockTimeout(v);
                    setState(() => _timeout = v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<AutoLockTimeout>(
                        title: Text(l10n.security_autoLockImmediate),
                        value: AutoLockTimeout.immediately,
                      ),
                      RadioListTile<AutoLockTimeout>(
                        title: Text(l10n.security_autoLock1min),
                        value: AutoLockTimeout.oneMinute,
                      ),
                      RadioListTile<AutoLockTimeout>(
                        title: Text(l10n.security_autoLock5min),
                        value: AutoLockTimeout.fiveMinutes,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
