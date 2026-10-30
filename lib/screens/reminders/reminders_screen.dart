import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/screens/reports/document_data.dart';
import 'package:namt_oil_mil/screens/reports/report_definitions.dart';
import 'package:namt_oil_mil/services/auto_reminder_service.dart';
import 'package:namt_oil_mil/services/pdf/pdf_service.dart';
import 'package:namt_oil_mil/services/reminder_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/services/sms_service.dart';
import 'package:namt_oil_mil/services/whatsapp_service.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';

/// Payment reminders (route: /reminders).
///
/// Lists customers with overdue khata balances, sorted by nearest due date.
/// Each row offers one-tap SMS / WhatsApp reminders using the ready-made
/// templates (EN / UR script — Roman Urdu was removed) — the user can edit
/// the text before sending.
///
/// A reminder never goes out as bare text (user-requested 2026-10-25):
/// WhatsApp sends the customer's FULL ledger statement PDF with the text
/// via the share sheet; SMS carries a compact ledger summary in its body
/// and the full PDF is offered through the share sheet right after.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  List<_ReminderRow>? _rows;
  bool _loading = true;
  String? _error;
  int _filter = 0; // 0 = overdue, 1 = upcoming
  int _panelEpoch = 0; // bumped on pull-to-refresh to reload the auto panel

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await ref.read(databaseProvider.future);
      final summaries = _filter == 0
          ? await ReminderService.remindersSummary()
          : await _upcomingSummaries();
      final customers = CustomerRepository(db);
      final rows = <_ReminderRow>[];
      for (final s in summaries) {
        final c = await customers.getById(s.customerId);
        if (c == null) continue;
        rows.add(_ReminderRow(
          customerId: s.customerId,
          name: c.name,
          phone: c.phone ?? '',
          overduePaisa: s.overduePaisa,
          nearestDueDate: s.nearestDueDate,
          daysOverdue: s.daysOverdue,
          entryCount: s.entryCount,
        ));
      }
      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Upcoming (not yet overdue) grouped per customer.
  Future<List<CustomerReminder>> _upcomingSummaries() async {
    final entries = await ReminderService.upcomingEntries();
    final map = <int, List<int>>{};
    final dueMap = <int, DateTime>{};
    for (final e in entries) {
      map.putIfAbsent(e.accountId, () => []).add(e.debitPaisa - e.creditPaisa);
      final d = e.dueDate;
      if (d != null) {
        final cur = dueMap[e.accountId];
        if (cur == null || d.isBefore(cur)) dueMap[e.accountId] = d;
      }
    }
    final out = <CustomerReminder>[];
    map.forEach((id, amounts) {
      final total = amounts.fold(0, (a, b) => a + b);
      if (total > 0 && dueMap[id] != null) {
        out.add(CustomerReminder(
          customerId: id,
          overduePaisa: total,
          nearestDueDate: dueMap[id]!,
          entryCount: amounts.length,
        ));
      }
    });
    out.sort((a, b) => a.nearestDueDate.compareTo(b.nearestDueDate));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.reminders_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(t.reminders_overdue)),
                ButtonSegment(value: 1, label: Text(t.reminders_upcoming)),
              ],
              selected: {_filter},
              onSelectionChanged: (s) {
                setState(() => _filter = s.first);
                _load();
              },
            ),
          ),
          Expanded(child: _buildBody(t)),
        ],
      ),
    );
  }

  Widget _buildBody(FragmentStrings t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final rows = _rows ?? const <_ReminderRow>[];
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _panelEpoch++);
        await _load();
      },
      child: ListView(
        children: [
          // Automatic reminders (user-requested 2026-10-30): today's
          // prepared WhatsApp queue, automatic SMS status, and history.
          _AutoReminderPanel(key: ValueKey(_panelEpoch)),
          const Divider(height: 1),
          if (rows.isEmpty)
            SizedBox(
              height: 300,
              child: EmptyState(
                icon: Icons.notifications_none,
                title: t.reminders_emptyTitle,
                message: t.reminders_emptyMessage,
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _ReminderTile(
                row: rows[i],
                isOverdue: _filter == 0,
                onSent: _load,
              ),
            ],
        ],
      ),
    );
  }
}

