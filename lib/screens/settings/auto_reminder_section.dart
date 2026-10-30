import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/services/auto_reminder_service.dart';
import 'package:namt_oil_mil/services/sms_service.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Settings section: automatic payment reminders (user-requested
/// 2026-10-30).
///
/// * WhatsApp (daily): a reminder with the customer's FULL ledger PDF is
///   prepared every day for each customer with a balance due. WhatsApp
///   does not let apps send silently, so the prepared reminders wait in
///   the Reminders screen and go out with one tap on Send.
/// * SMS (every 7 days): sent automatically from the SIM by
///   [AutoReminderService]; needs the device to be able to send SMS
///   directly (checked through [SmsService.canSendDirect]).
///
/// The toggles and the daily time persist through [AutoReminderSettings]
/// (saving also reschedules the background work).
class AutoReminderSection extends ConsumerStatefulWidget {
  const AutoReminderSection({super.key});

  @override
  ConsumerState<AutoReminderSection> createState() =>
      _AutoReminderSectionState();
}

class _AutoReminderSectionState extends ConsumerState<AutoReminderSection> {
  AutoReminderSettings? _settings;
  bool _smsCapable = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await AutoReminderSettings.load();
      final smsCapable = await SmsService.canSendDirect();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _smsCapable = smsCapable;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _update({
    bool? whatsappDaily,
    bool? smsWeekly,
    int? hour,
    int? minute,
  }) async {
    final current = _settings;
    if (current == null) return;
    final next = AutoReminderSettings(
      whatsappDaily: whatsappDaily ?? current.whatsappDaily,
      smsWeekly: smsWeekly ?? current.smsWeekly,
      hour: hour ?? current.hour,
      minute: minute ?? current.minute,
    );
    setState(() => _settings = next);
    try {
      await AutoReminderSettings.save(next);
    } catch (_) {
      // Keep the on-screen state; the engine retries on next change.
    }
  }

  Future<void> _pickTime() async {
    final current = _settings;
    if (current == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      await _update(hour: picked.hour, minute: picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final t = FragmentStrings.of(context);
    final settings = _settings;
    final localeCode = Localizations.localeOf(context).languageCode;
    final timeLabel = settings == null
        ? ''
        : DateFormat.jm(localeCode).format(
            DateTime(2000, 1, 1, settings.hour, settings.minute),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.reminders_autoTitle),
        SwitchListTile(
          secondary: const Icon(Icons.chat_bubble_outline),
          title: Text(t.reminders_autoWhatsappDaily),
          subtitle: Text(t.reminders_autoWhatsappDailyHint),
          value: settings?.whatsappDaily ?? false,
          onChanged: settings == null
              ? null
              : (v) => _update(whatsappDaily: v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.sms_outlined),
          title: Text(t.reminders_autoSmsWeekly),
          subtitle: Text(t.reminders_autoSmsWeeklyHint),
          value: settings?.smsWeekly ?? false,
          onChanged:
              settings == null ? null : (v) => _update(smsWeekly: v),
        ),
        if (settings?.smsWeekly ?? false)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(
                  _smsCapable
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color: _smsCapable
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _smsCapable
                        ? t.reminders_autoSmsReady
                        : t.reminders_autoSmsPermissionNeeded,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(t.reminders_autoTime),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: settings == null ? null : _pickTime,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
          child: Text(
            t.reminders_autoHowItWorks,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
