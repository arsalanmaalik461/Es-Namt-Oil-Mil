import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/repositories/customer_repository.dart';
import 'package:namt_oil_mil/services/reminder_service.dart';
import 'package:namt_oil_mil/services/reminder_texts.dart';
import 'package:namt_oil_mil/services/sms_service.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';

/// Payment reminders (route: /reminders).
///
/// Lists customers with overdue khata balances, sorted by nearest due date.
/// Each row offers one-tap SMS / WhatsApp reminders using the ready-made
/// templates (EN / UR / Roman-Urdu) — the user can edit the text before
/// sending.
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
    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: t.reminders_emptyTitle,
        message: t.reminders_emptyMessage,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => _ReminderTile(
          row: rows[i],
          isOverdue: _filter == 0,
          onSent: _load,
        ),
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

class _ReminderTile extends StatelessWidget {
  final _ReminderRow row;
  final bool isOverdue;
  final VoidCallback onSent;

  const _ReminderTile({
    required this.row,
    required this.isOverdue,
    required this.onSent,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _sendSms(context, t),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: t.reminders_sendWhatsapp,
            onPressed: () => _sendWhatsapp(context, t),
          ),
        ],
      ),
    );
  }

  String _message(FragmentStrings t, String script) {
    if (isOverdue) {
      switch (script) {
        case 'ur':
          return buildOverdueReminderUr(
              partyName: row.name,
              balancePaisa: row.overduePaisa,
              daysOverdue: row.daysOverdue);
        case 'en':
          return buildOverdueReminderEn(
              partyName: row.name,
              balancePaisa: row.overduePaisa,
              daysOverdue: row.daysOverdue);
        case 'roman':
        default:
          return buildOverdueReminderRomanUrdu(
              partyName: row.name,
              balancePaisa: row.overduePaisa,
              daysOverdue: row.daysOverdue);
      }
    }
    switch (script) {
      case 'ur':
        return buildReminderUr(
            partyName: row.name, balancePaisa: row.overduePaisa);
      case 'en':
        return buildReminderEn(
            partyName: row.name, balancePaisa: row.overduePaisa);
      case 'roman':
      default:
        return buildReminderRomanUrdu(
            partyName: row.name, balancePaisa: row.overduePaisa);
    }
  }

  Future<void> _sendSms(BuildContext context, FragmentStrings t) async {
    if (row.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reminders_noPhone(name: row.name))),
      );
      return;
    }
    final script = await _pickScript(context, t);
    if (script == null || !context.mounted) return;
    final message = _message(t, script);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? t.reminders_sent : t.reminders_failed)));
        if (ok) onSent();
      }
    } on SmsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _sendWhatsapp(BuildContext context, FragmentStrings t) async {
    // WhatsApp deep-link is owned by Team 3's WhatsappService; until it
    // lands, share the text via the platform share sheet.
    final script = await _pickScript(context, t);
    if (script == null || !context.mounted) return;
    final message = _message(t, script);
    final edited = await _editMessage(context, t, message);
    if (edited == null || !context.mounted) return;
    // TODO(team3): replace with WhatsappService.openChatWithText once
    // lib/services/whatsapp_service.dart lands.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reminders_whatsappSoon)),
      );
    }
  }

  Future<String?> _pickScript(BuildContext context, FragmentStrings t) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t.reminders_pickScript),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'roman'),
            child: Text(t.reminders_scriptRoman),
          ),
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