class _ReminderRow {
  final int customerId;
  final String name;
  final String phone;
  final int overduePaisa;
  final DateTime nearestDueDate;
  final int daysOverdue;
  final int entryCount;
  const _ReminderRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.overduePaisa,
    required this.nearestDueDate,
    required this.daysOverdue,
    required this.entryCount,
  });
}

/// Builds the customer's FULL ledger statement PDF (every entry, not a
/// partial page): the statement builder defaults to the last 90 days, so
/// an explicit 2000→2100 window is passed (same as the customer detail
/// screen's "All" period).
Future<Uint8List> _fullStatementPdfBytes(
  WidgetRef ref,
  BuildContext context, {
  required int customerId,
  required FragmentStrings t,
}) async {
  final business = ref.read(businessProfileProvider);
  final localeCode = Localizations.localeOf(context).languageCode;
  final l10n = AppLocalizations.of(context);
  String fmt(DateTime d) => DateFormat.yMMMd(localeCode).format(d);
  final data = await buildDocumentData(
    ref: ref,
    documentType: DocumentKeys.customerStatement,
    id: customerId,
    t: t,
    business: business,
    formatDate: fmt,
    from: DateTime(2000, 1, 1),
    to: DateTime(2100, 1, 1),
  );
  return ref.read(pdfServiceProvider).buildPdf(document: data, l10n: l10n);
}

class _ReminderTile extends ConsumerWidget {
  final _ReminderRow row;
  final bool isOverdue;
  final VoidCallback onSent;

  const _ReminderTile({
    required this.row,
    required this.isOverdue,
    required this.onSent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FragmentStrings.of(context);
    final dueLabel = isOverdue
        ? t.reminders_daysOverdue(days: row.daysOverdue)
        : t.reminders_dueOn(
            date:
                '${row.nearestDueDate.day}/${row.nearestDueDate.month}/${row.nearestDueDate.year}');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOverdue
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        child: Text(
          row.name.isNotEmpty ? row.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(row.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${formatPkr(row.overduePaisa)} • $dueLabel',
        style: TextStyle(
          color: isOverdue ? Theme.of(context).colorScheme.error : null,
          fontWeight: isOverdue ? FontWeight.w600 : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: t.reminders_sendSms,
            onPressed: () => _sendSms(context, ref, t),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: t.reminders_sendWhatsapp,
            onPressed: () => _sendWhatsapp(context, ref, t),
          ),
        ],
      ),
    );
  }

  String _message(FragmentStrings t, String script) {
    // English and Urdu (script) only — Roman Urdu was removed (user
    // instruction 2026-10-25); any legacy 'roman' value falls back to the
    // Urdu-script builders.
    if (isOverdue) {
      return script == 'en'
          ? buildOverdueReminderEn(
              partyName: row.name,
              balancePaisa: row.overduePaisa,
              daysOverdue: row.daysOverdue)
          : buildOverdueReminderUr(
              partyName: row.name,
              balancePaisa: row.overduePaisa,
              daysOverdue: row.daysOverdue);
    }
    return script == 'en'
        ? buildReminderEn(partyName: row.name, balancePaisa: row.overduePaisa)
        : buildReminderUr(partyName: row.name, balancePaisa: row.overduePaisa);
  }

