import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/production/production_batch_form_screen.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';

/// Production batches: batch no., date, input summary, yield %, status.
/// FAB opens the batch form.
class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _BatchRow {
  final ProductionBatch batch;
  final int inputCount;

  const _BatchRow(this.batch, this.inputCount);
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  late Future<List<_BatchRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_BatchRow>> _load() async {
    final repo = await ref.read(productionRepositoryProvider.future);
    final batches = await repo.list(limit: 200);
    final rows = <_BatchRow>[];
    for (final b in batches) {
      final inputs = await repo.getInputs(b.id!);
      rows.add(_BatchRow(b, inputs.length));
    }
    return rows;
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.production_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (_) => const ProductionBatchFormScreen()),
          );
          if (posted == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.production_newBatch),
      ),
      body: FutureBuilder<List<_BatchRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            return ErrorState(
              message: err is AppException
                  ? errorText(context, err)
                  : l10n.error_generic,
              onRetry: _refresh,
            );
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.factory_outlined,
              title: l10n.production_noBatches,
              message: l10n.production_noBatchesHint,
              actionLabel: l10n.production_newBatch,
              onAction: () async {
                final posted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => const ProductionBatchFormScreen()),
                );
                if (posted == true) _refresh();
              },
            );
          }
          final dateFormat = DateFormat.yMMMd(l10n.localeName);
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final row = rows[index];
              final b = row.batch;
              final costsPosted = b.journalKey != null;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.6),
                  child: Icon(
                    Icons.factory_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(b.batchNo,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${dateFormat.format(b.date)} • '
                  '${l10n.production_inputsCount(row.inputCount.toString())} • '
                  '${formatPkr(b.cashCostPaisa)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      b.yieldPct == null ? '—' : '${formatQty(b.yieldPct!)}%',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      costsPosted
                          ? l10n.production_statusCostsPosted
                          : l10n.production_statusPosted,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.productionBatchDetail,
                  arguments: b.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
