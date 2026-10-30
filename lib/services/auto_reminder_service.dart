import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/services/drive_backup_service.dart'
    show driveBackupCallbackDispatcher;
import 'package:namt_oil_mil/services/reminder_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/services/sms_service.dart';
import 'package:namt_oil_mil/utils/time.dart';

/// Automatic payment reminders (user-requested 2026-10-30).
///
/// Two cadences, both targeting ONLY customers who owe the business
/// (cached `balance_paisa > 0`, the ledger-derived figure):
///
/// * **WhatsApp — daily.** WhatsApp sends are inherently user-tap (the
///   statement PDF rides the system share sheet), so automation here
///   means PREPARING the queue: [AutoReminderService.dueWhatsApp] lists
///   every owing customer not yet reminded today, the UI presents them
///   with the full-ledger PDF ready to share, and a successful share is
///   recorded via [AutoReminderService.markSent] so the customer drops
///   off today's queue.
/// * **SMS — every 7 days.** A real SMS can be sent unattended via
///   [SmsService.sendDirect] (Android SmsManager), so this cadence truly
///   sends: [AutoReminderService.runForegroundCatchUp] runs shortly
///   after every app start and sends to each customer whose last SMS is
///   7+ days old (or who was never sent one).
///
/// Send history lives in `reminder_auto_log` (schema v5). A row is
/// written ONLY on a confirmed send — a failed or unattempted send
/// leaves the customer due, never falsely stamped.
///
/// Platform fact: the `namt_oil_mil/sms` MethodChannel is registered by
/// MainActivity in the FOREGROUND engine only. The WorkManager
/// background isolate can compute due lists (sqflite works there) but
/// its SMS attempts throw (converted to an [SmsException] by
/// [SmsService]); [AutoReminderService.runBackgroundCheck] catches that
/// per customer and leaves them pending, so the real sends happen in
/// the foreground catch-up on the next app open.
class AutoReminderSettings {
  final bool whatsappDaily;
  final bool smsWeekly;
  final int hour;
  final int minute;

  const AutoReminderSettings({
    this.whatsappDaily = false,
    this.smsWeekly = false,
    this.hour = 10,
    this.minute = 0,
  });

  static const String _prefix = 'auto_reminder_';
  static const String _keyWhatsappDaily = '${_prefix}whatsapp_daily';
  static const String _keySmsWeekly = '${_prefix}sms_weekly';
  static const String _keyHour = '${_prefix}hour';
  static const String _keyMinute = '${_prefix}minute';