  Future<void> _sendSms(
      BuildContext context, WidgetRef ref, FragmentStrings t) async {
    if (row.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reminders_noPhone(name: row.name))),
      );
      return;
    }
    final script = await _pickScript(context, t);
    if (script == null || !context.mounted) return;
    // The SMS body carries the compact ledger summary (walked back from
    // the customer's CURRENT balance so the running balances are right);
    // the full statement PDF is offered right after the send.
    var balancePaisa = row.overduePaisa;
    try {
      final repo = await ref.read(customerRepositoryProvider.future);
      final customer = await repo.getById(row.customerId);
      if (customer != null) balancePaisa = customer.balancePaisa;
    } catch (_) {
      // Fall back to the overdue total if the fresh balance can't load.
    }
    if (!context.mounted) return;
    final message = await ReminderService.smsTextWithLedgerSummary(
      customerId: row.customerId,
      reminderText: _message(t, script),
      balancePaisa: balancePaisa,
      script: script,
    );
    if (!context.mounted) return;
    final edited = await _editMessage(context, t, message);
    if (edited == null || !context.mounted) return;
    try {
      // Prefer direct send; fall back to the SMS app.
      final direct = await SmsService.canSendDirect();
      bool ok;
      if (direct) {
        try {
          ok = await SmsService.sendDirect(
              phoneNumber: row.phone, message: edited);
        } on SmsException {
          ok = await SmsService.openSmsApp(
              phoneNumber: row.phone, message: edited);
        }
      } else {
        ok = await SmsService.openSmsApp(
            phoneNumber: row.phone, message: edited);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? t.reminders_sent : t.reminders_failed)));
      if (ok) {
        onSent();
        // SMS cannot attach files — offer the full ledger PDF via the
        // share sheet so the reminder still delivers the complete khata.
        await _offerStatementPdf(context, ref, t, text: edited);
      }
    } on SmsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(context, e))));
      }
    }
  }

  /// After an SMS reminder, offers the customer's FULL statement PDF and
  /// shares it through the system share sheet when accepted.
  Future<void> _offerStatementPdf(
      BuildContext context, WidgetRef ref, FragmentStrings t,
      {String? text}) async {
    final share = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.customers_statement),
        content: Text('${row.name} • ${formatPkr(row.overduePaisa)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.reminders_send),
          ),
        ],
      ),
    );
    if (share != true || !context.mounted) return;
    try {
      final bytes = await _fullStatementPdfBytes(ref, context,
          customerId: row.customerId, t: t);
      if (!context.mounted) return;
      final safeName = row.name.replaceAll(RegExp(r'[^\w\- ]'), '_');
      await SmsService.shareStatementPdf(
        pdfBytes: bytes,
        fileName: 'namt-oil-mil-statement-$safeName.pdf',
        text: text,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is AppException
              ? errorText(context, e)
              : AppLocalizations.of(context).error_generic)));
    }
  }

  Future<void> _sendWhatsapp(
      BuildContext context, WidgetRef ref, FragmentStrings t) async {
    final script = await _pickScript(context, t);
    if (script == null || !context.mounted) return;
    final message = _message(t, script);
    final edited = await _editMessage(context, t, message);
    if (edited == null || !context.mounted) return;
    try {
      // The reminder goes WITH the customer's FULL ledger statement PDF
      // (user-requested 2026-10-25): wa.me links cannot attach files, so
      // the PDF and the reminder text travel together through the share
      // sheet and the user picks the customer's WhatsApp chat.
      final bytes = await _fullStatementPdfBytes(ref, context,
          customerId: row.customerId, t: t);
      if (!context.mounted) return;
      final status =
          await ref.read(whatsAppServiceProvider).shareReminderWithStatement(
                pdfBytes: bytes,
                customerName: row.name,
                message: edited,
              );
      if (!context.mounted) return;
      if (status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.reminders_sent)));
        onSent();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is AppException
              ? errorText(context, e)
              : AppLocalizations.of(context).error_generic)));
    }
  }

  Future<String?> _pickScript(BuildContext context, FragmentStrings t) {
    // English + Urdu (script) only — the Roman Urdu option was removed
    // (user instruction 2026-10-25).
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t.reminders_pickScript),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ur'),
            child: Text(t.reminders_scriptUrdu),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: Text(t.reminders_scriptEnglish),
          ),
        ],
      ),
    );
  }

  Future<String?> _editMessage(
      BuildContext context, FragmentStrings t, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.reminders_editMessage),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t.reminders_send),
          ),
        ],
      ),
    );
  }
}

