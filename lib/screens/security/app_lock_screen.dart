import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/screens/security/pin_setup_screen.dart';
import 'package:namt_oil_mil/services/app_lock_service.dart';

/// Gate shown on launch / resume when app lock is active.
///
/// Tries biometric first (if enabled + available); otherwise asks for PIN.
/// "Forgot PIN" resets the lock after confirmation.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  bool _busy = false;
  bool _bioTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_bioTried) return;
    _bioTried = true;
    final svc = ref.read(appLockServiceProvider);
    if (!await svc.isBiometricEnabled) return;
    if (!await svc.canUseBiometric) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok =
        await svc.authenticateBiometric(reason: l10n.security_biometric);
    if (ok && mounted) _unlock();
  }

  void _unlock() => ref.read(appLockedProvider.notifier).state = false;

  void _onDigit(String d) {
    if (_busy || _pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _submit();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(appLockServiceProvider).verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      _unlock();
    } else {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.security_wrongPin)),
      );
      setState(() {
        _pin = '';
        _busy = false;
      });
    }
  }

  Future<void> _forgotPin() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.security_forgotPin),
        content: Text(l10n.security_forgotPinMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(appLockServiceProvider).clearPin();
      await ref.read(appLockServiceProvider).setBiometricEnabled(false);
      _unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.lock_outline,
                  size: 44, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text(l10n.appTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.security_enterPin,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _tryBiometric,
              child: Text(l10n.security_unlockWithBiometric),
            ),
            const Spacer(),
            PinPad(
              onDigit: _onDigit,
              onBackspace: () =>
                  setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
            ),
            TextButton(
              onPressed: _forgotPin,
              child: Text(l10n.security_forgotPin),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
