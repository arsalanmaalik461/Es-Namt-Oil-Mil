import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/production_batch.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/screens/production/production_batch_form_screen.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Read-only detail of one production batch: inputs, outputs, wastage,
/// yield % and the cost breakdown.
class ProductionBatchDetailScreen extends ConsumerStatefulWidget {
  final int batchId;

  const ProductionBatchDetailScreen({super.key, required this.batchId});

  @override
  ConsumerState<ProductionBatchDetailScreen> createState() =>
      _ProductionBatchDetailScreenState();
}

class _DetailData {
  final ProductionBatch batch;
  final List<ProductionInput> inputs;
  final List<ProductionOutput> outputs;
  final Map<int, Product> products;
  final Map<int, Unit> units;
  final String? wastage;
  final String? notes;

  const _DetailData({
    required this.batch,
    required this.inputs,
    required this.outputs,
    required this.products,
    required this.units,
    this.wastage,
    this.notes,
  });
}

class _ProductionBatchDetailScreenState
    extends ConsumerState<ProductionBatchDetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final repo = await ref.read(productionRepositoryProvider.future);
    final products = await ref.read(productRepositoryProvider.future);
    final units = await ref.read(unitRepositoryProvider.future);
    final batch = await repo.getBatch(widget.batchId);
    if (batch == null) throw ValidationException('error.database');
    final inputs = await repo.getInputs(widget.batchId);
    final outputs = await repo.getOutputs(widget.batchId);
    final allProducts = await products.getAll();
    final allUnits = await units.getAll();

    String? wastage;
    String? notes = batch.notes;
    if (notes != null) {
      final lines = notes.split('\n');
      final rest = <String>[];
      for (final line in lines) {
        if (line.trim().startsWith(wastageNotePrefix)) {
          wastage = line.trim().substring(wastageNotePrefix.length).trim();
        } else {
          rest.add(line);
        }
      }
      notes = rest.join('\n').trim().isEmpty ? null : rest.join('\n').trim();
    }

    return _DetailData(
      batch: batch,
      inputs: inputs,
      outputs: outputs,
      products: {for (final p in allProducts) p.id!: p},
      units: {for (final u in allUnits) u.id!: u},
      wastage: wastage?.isEmpty == true ? null : wastage,
      notes: notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.production_title)),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError || snapshot.data == null) {
            final err = snapshot.error;
            return ErrorState(
              message: err is AppException
                  ? errorText(context, err)
                  : l10n.error_generic,
              onRetry: () => Navigator.of(context).pop(),
            );
          }
          return _buildBody(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, _DetailData data) {
    final l10n = AppLocalizations.of(context);
    final b = data.batch;
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(b.batchNo,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Chip(
                        label: Text(
                          b.yieldPct == null
                              ? '—'
                              : '${l10n.production_yield}: '
                                  '${formatQty(b.yieldPct!)}%',
                          textDirection: TextDirection.ltr,
                        ),
                        backgroundColor: scheme.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(b.date),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (data.wastage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.production_wastage}: ${data.wastage}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (data.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(data.notes!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ),
        SectionHeader(title: l10n.production_inputs),
        ...data.inputs.map((i) {
          final p = data.products[i.productId];
          final symbol = data.units[i.unitId]?.symbol ?? '';
          return ListTile(
            leading: const Icon(Icons.input_outlined),
            title: Text(p?.name ?? '#${i.productId}'),
            trailing: Text(
              '${formatQty(i.qty)} $symbol',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }),
        SectionHeader(title: l10n.production_outputs),
        ...data.outputs.map((o) {
          final p = data.products[o.productId];
          final symbol = data.units[o.unitId]?.symbol ?? '';
          return ListTile(
            leading: const Icon(Icons.output_outlined),
            title: Text(p?.name ?? '#${o.productId}'),
            subtitle: Text(outputTypeLabel(l10n, o.outputType)),
            trailing: Text(
              '${formatQty(o.qty)} $symbol',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }),
        SectionHeader(title: l10n.production_costBreakdown),
        _CostRow(l10n.production_labourCost, b.labourCostPaisa),
        _CostRow(l10n.production_electricityCost, b.electricityCostPaisa),
        _CostRow(l10n.production_otherCost, b.otherCostPaisa),
        const Divider(indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.production_totalCost,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              AmountText(
                  paisa: b.cashCostPaisa,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final int paisa;

  const _CostRow(this.label, this.paisa);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AmountText(
              paisa: paisa, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