/// One row of the `reminder_auto_log` history, with the customer name
/// resolved for display.
class _AutoLogRow {
  final String customerName;
  final String channel;
  final DateTime? sentAt;
  final int balancePaisa;
  final String status;

  const _AutoLogRow({
    required this.customerName,
    required this.channel,
    required this.sentAt,
    required this.balancePaisa,
    required this.status,
  });
}

/// "Auto reminders" area at the top of the Reminders screen
/// (user-requested 2026-10-30).
///
/// * WhatsApp queue for today ([AutoReminderService.dueWhatsApp]): one
///   Send tap per customer runs the same flow as the manual tiles below —
///   the FULL ledger statement PDF plus the reminder text through the
///   share sheet — and a successful share is recorded with
///   [AutoReminderService.markSent].
/// * SMS status: how many automatic SMS are due, and when the last one
///   went (from `reminder_auto_log`).
/// * History: the newest `reminder_auto_log` entries.
///
/// Opening the screen first runs the engine's foreground catch-up so due
/// automatic SMS go out while the app is open. If both auto channels are
/// off in Settings, a short pointer to Settings is shown instead.
class _AutoReminderPanel extends ConsumerStatefulWidget {
  const _AutoReminderPanel({super.key});

  @override
  ConsumerState<_AutoReminderPanel> createState() =>
      _AutoReminderPanelState();
}

