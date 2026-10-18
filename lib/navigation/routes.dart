import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/app_shell.dart';
// Agent E screens (inventory / production / cashbook / expenses).
import 'package:namt_oil_mil/screens/cashbook/cashbook_screen.dart';
import 'package:namt_oil_mil/screens/dashboard/dashboard_screen.dart';
import 'package:namt_oil_mil/screens/expenses/expenses_screen.dart';
import 'package:namt_oil_mil/screens/inventory/inventory_screen.dart';
import 'package:namt_oil_mil/screens/inventory/product_detail_screen.dart';
import 'package:namt_oil_mil/screens/inventory/units_screen.dart';
import 'package:namt_oil_mil/screens/khata/customer_detail_screen.dart';
import 'package:namt_oil_mil/screens/khata/customer_ledger_screen.dart';
import 'package:namt_oil_mil/screens/khata/customer_list_screen.dart';
import 'package:namt_oil_mil/screens/khata/supplier_detail_screen.dart';
import 'package:namt_oil_mil/screens/khata/supplier_ledger_screen.dart';
import 'package:namt_oil_mil/screens/khata/supplier_list_screen.dart';
import 'package:namt_oil_mil/screens/more/backup_screen.dart';
import 'package:namt_oil_mil/screens/more/more_hub_screen.dart';
import 'package:namt_oil_mil/screens/reminders/reminders_screen.dart';
import 'package:namt_oil_mil/screens/production/production_batch_detail_screen.dart';
import 'package:namt_oil_mil/screens/production/production_screen.dart';
import 'package:namt_oil_mil/screens/purchases/purchase_detail_screen.dart';
import 'package:namt_oil_mil/screens/purchases/purchase_list_screen.dart';
import 'package:namt_oil_mil/screens/reports/report_detail_screen.dart';
import 'package:namt_oil_mil/screens/reports/reports_hub_screen.dart';
import 'package:namt_oil_mil/screens/sales/sale_detail_screen.dart';
import 'package:namt_oil_mil/screens/sales/sales_list_screen.dart';
import 'package:namt_oil_mil/screens/settings/about_screen.dart';
import 'package:namt_oil_mil/screens/settings/settings_screen.dart';
import 'package:namt_oil_mil/screens/transactions/transaction_center_screen.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';

// ===========================================================================
// ROUTE MAP — who owns what (Wave 2 agents paste their cases into the
// marked insertion sections below; do NOT edit other agents' sections).
//
// Route                       Owner    Screen class               File
// --------------------------- -------- -------------------------- ----------------------------------------------
// /                           A        AppShell                   lib/navigation/app_shell.dart
// /dashboard                  C/D      DashboardScreen            lib/screens/dashboard/dashboard_screen.dart
// /customers                  C        CustomerListScreen         lib/screens/khata/customer_list_screen.dart *
// /customer-detail            C        CustomerDetailScreen       lib/screens/khata/customer_detail_screen.dart *
// /customer-ledger            C        CustomerLedgerScreen       lib/screens/khata/customer_ledger_screen.dart *
// /suppliers                  C        SupplierListScreen         lib/screens/khata/supplier_list_screen.dart *
// /supplier-detail            C        SupplierDetailScreen       lib/screens/khata/supplier_detail_screen.dart *
// /supplier-ledger            C        SupplierLedgerScreen       lib/screens/khata/supplier_ledger_screen.dart *
// /transactions               D        TransactionCenterScreen    lib/screens/transactions/transaction_center_screen.dart
// /sales                      D        SalesListScreen            lib/screens/sales/sales_list_screen.dart *
// /sale-detail                D        SaleDetailScreen           lib/screens/sales/sale_detail_screen.dart *
// /purchases                  D        PurchaseListScreen         lib/screens/purchases/purchase_list_screen.dart *
// /purchase-detail            D        PurchaseDetailScreen       lib/screens/purchases/purchase_detail_screen.dart *
// /inventory                  E        InventoryScreen            lib/screens/inventory/inventory_screen.dart *
// /product-detail             E        ProductDetailScreen        lib/screens/inventory/product_detail_screen.dart *
// /production                 E        ProductionScreen           lib/screens/production/production_screen.dart *
// /production-batch-detail    E        ProductionBatchDetailScreen lib/screens/production/production_batch_detail_screen.dart *
// /cashbook                   E        CashbookScreen             lib/screens/cashbook/cashbook_screen.dart *
// /expenses                   E        ExpensesScreen             lib/screens/expenses/expenses_screen.dart *
// /reports                    F        ReportsHubScreen           lib/screens/reports/reports_hub_screen.dart
// /report-detail              F        ReportDetailScreen         lib/screens/reports/report_detail_screen.dart *
// /backup                     F        BackupScreen               lib/screens/more/backup_screen.dart *
// /settings                   A        SettingsScreen             lib/screens/settings/settings_screen.dart
// /about                      A        AboutScreen                lib/screens/settings/about_screen.dart
// /more                       A        MoreHubScreen              lib/screens/more/more_hub_screen.dart
//   * exact screen class/file names are suggestions — the owning agent decides,
//     but the ROUTE NAME must stay as listed here.
// ===========================================================================

