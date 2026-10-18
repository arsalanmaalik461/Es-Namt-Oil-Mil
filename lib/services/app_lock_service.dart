import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto-lock delay options.
enum AutoLockTimeout {
  immediately(0),
  oneMinute(60),
  fiveMinutes(300);

  const AutoLockTimeout(this.seconds);
  final int seconds;
}

/// App lock state: PIN and/or biometric gate on app launch / resume.
///
/// - PIN: 4-digit, SHA-256 hashed, stored in [FlutterSecureStorage]
///   (encrypted at rest by the OS keystore).
/// - Biometric: [LocalAuth], device must support it; falls back to PIN.
/// - Auto-lock: re-locks when the app returns from background after the
///   configured timeout.
class AppLockService {
  AppLockService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _biometrics = LocalAuthentication();

  static const _pinKey = 'app_lock.pin_hash';
  static const _pinEnabledKey = 'app_lock.pin_enabled';
  static const _bioEnabledKey = 'app_lock.biometric_enabled';
  static const _timeoutKey = 'app_lock.timeout_seconds';
  static const _lastPausedKey = 'app_lock.last_paused_ms';

  String _hashPin(String pin) =>
      sha256.convert(utf8.encode('namt-oil-mil|$pin')).toString();

  // -- PIN ---------------------------------------------------------------

  Future<bool> get isPinEnabled async =>
      (await _storage.read(key: _pinEnabledKey)) == '1';

  Future<bool> get hasPin async =>
      (await _storage.read(key: _pinKey)) != null;

  /// Stores a new 4-digit PIN (hashed) and enables PIN lock.
  Future<void> setPin(String pin) async {
    assert(RegExp(r'^\d{4}$').hasMatch(pin), 'PIN must be 4 digits');
    await _storage.write(key: _pinKey, value: _hashPin(pin));
    await _storage.write(key: _pinEnabledKey, value: '1');
  }

  /// Verifies a PIN attempt against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Disables PIN lock and wipes the stored hash.
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: '0');
  }

  // -- Biometric ----------------------------------------------------------

  Future<bool> get isBiometricEnabled async =>
      (await _storage.read(key: _bioEnabledKey)) == '1';

  Future<void> setBiometricEnabled(bool enabled) async =>
      _storage.write(key: _bioEnabledKey, value: enabled ? '1' : '0');

  /// True when the device can do biometric auth (hardware + enrolled).
  Future<bool> get canUseBiometric async {
    try {
      final canCheck = await _biometrics.canCheckBiometrics;
      final available = await _biometrics.getAvailableBiometrics();
      return canCheck && available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system biometric prompt. Returns true on success.
  Future<bool> authenticateBiometric({required String reason}) async {
    try {
      return await _biometrics.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  // -- Auto-lock -----------------------------------------------------------

  Future<AutoLockTimeout> get autoLockTimeout async {
    final raw = await _storage.read(key: _timeoutKey);
    final seconds = int.tryParse(raw ?? '');
    return AutoLockTimeout.values.firstWhere(
      (t) => t.seconds == seconds,
      orElse: () => AutoLockTimeout.immediately,
    );
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async =>
      _storage.write(key: _timeoutKey, value: timeout.seconds.toString());

  /// Call when the app goes to background.
  Future<void> markPaused() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastPausedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// True when the app should re-lock on resume (timeout elapsed).
  Future<bool> shouldLockOnResume() async {
    if (!await isPinEnabled && !await isBiometricEnabled) return false;
    final timeout = await autoLockTimeout;
    if (timeout == AutoLockTimeout.immediately) return true;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastPausedKey);
    if (last == null) return true;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= timeout.seconds * 1000;
  }

  /// True when any lock is active.
  Future<bool> get isLockActive async =>
      (await isPinEnabled) || (await isBiometricEnabled);
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

/// Whether the app is currently locked (gate visible).
final appLockedProvider = StateProvider<bool>((ref) => false);