class _AutoReminderPanelState extends ConsumerState<_AutoReminderPanel> {
  bool _loading = true;
  bool _failed = false;
  AutoReminderSettings? _settings;
  List<DueReminder> _waQueue = const [];
  int _smsDueCount = 0;
  DateTime? _lastSmsAt;
  List<_AutoLogRow> _history = const [];
  final Set<int> _sending = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await AutoReminderSettings.load();
      // Foreground catch-up: due automatic SMS go out now that the app
      // is open; the lists below then reflect the fresh state.
      try {
        await AutoReminderService.runForegroundCatchUp();
      } catch (_) {
        // Best-effort only; the queue/status loads below still run.
      }
      var wa = const <DueReminder>[];
      var smsDue = 0;
      if (settings.whatsappDaily) {
        wa = await AutoReminderService.dueWhatsApp();
      }
      if (settings.smsWeekly) {
        smsDue = (await AutoReminderService.dueSms()).length;
      }
      DateTime? lastSmsAt;
      var history = const <_AutoLogRow>[];
      try {
        final db = await ref.read(databaseProvider.future);
        final lastRows = await db.query(
          'reminder_auto_log',
          where: 'channel = ?',
          whereArgs: ['sms'],
          orderBy: 'sent_at DESC',
          limit: 1,
        );
        if (lastRows.isNotEmpty) {
          lastSmsAt = _parseSentAt(lastRows.first['sent_at']);
        }
        final logRows = await db.query(
          'reminder_auto_log',
          orderBy: 'sent_at DESC',
          limit: 30,
        );
        final repo = CustomerRepository(db);
        final names = <int, String>{};
        final parsed = <_AutoLogRow>[];
        for (final r in logRows) {
          final cid = (r['customer_id'] as num?)?.toInt();
          var name = '';
          if (cid != null) {
            var cached = names[cid];
            if (cached == null) {
              cached = (await repo.getById(cid))?.name ?? '';
              names[cid] = cached;
            }
            name = cached.isEmpty ? '#$cid' : cached;
          }
          parsed.add(_AutoLogRow(
            customerName: name,
            channel: r['channel'] as String? ?? '',
            sentAt: _parseSentAt(r['sent_at']),
            balancePaisa: (r['balance_paisa'] as num?)?.toInt() ?? 0,
            status: r['status'] as String? ?? '',
          ));
        }
        history = parsed;
      } catch (_) {
        // The log table arrives with the auto-reminder engine; until
        // then the panel simply shows no history.
      }
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _waQueue = wa;
        _smsDueCount = smsDue;
        _lastSmsAt = lastSmsAt;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  /// `sent_at` is stored as epoch milliseconds; ISO text is accepted
  /// too so the history renders whichever the engine writes.
  static DateTime? _parseSentAt(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _sendWhatsApp(DueReminder due) async {
    final customer = due.customer;
    final customerId = customer.id;
    if (customerId == null || _sending.contains(customerId)) return;
    final t = FragmentStrings.of(context);
    setState(() => _sending.add(customerId));
    try {
      // Same statement + share flow as the manual reminder tiles: the
      // reminder goes WITH the customer's FULL ledger PDF, and the text
      // follows the current UI language (English / Urdu script only).
      final localeCode = Localizations.localeOf(context).languageCode;
      final message = localeCode == 'en'
          ? buildReminderEn(
              partyName: customer.name, balancePaisa: due.balancePaisa)
          : buildReminderUr(
              partyName: customer.name, balancePaisa: due.balancePaisa);
      final bytes = await _fullStatementPdfBytes(ref, context,
          customerId: customerId, t: t);
      if (!mounted) return;
      final status =
          await ref.read(whatsAppServiceProvider).shareReminderWithStatement(
                pdfBytes: bytes,
                customerName: customer.name,
                message: message,
              );
      if (!mounted) return;
      if (status == ShareResultStatus.success) {
        await AutoReminderService.markSent(
            customerId, 'whatsapp', due.balancePaisa);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.reminders_sent)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is AppException
                ? errorText(context, e)
                : AppLocalizations.of(context).error_generic)));
      }
    } finally {
      if (mounted) setState(() => _sending.remove(customerId));
    }
  }

  Widget _panelTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _queueTile(BuildContext context, FragmentStrings t, DueReminder due) {
    final customer = due.customer;
    final sending = customer.id != null && _sending.contains(customer.id);
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: AmountText(
        paisa: due.balancePaisa,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: FilledButton(
        onPressed: sending ? null : () => _sendWhatsApp(due),
        child: sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(t.reminders_send),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) return const SizedBox.shrink();
    final settings = _settings;
    if (settings == null) return const SizedBox.shrink();
    final t = FragmentStrings.of(context);
    if (!settings.whatsappDaily && !settings.smsWeekly) {
      return ListTile(
        leading: const Icon(Icons.notifications_off_outlined),
        title: Text(t.reminders_autoOffTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(t.reminders_autoOffMessage),
        trailing: TextButton(
          onPressed: () => Navigator.pushNamed(context, Routes.settings),
          child: Text(t.reminders_autoOpenSettings),
        ),
      );
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    String fmtDateTime(DateTime d) =>
        '${DateFormat.yMMMd(localeCode).format(d)} · '
        '${DateFormat.jm(localeCode).format(d)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.whatsappDaily) ...[
          _panelTitle(context, t.reminders_autoQueueTitle),
          if (_waQueue.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
              child: Text(
                t.reminders_autoQueueEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            for (final due in _waQueue) _queueTile(context, t, due),
        ],
        if (settings.smsWeekly) ...[
          _panelTitle(context, t.reminders_autoSmsWeekly),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _smsDueCount > 0
                      ? t.reminders_autoSmsDue(count: _smsDueCount)
                      : t.reminders_autoSmsNoneDue,
                ),
                const SizedBox(height: 2),
                Text(
                  _lastSmsAt != null
                      ? t.reminders_autoLastSms(
                          date: fmtDateTime(_lastSmsAt!))
                      : t.reminders_autoLastSmsNever,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (_history.isNotEmpty) ...[
          _panelTitle(context, t.reminders_autoHistoryTitle),
          for (final h in _history)
            ListTile(
              dense: true,
              leading: Icon(
                h.channel == 'sms'
                    ? Icons.sms_outlined
                    : Icons.send_outlined,
                size: 20,
              ),
              title: Text(h.customerName),
              subtitle: Text(h.sentAt == null ? '' : fmtDateTime(h.sentAt!)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    paisa: h.balancePaisa,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (h.status == 'failed')
                    Text(
                      t.reminders_autoStatusFailed,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