  AutoReminderSettings copyWith({
    bool? whatsappDaily,
    bool? smsWeekly,
    int? hour,
    int? minute,
  }) {
    return AutoReminderSettings(
      whatsappDaily: whatsappDaily ?? this.whatsappDaily,
      smsWeekly: smsWeekly ?? this.smsWeekly,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// Loads the persisted settings (defaults: both cadences OFF, 10:00).
  static Future<AutoReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AutoReminderSettings(
      whatsappDaily: prefs.getBool(_keyWhatsappDaily) ?? false,
      smsWeekly: prefs.getBool(_keySmsWeekly) ?? false,
      hour: prefs.getInt(_keyHour) ?? 10,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  /// Persists [settings] and re-syncs the WorkManager schedule so a
  /// toggle/time change takes effect immediately.
  static Future<void> save(AutoReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWhatsappDaily, settings.whatsappDaily);
    await prefs.setBool(_keySmsWeekly, settings.smsWeekly);
    await prefs.setInt(_keyHour, settings.hour);
    await prefs.setInt(_keyMinute, settings.minute);
    await AutoReminderService.syncSchedule();
  }
}

/// One customer due a reminder, with the balance they currently owe.
class DueReminder {
  final Customer customer;
  final int balancePaisa;

  const DueReminder({required this.customer, required this.balancePaisa});
}

/// Engine behind [AutoReminderSettings]: due computation, send logging,
/// foreground/background execution and WorkManager scheduling.
/// All methods are static and fail-safe — nothing here ever throws into
/// the UI or the background worker.
class AutoReminderService {
  AutoReminderService._();

  /// `reminder_auto_log.channel` values.
  static const String channelWhatsapp = 'whatsapp';
  static const String channelSms = 'sms';

  /// WorkManager registration for the daily background check. The task
  /// is executed by the SHARED [driveBackupCallbackDispatcher] (there
  /// can be only one WorkManager callback dispatcher per app).
  static const String taskUniqueName = 'namt_oil_mil_auto_reminder_daily';
  static const String taskName = 'autoReminderDaily';

  /// SharedPreferences key holding the app UI locale code ('en'/'ur'/'sd')
  /// — the same key `settings_provider.dart` writes.
  static const String _localePrefsKey = 'settings.locale';

  // ------------------------------------------------------------ cadence
  //
  // Pure date-window logic (unit-tested): a customer is due when they
  // have no confirmed send inside the channel's window, comparing
  // LOCAL calendar days — "today" for WhatsApp, "the last 7 days" for
  // SMS (a send exactly 7 calendar days ago makes the customer due).

  /// Whether a send on [channel] is due at [now], given the last
  /// confirmed send time ([lastSentAt], null = never sent).
  static bool isChannelDue({
    required String channel,
    required DateTime now,
    required DateTime? lastSentAt,
  }) {
    if (lastSentAt == null) return true;
    final days = DateTime(now.year, now.month, now.day)
        .difference(
            DateTime(lastSentAt.year, lastSentAt.month, lastSentAt.day))
        .inDays;
    return channel == channelSms ? days >= 7 : days >= 1;
  }

  /// Pure selection: the subset of [customers] due on [channel] at
  /// [now] — owing customers only (`balancePaisa > 0`), filtered by
  /// [isChannelDue] against [lastSentByCustomerId] (absent = never sent).
  static List<DueReminder> selectDue({
    required List<Customer> customers,
    required Map<int, DateTime?> lastSentByCustomerId,
    required String channel,
    required DateTime now,
  }) {
    final due = <DueReminder>[];
    for (final customer in customers) {
      if (customer.balancePaisa <= 0) continue;
      final lastSent =
          customer.id == null ? null : lastSentByCustomerId[customer.id];
      if (!isChannelDue(channel: channel, now: now, lastSentAt: lastSent)) {
        continue;
      }
      due.add(DueReminder(
          customer: customer, balancePaisa: customer.balancePaisa));
    }
    return due;
  }

  // ------------------------------------------------------------ due lists

  /// Customers due a WhatsApp reminder: they owe money and have no
  /// successful 'whatsapp' log entry TODAY (local date).
  static Future<List<DueReminder>> dueWhatsApp() =>
      _due(channelWhatsapp, DateTime.now());

  /// Customers due an SMS reminder: they owe money and have no
  /// successful 'sms' log entry in the last 7 days.
  static Future<List<DueReminder>> dueSms() => _due(channelSms, DateTime.now());

  static Future<List<DueReminder>> _due(String channel, DateTime now) async {
    final db = await DatabaseHelper.instance.database;
    final customers =
        await CustomerRepository(db).search(limit: 100000);
    final lastSent = await _lastSentByCustomer(channel);
    return selectDue(
      customers: customers,
      lastSentByCustomerId: lastSent,
      channel: channel,
      now: now,
    );
  }

  /// Latest confirmed send per customer on [channel]
  /// (`MAX(sent_at)` over 'sent' rows), keyed by customer id.
  static Future<Map<int, DateTime>> _lastSentByCustomer(String channel) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT customer_id, MAX(sent_at) AS last_sent '
      'FROM reminder_auto_log '
      "WHERE channel = ? AND status = 'sent' "
      'GROUP BY customer_id',
      [channel],
    );
    return {
      for (final row in rows)
        (row['customer_id'] as int): fromEpochMillis(row['last_sent'] as int),
    };
  }

