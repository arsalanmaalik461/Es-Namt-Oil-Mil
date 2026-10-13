import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
// NOTE (Module A contract): the four screens below are built by other
// agents in Wave 2. These imports are contractual — the project fully
// compiles once Wave 2 lands. Do NOT change these import paths.
import 'package:namt_oil_mil/screens/dashboard/dashboard_screen.dart';
import 'package:namt_oil_mil/screens/khata/khata_hub_screen.dart';
import 'package:namt_oil_mil/screens/more/more_hub_screen.dart';
import 'package:namt_oil_mil/screens/reports/reports_hub_screen.dart';
import 'package:namt_oil_mil/screens/transactions/transaction_center_screen.dart';

/// Responsive root shell.
///
/// * width < 900  -> [NavigationBar] with 5 destinations
/// * width >= 900 -> [NavigationRail]
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    KhataHubScreen(),
    TransactionCenterScreen(),
    ReportsHubScreen(),
    MoreHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.nav_home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.book_outlined),
        selectedIcon: const Icon(Icons.book),
        label: l10n.nav_khata,
      ),
      NavigationDestination(
        icon: const Icon(Icons.swap_horiz_outlined),
        selectedIcon: const Icon(Icons.swap_horiz),
        label: l10n.nav_transactions,
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart),
        label: l10n.nav_reports,
      ),
      NavigationDestination(
        icon: const Icon(Icons.more_horiz_outlined),
        selectedIcon: const Icon(Icons.more_horiz),
        label: l10n.nav_more,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final body = IndexedStack(index: _index, children: _pages);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