/// Central route name constants. Always navigate with these, never raw
/// strings, e.g. `Navigator.pushNamed(context, Routes.customers)`.
class Routes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String customerDetail = '/customer-detail';
  static const String customerLedger = '/customer-ledger';
  static const String suppliers = '/suppliers';
  static const String supplierDetail = '/supplier-detail';
  static const String supplierLedger = '/supplier-ledger';
  static const String transactions = '/transactions';
  static const String sales = '/sales';
  static const String saleDetail = '/sale-detail';
  static const String purchases = '/purchases';
  static const String purchaseDetail = '/purchase-detail';
  static const String inventory = '/inventory';
  static const String productDetail = '/product-detail';
  static const String units = '/units';
  static const String production = '/production';
  static const String productionBatchDetail = '/production-batch-detail';
  static const String cashbook = '/cashbook';
  static const String expenses = '/expenses';
  static const String reports = '/reports';
  static const String reportDetail = '/report-detail';
  static const String backup = '/backup';
  static const String reminders = '/reminders';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String more = '/more';

  const Routes._();
}

/// Builds routes for [MaterialApp.onGenerateRoute].
class RouteRegistry {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case Routes.home:
        page = const AppShell();
      case Routes.settings:
        page = const SettingsScreen();
      case Routes.about:
        page = const AboutScreen();
      case Routes.more:
        page = const MoreHubScreen();

      // ===== AGENT C ROUTES — paste below this line =====
      // [C-ROUTES]
      // Khata module: /dashboard, /customers, /customer-detail,
      // /customer-ledger, /suppliers, /supplier-detail, /supplier-ledger
      case Routes.dashboard:
        page = const DashboardScreen();
      case Routes.customers:
        page = const CustomerListScreen();
      case Routes.customerDetail:
        page = const CustomerDetailScreen();
      case Routes.customerLedger:
        page = const CustomerLedgerScreen();
      case Routes.suppliers:
        page = const SupplierListScreen();
      case Routes.supplierDetail:
        page = const SupplierDetailScreen();
      case Routes.supplierLedger:
        page = const SupplierLedgerScreen();

      // ===== AGENT D ROUTES — paste below this line =====
      // [D-ROUTES]
      // Transactions module: /transactions, /sales, /sale-detail,
      // /purchases, /purchase-detail
      case Routes.transactions:
        page = const TransactionCenterScreen();
      case Routes.sales:
        page = const SalesListScreen();
      case Routes.saleDetail:
        final saleId = settings.arguments as int?;
        page = saleId == null
            ? _UnknownRouteScreen(routeName: settings.name)
            : SaleDetailScreen(id: saleId);
      case Routes.purchases:
        page = const PurchaseListScreen();
      case Routes.purchaseDetail:
        final purchaseId = settings.arguments as int?;
        page = purchaseId == null
            ? _UnknownRouteScreen(routeName: settings.name)
            : PurchaseDetailScreen(id: purchaseId);

      // ===== AGENT E ROUTES — paste below this line =====
      // [E-ROUTES]
      // Inventory/production/cashbook module: /inventory, /product-detail,
      // /units, /production, /production-batch-detail, /cashbook, /expenses
      case Routes.inventory:
        page = const InventoryScreen();
      case Routes.productDetail:
        page = settings.arguments is int
            ? ProductDetailScreen(productId: settings.arguments as int)
            : const _MissingArgScreen();
      case Routes.units:
        page = const UnitsScreen();
      case Routes.production:
        page = const ProductionScreen();
      case Routes.productionBatchDetail:
        page = settings.arguments is int
            ? ProductionBatchDetailScreen(batchId: settings.arguments as int)
            : const _MissingArgScreen();
      case Routes.cashbook:
        page = const CashbookScreen();
      case Routes.expenses:
        page = const ExpensesScreen();

      // ===== AGENT F ROUTES — paste below this line =====      // [F-ROUTES]
      // Reports/backup module: /reports, /report-detail, /backup
      case Routes.reports:
        page = const ReportsHubScreen();
      case Routes.reportDetail:
        final args = settings.arguments;
        page = ReportDetailScreen(
          args: args is Map<String, dynamic> ? args : const {},
        );
      case Routes.backup:
        page = const BackupScreen();
      case Routes.reminders:
        page = const RemindersScreen();

      default:
        page = _UnknownRouteScreen(routeName: settings.name);
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  const RouteRegistry._();
}

/// Agent E: shown when /product-detail or /production-batch-detail is pushed
/// without an int id argument. Never crashes — renders a normal scaffold.
class _MissingArgScreen extends StatelessWidget {
  const _MissingArgScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ErrorState(
        message: l10n.error_generic,
        onRetry: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Temporary placeholder shown for routes whose screens are built by other
/// agents in Wave 2. Never crashes — renders a normal scaffold.
class Wave2PlaceholderScreen extends StatelessWidget {
  final String routeName;

  const Wave2PlaceholderScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: ErrorState(
        message: 'Coming soon: $routeName',
        onRetry: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  final String? routeName;

  const _UnknownRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ErrorState(
        message: l10n.error_generic,
        onRetry: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}
