import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';

/// "More" hub: entry points to every module. Every tile navigates via a
/// named route from [Routes] — no dead tiles.
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_MoreItem>[
      _MoreItem(l10n.more_sales, Icons.point_of_sale, Routes.sales),
      _MoreItem(l10n.more_purchases, Icons.shopping_bag, Routes.purchases),
      _MoreItem(l10n.more_inventory, Icons.inventory_2, Routes.inventory),
      _MoreItem(l10n.more_production, Icons.factory, Routes.production),
      _MoreItem(
          l10n.more_cashbook, Icons.account_balance_wallet, Routes.cashbook),
      _MoreItem(l10n.more_expensesIncome, Icons.receipt_long, Routes.expenses),
      _MoreItem(l10n.more_backup, Icons.backup, Routes.backup),
      _MoreItem(l10n.more_settings, Icons.settings, Routes.settings),
      _MoreItem(l10n.more_about, Icons.info_outline, Routes.about),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nav_more)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final item = items[index];
          final scheme = Theme.of(context).colorScheme;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.6),
              child: Icon(item.icon, color: scheme.onPrimaryContainer),
            ),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, item.route),
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final String label;
  final IconData icon;
  final String route;

  const _MoreItem(this.label, this.icon, this.route);
}
