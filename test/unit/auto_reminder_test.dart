import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/customer.dart';
import 'package:namt_oil_mil/services/auto_reminder_service.dart';

import '../helpers/test_db.dart';

/// Cadence + due-list tests for the automatic reminders
/// (user-requested 2026-10-30): WhatsApp daily, SMS every 7 days,
/// owing customers only (balance > 0).
void main() {
  // Fixed "now" so the calendar-day windows are deterministic.
  final now = DateTime(2026, 10, 30, 11, 0);

  Customer owing(int id, int balancePaisa) =>
      Customer(id: id, name: 'C$id', balancePaisa: balancePaisa);

  group('isChannelDue (pure cadence windows)', () {
    test('never sent -> due on both channels', () {
      expect(
          AutoReminderService.isChannelDue(
              channel: 'whatsapp', now: now, lastSentAt: null),
          isTrue);
      expect(
          AutoReminderService.isChannelDue(
              channel: 'sms', now: now, lastSentAt: null),
          isTrue);
    });

    test('whatsapp: sent today -> not due; sent yesterday -> due', () {
      expect(
          AutoReminderService.isChannelDue(
              channel: 'whatsapp',
              now: now,
              lastSentAt: DateTime(2026, 10, 30, 0, 5)),
          isFalse);
      expect(
          AutoReminderService.isChannelDue(
              channel: 'whatsapp',
              now: now,
              lastSentAt: DateTime(2026, 10, 29, 23, 55)),
          isTrue);
    });

    test('sms: 6 days ago -> not due; 7 days ago -> due; 8 -> due', () {
      expect(
          AutoReminderService.isChannelDue(
              channel: 'sms',
              now: now,
              lastSentAt: DateTime(2026, 10, 24, 11, 0)),
          isFalse);
      expect(
          AutoReminderService.isChannelDue(
              channel: 'sms',
              now: now,
              lastSentAt: DateTime(2026, 10, 23, 11, 0)),
          isTrue);
      expect(
          AutoReminderService.isChannelDue(
              channel: 'sms',
              now: now,
              lastSentAt: DateTime(2026, 10, 22, 11, 0)),
          isTrue);
      expect(
          AutoReminderService.isChannelDue(
              channel: 'sms', now: now, lastSentAt: now),
          isFalse);
    });
  });

  group('selectDue (pure selection)', () {
    test('zero and negative balances are never due', () {
      final customers = [owing(1, 0), owing(2, -500), owing(3, 700)];
      final due = AutoReminderService.selectDue(
        customers: customers,
        lastSentByCustomerId: const {},
        channel: 'whatsapp',
        now: now,
      );
      expect(due.map((d) => d.customer.id), [3]);
      expect(due.single.balancePaisa, 700);
    });

    test('a send logged today removes the customer from whatsapp due', () {
      final due = AutoReminderService.selectDue(
        customers: [owing(1, 1000), owing(2, 2000)],
        lastSentByCustomerId: {1: DateTime(2026, 10, 30, 9, 0)},
        channel: 'whatsapp',
        now: now,
      );
      expect(due.map((d) => d.customer.id), [2]);
    });

    test('sms window: logged 6 days ago still excluded, 7 days included',
        () {
      final due = AutoReminderService.selectDue(
        customers: [owing(1, 1000), owing(2, 2000), owing(3, 3000)],
        lastSentByCustomerId: {
          1: DateTime(2026, 10, 24, 10, 0), // 6 days ago
          2: DateTime(2026, 10, 23, 10, 0), // 7 days ago
        },
        channel: 'sms',
        now: now,
      );
      expect(due.map((d) => d.customer.id), [2, 3]);
    });
  });

  group('AutoReminderSettings persistence', () {
    test('defaults: both cadences off, 10:00', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await AutoReminderSettings.load();
      expect(s.whatsappDaily, isFalse);
      expect(s.smsWeekly, isFalse);
      expect(s.hour, 10);
      expect(s.minute, 0);
    });

    test('save -> load round-trips all fields', () async {
      SharedPreferences.setMockInitialValues({});
      await AutoReminderSettings.save(const AutoReminderSettings(
          whatsappDaily: true, smsWeekly: true, hour: 9, minute: 30));
      final s = await AutoReminderSettings.load();
      expect(s.whatsappDaily, isTrue);
      expect(s.smsWeekly, isTrue);
      expect(s.hour, 9);
      expect(s.minute, 30);
    });
  });

  group('due lists against the real database', () {
    setUpAll(initFfiDatabase);

    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    Future<int> owingCustomer(String name, {String? phone}) async {
      final accounting = await freshAccountingService();
      final id = await makeCustomer(name);
      final cashId = await seededCashAccountId();
      await accounting.postCustomerUdhaar(
        customerId: id,
        accountId: cashId,
        amountPaisa: 150000,
        date: DateTime(2026, 10, 29),
      );
      if (phone != null) {
        final db = await DatabaseHelper.instance.database;
        await db.update('customers', {'phone': phone},
            where: 'id = ?', whereArgs: [id]);
      }
      return id;
    }

    test('reminder_auto_log table exists (schema v5)', () async {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='reminder_auto_log'");
      expect(rows.length, 1);
      expect(DatabaseHelper.dbVersion, 5);
    });

    test('owing customer is due on both channels; settled is not',
        () async {
      final owingId = await owingCustomer('Owing');
      await makeCustomer('Settled'); // balance 0
      final wa = await AutoReminderService.dueWhatsApp();
      final sms = await AutoReminderService.dueSms();
      expect(wa.map((d) => d.customer.id), [owingId]);
      expect(wa.single.balancePaisa, 150000);
      expect(sms.map((d) => d.customer.id), [owingId]);
    });

    test('markSent(whatsapp) clears only the whatsapp queue', () async {
      final id = await owingCustomer('Owing');
      await AutoReminderService.markSent(id, 'whatsapp', 150000);
      expect(await AutoReminderService.dueWhatsApp(), isEmpty);
      expect((await AutoReminderService.dueSms()).length, 1);
    });

    test('sms cadence in DB: 6-day-old log not due, 7-day-old log due',
        () async {
      final id = await owingCustomer('Owing');
      await AutoReminderService.markSent(id, 'sms', 150000);
      expect(await AutoReminderService.dueSms(), isEmpty);

      final db = await DatabaseHelper.instance.database;
      final sixDaysAgo = DateTime.now()
          .subtract(const Duration(days: 6))
          .millisecondsSinceEpoch;
      await db.update('reminder_auto_log', {'sent_at': sixDaysAgo});
      expect(await AutoReminderService.dueSms(), isEmpty);

      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      await db.update('reminder_auto_log', {'sent_at': sevenDaysAgo});
      expect((await AutoReminderService.dueSms()).length, 1);
    });

    test('foreground catch-up with both cadences off sends nothing',
        () async {
      SharedPreferences.setMockInitialValues({});
      await owingCustomer('Owing', phone: '03001234567');
      final result = await AutoReminderService.runForegroundCatchUp();
      expect(result, {'smsSent': 0, 'smsFailed': 0, 'whatsappPending': 0});
      // Still due afterwards — nothing was attempted or stamped.
      expect((await AutoReminderService.dueSms()).length, 1);
    });

    test(
        'sms enabled but channel unavailable: counted failed, '
        'never falsely stamped', () async {
      SharedPreferences.setMockInitialValues({});
      await AutoReminderSettings.save(const AutoReminderSettings(
          whatsappDaily: true, smsWeekly: true));
      await owingCustomer('Owing', phone: '03001234567');
      // In the test environment the namt_oil_mil/sms MethodChannel does
      // not exist (same situation as the WorkManager background
      // isolate): sendDirect fails, so the customer must stay due.
      final result = await AutoReminderService.runForegroundCatchUp();
      expect(result['smsSent'], 0);
      expect(result['smsFailed'], 1);
      expect(result['whatsappPending'], 1);
      expect((await AutoReminderService.dueSms()).length, 1);
      final db = await DatabaseHelper.instance.database;
      final logs = await db.query('reminder_auto_log');
      expect(logs, isEmpty);
    });
  });
}
