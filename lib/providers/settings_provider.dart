import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Override this in `main()` with the real instance before `runApp`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

// ---------------------------------------------------------------------------
// Locale
// ---------------------------------------------------------------------------

const _localeKey = 'settings.locale';
const _defaultLocaleCode = 'en';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return Locale(prefs.getString(_localeKey) ?? _defaultLocaleCode);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

// ---------------------------------------------------------------------------
// Theme mode
// ---------------------------------------------------------------------------

const _themeKey = 'settings.themeMode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, mode.name);
    state = mode;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------------------
// Business profile
// ---------------------------------------------------------------------------

const _profileNameKey = 'business.name';
const _profileAddressKey = 'business.address';
const _profilePhoneKey = 'business.phone';

@immutable
class BusinessProfile {
  final String name;
  final String address;
  final String phone;

  const BusinessProfile({
    required this.name,
    required this.address,
    required this.phone,
  });

  BusinessProfile copyWith({String? name, String? address, String? phone}) {
    return BusinessProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          phone == other.phone;

  @override
  int get hashCode => Object.hash(name, address, phone);
}

class BusinessProfileNotifier extends Notifier<BusinessProfile> {
  @override
  BusinessProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return BusinessProfile(
      name: prefs.getString(_profileNameKey) ?? 'Namt Oil Mil',
      address: prefs.getString(_profileAddressKey) ?? '',
      phone: prefs.getString(_profilePhoneKey) ?? '',
    );
  }

  Future<void> save(BusinessProfile profile) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_profileNameKey, profile.name);
    await prefs.setString(_profileAddressKey, profile.address);
    await prefs.setString(_profilePhoneKey, profile.phone);
    state = profile;
  }
}

final businessProfileProvider =
    NotifierProvider<BusinessProfileNotifier, BusinessProfile>(
  BusinessProfileNotifier.new,
);

// ---------------------------------------------------------------------------
// Hisaab mode: personal vs business (user-requested 2026-10-18)
// ---------------------------------------------------------------------------

/// Which hisaab the user is currently viewing: personal or business.
/// Stored as a plain flag; screens filter their lists by it.
const _hisaabModeKey = 'settings.hisaabMode';

enum HisaabMode { business, personal }

class HisaabModeNotifier extends Notifier<HisaabMode> {
  @override
  HisaabMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_hisaabModeKey);
    return HisaabMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => HisaabMode.business,
    );
  }

  Future<void> setMode(HisaabMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_hisaabModeKey, mode.name);
    state = mode;
  }
}

final hisaabModeProvider =
    NotifierProvider<HisaabModeNotifier, HisaabMode>(HisaabModeNotifier.new);
