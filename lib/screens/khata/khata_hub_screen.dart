import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';
import 'package:namt_oil_mil/widgets/summary_card.dart';
import 'khata_providers.dart';

/// Khata hub: outstanding receivable / payable summary plus entry points
/// into the customer and supplier ledgers.
class KhataHubScreen extends ConsumerWidget {
  const KhataHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = FragmentStrings.of(context);
    final summaryAsync = ref.watch(khataSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.khata_title)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(khataSummaryProvider);
          await ref.read(khataSummaryProvider.future);
        },
        child: summaryAsync.when(
          data: (summary) => _buildBody(context, summary),
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message: l10n.error_generic,
            onRetry: () => ref.invalidate(khataSummaryProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, KhataSummary summary) {
    final t = FragmentStrings.of(context);
    final hasDues = summary.receivablePaisa > 0 || summary.payablePaisa > 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(title: t.khata_title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth > 420;
              final cards = [
                SummaryCard(
                  label: t.khata_toReceive,
                  paisa: summary.receivablePaisa,
                  icon: Icons.arrow_downward,
                  positive: true,
                  onTap: () => Navigator.pushNamed(context, Routes.customers),
                ),
                SummaryCard(
                  label: t.khata_toPay,
                  paisa: summary.payablePaisa,
                  icon: Icons.arrow_upward,
                  positive: false,
                  onTap: () => Navigator.pushNamed(context, Routes.suppliers),
                ),
              ];
              if (twoCol) {
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                );
              }
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                ],
              );
            },
          ),
        ),
        if (!hasDues)
          Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.check_circle_outline,
              title: t.khata_noDues,
              message: t.khata_noDuesHint,
            ),
          ),
        SectionHeader(title: t.khata_title),
        _HubTile(
          icon: Icons.people_outline,
          title: t.khata_customers,
          trailing: Text('${summary.receivableCount}'),
          onTap: () => Navigator.pushNamed(context, Routes.customers),
        ),
        _HubTile(
          icon: Icons.local_shipping_outlined,
          title: t.khata_suppliers,
          trailing: Text('${summary.payableCount}'),
          onTap: () => Navigator.pushNamed(context, Routes.suppliers),
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
