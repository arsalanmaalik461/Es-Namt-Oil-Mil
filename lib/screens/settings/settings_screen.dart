import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/widgets/app_button.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

import 'auto_reminder_section.dart';
import 'google_drive_section.dart';
import 'package:namt_oil_mil/screens/security/security_settings_screen.dart';

/// App settings: language, theme, business profile, and an About section.
/// Language/theme changes apply instantly — no restart needed.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncProfile(BusinessProfile profile) {
    if (_profileLoaded) return;
    _profileLoaded = true;
    _nameController.text = profile.name;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    await ref.read(businessProfileProvider.notifier).save(
          BusinessProfile(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settings_saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(businessProfileProvider);
    _syncProfile(profile);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        children: [
          SectionHeader(title: l10n.settings_language),
          RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.langEnglish),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(l10n.langUrdu),
                  value: 'ur',
                ),
                RadioListTile<String>(
                  title: Text(l10n.langSindhi),
                  value: 'sd',
                ),
              ],
            ),
          ),
          const Divider(),
          SectionHeader(title: l10n.settings_theme),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(),
          SectionHeader(title: l10n.settings_businessProfile),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: l10n.settings_businessName,
                    validator: AppValidators.required(context),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _addressController,
                    label: l10n.settings_address,
                    maxLines: 2,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneController,
                    label: l10n.settings_phone,
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.phone(context),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.common_save,
                    onPressed: _saveProfile,
                    icon: Icons.save_outlined,
                    expanded: true,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const Divider(),
          SectionHeader(title: l10n.settings_about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.more_about),
            subtitle: Text(l10n.about_version('1.0.0')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, Routes.about),
          ),
          const Divider(),
          // Hisaab mode: personal vs business (Team 7, 2026-10-18).
          _HisaabModeSection(),
          const Divider(),
          // App lock & security (Team 7, 2026-10-18).
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.security_title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SecuritySettingsScreen(),
              ),
            ),
          ),
          const Divider(),
          // Google Drive backup (opt-in, user-requested 2026-10-18).
          const GoogleDriveSection(),
          const Divider(),
          // Automatic payment reminders (user-requested 2026-10-30).
          const AutoReminderSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Personal vs business hisaab toggle (Team 7, 2026-10-18).
class _HisaabModeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(hisaabModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settings_hisaabMode),
        RadioGroup<HisaabMode>(
          groupValue: mode,
          onChanged: (v) {
            if (v != null) ref.read(hisaabModeProvider.notifier).setMode(v);
          },
          child: Column(
            children: [
              RadioListTile<HisaabMode>(
                title: Text(l10n.settings_hisaabBusiness),
                value: HisaabMode.business,
                secondary: const Icon(Icons.business_outlined),
              ),
              RadioListTile<HisaabMode>(
                title: Text(l10n.settings_hisaabPersonal),
                value: HisaabMode.personal,
                secondary: const Icon(Icons.person_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