  /// Records a CONFIRMED send. Callers must call this only after the
  /// send actually succeeded (SMS accepted by the OS, WhatsApp share
  /// completed) — the due computation trusts these rows completely.
  static Future<void> markSent(
      int customerId, String channel, int balancePaisa) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('reminder_auto_log', {
      'customer_id': customerId,
      'channel': channel,
      'sent_at': nowMillis(),
      'balance_paisa': balancePaisa,
      'status': 'sent',
    });
  }

  // ------------------------------------------------------------ sending

  /// The number an auto-SMS goes to: the customer's phone, falling back
  /// to the WhatsApp number (a WhatsApp number is the customer's mobile
  /// SIM number; many customers have only that saved). Null when the
  /// customer has no number at all — such customers are skipped, never
  /// attempted and never marked.
  static String? smsNumberFor(Customer customer) {
    final phone = customer.phone?.trim() ?? '';
    if (phone.isNotEmpty) return phone;
    final whatsapp = customer.whatsappNumber?.trim() ?? '';
    if (whatsapp.isNotEmpty) return whatsapp;
    return null;
  }

  /// Reminder script from the stored app locale: 'ur' → Urdu builders,
  /// anything else → English (matches the manual reminder flows).
  static Future<String> _reminderScript() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localePrefsKey) == 'ur' ? 'ur' : 'en';
  }

  /// Attempts the SMS sends for [due]. A customer is marked sent ONLY
  /// when [SmsService.sendDirect] confirms; any failure (no channel in
  /// a background isolate, permission denied, no SIM) leaves them due.
  /// Returns (sent, failed) counts — customers with no number are
  /// skipped entirely (not counted either way).
  static Future<({int sent, int failed})> _attemptSmsSends(
      List<DueReminder> due, String script) async {
    var sent = 0;
    var failed = 0;
    for (final item in due) {
      final customer = item.customer;
      final number = smsNumberFor(customer);
      if (number == null || customer.id == null) continue;
      try {
        final reminderText = script == 'ur'
            ? buildReminderUr(
                partyName: customer.name, balancePaisa: item.balancePaisa)
            : buildReminderEn(
                partyName: customer.name, balancePaisa: item.balancePaisa);
        final body = await ReminderService.smsTextWithLedgerSummary(
          customerId: customer.id!,
          reminderText: reminderText,
          balancePaisa: item.balancePaisa,
          script: script,
        );
        final ok =
            await SmsService.sendDirect(phoneNumber: number, message: body);
        if (ok) {
          await markSent(customer.id!, channelSms, item.balancePaisa);
          sent++;
        } else {
          failed++;
        }
      } catch (_) {
        // SmsException / MissingPluginException / PlatformException —
        // leave the customer pending; the next catch-up retries.
        failed++;
      }
    }
    return (sent: sent, failed: failed);
  }

  /// Foreground catch-up, run shortly after app start. Sends every due
  /// weekly SMS for real (the SMS channel exists in this engine) when
  /// the SMS cadence is enabled, and reports how many WhatsApp
  /// reminders are prepared/pending for the UI queue (0 when the
  /// WhatsApp cadence is off). Never throws.
  static Future<Map<String, int>> runForegroundCatchUp() async {
    var smsSent = 0;
    var smsFailed = 0;
    var whatsappPending = 0;
    try {
      final settings = await AutoReminderSettings.load();
      if (settings.smsWeekly) {
        final result =
            await _attemptSmsSends(await dueSms(), await _reminderScript());
        smsSent = result.sent;
        smsFailed = result.failed;
      }
      if (settings.whatsappDaily) {
        whatsappPending = (await dueWhatsApp()).length;
      }
    } catch (_) {
      // Best-effort by design — a failed catch-up must never surface.
    }
    return {
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'whatsappPending': whatsappPending,
    };
  }

  /// Background check, run by the shared WorkManager dispatcher when
  /// the [taskName] task fires. Opens the DB in the background isolate
  /// (same pattern as the Drive backup worker), recomputes the due
  /// lists and attempts the SMS sends defensively: this isolate has no
  /// `namt_oil_mil/sms` channel (registered only by MainActivity), so
  /// attempts fail cleanly and customers stay pending for the
  /// foreground catch-up — nothing is ever marked without a confirmed
  /// send. WhatsApp cannot be sent from here at all (share sheet is
  /// user-tap); its queue is recomputed fresh by [dueWhatsApp]
  /// whenever the app opens, so there is nothing to persist. Never
  /// throws.
  static Future<void> runBackgroundCheck() async {
    try {
      final settings = await AutoReminderSettings.load();
      if (!settings.whatsappDaily && !settings.smsWeekly) return;
      if (settings.smsWeekly) {
        await _attemptSmsSends(await dueSms(), await _reminderScript());
      }
    } catch (_) {
      // Best-effort: a failed tick must not crash the worker; the next
      // tick (or the foreground catch-up) retries.
    }
  }

  // ------------------------------------------------------------ scheduling

  /// Re-asserts the WorkManager schedule from the persisted settings:
  /// either cadence on → the daily [taskName] periodic task is
  /// registered (first run at the next occurrence of the configured
  /// time); both off → the task is cancelled. Called from
  /// [AutoReminderSettings.save] and at app start. Never throws (on
  /// platforms without WorkManager the foreground catch-up still
  /// covers the SMS cadence).
  static Future<void> syncSchedule() async {
    try {
      final settings = await AutoReminderSettings.load();
      if (!settings.whatsappDaily && !settings.smsWeekly) {
        await Workmanager().cancelByUniqueName(taskUniqueName);
        return;
      }
      await Workmanager().initialize(driveBackupCallbackDispatcher);
      final now = DateTime.now();
      var next = DateTime(
          now.year, now.month, now.day, settings.hour, settings.minute);
      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }
      await Workmanager().registerPeriodicTask(
        taskUniqueName,
        taskName,
        frequency: const Duration(hours: 24),
        initialDelay: next.difference(now),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } catch (_) {
      // Plugin unavailable on this platform — scheduling is skipped;
      // runForegroundCatchUp at app start still sends due SMS.
    }
  }
}
