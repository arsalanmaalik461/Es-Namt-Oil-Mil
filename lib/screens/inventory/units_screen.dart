import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/models/unit_conversion.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'package:namt_oil_mil/widgets/section_header.dart';

/// Units & conversions: lists all units and their conversion factors.
/// Factors are user-editable (validated > 0); new conversions can be added.
/// Conversions are data — never hardcoded (e.g. maund = 40 kg is only the
/// seeded default and stays editable here).
class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key});

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsData {
  final List<Unit> units;
  final List<UnitConversion> conversions;

  const _UnitsData(this.units, this.conversions);
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  late Future<_UnitsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_UnitsData> _load() async {
    final units = await ref.read(unitRepositoryProvider.future);
    return _UnitsData(await units.getAll(), await units.listConversions());
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventory_units)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await _showConversionDialog(context, null);
          if (added == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_UnitsData>(
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
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          final byId = {for (final u in data.units) u.id!: u};
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              SectionHeader(title: l10n.inventory_unitsTitle),
              ...data.units.map((u) => ListTile(
                    leading: const Icon(Icons.scale_outlined),
                    title: Text(u.name),
                    subtitle: Text(u.symbol),
                  )),
              SectionHeader(
                title: l10n.inventory_conversionsTitle,
                action: TextButton.icon(
                  onPressed: () async {
                    final added = await _showConversionDialog(context, null);
                    if (added == true) _refresh();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.inventory_addConversion),
                ),
              ),
              if (data.conversions.isEmpty)
                EmptyState(
                  icon: Icons.compare_arrows,
                  message: l10n.inventory_noConversions,
                )
              else
                ...data.conversions.map((c) {
                  final from = byId[c.fromUnitId];
                  final to = byId[c.toUnitId];
                  return ListTile(
                    leading: const Icon(Icons.compare_arrows),
                    title: Text(
                      '1 ${from?.symbol ?? '?'} = '
                      '${formatQty(c.factor)} ${to?.symbol ?? '?'}',
                      textDirection: TextDirection.ltr,
                    ),
                    subtitle: Text('${from?.name ?? ''} → ${to?.name ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.inventory_editConversion,
                      onPressed: () async {
                        final saved = await _showConversionDialog(
                            context, _EditTarget(c, data.units));
                        if (saved == true) _refresh();
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  /// Shows the add/edit conversion dialog. Returns true when saved.
  Future<bool?> _showConversionDialog(
      BuildContext context, _EditTarget? target) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConversionDialog(target: target, ref: ref),
    );
  }
}

class _EditTarget {
  final UnitConversion conversion;
  final List<Unit> units;

  const _EditTarget(this.conversion, this.units);
}

class _ConversionDialog extends ConsumerStatefulWidget {
  final _EditTarget? target;
  final WidgetRef ref;

  const _ConversionDialog({required this.target, required this.ref});

  @override
  ConsumerState<_ConversionDialog> createState() => _ConversionDialogState();
}

class _ConversionDialogState extends ConsumerState<_ConversionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _factor = TextEditingController();
  late Future<List<Unit>> _unitsFuture;
  int? _fromId;
  int? _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.target;
    if (t != null) {
      _fromId = t.conversion.fromUnitId;
      _toId = t.conversion.toUnitId;
      _factor.text = t.conversion.factor.toString();
      _unitsFuture = Future.value(t.units);
    } else {
      _unitsFuture = widget.ref
          .read(unitRepositoryProvider.future)
          .then((r) => r.getAll());
    }
  }

  @override
  void dispose() {
    _factor.dispose();
    super.dispose();
  }

  Future<void> _save(List<Unit> units) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null || _fromId == _toId) return;
    setState(() => _saving = true);
    try {
      final repo = await widget.ref.read(unitRepositoryProvider.future);
      final factor = double.parse(_factor.text.trim());
      final existing = widget.target?.conversion;
      if (existing?.id != null) {
        // No update API on the repository (CRUD-only): replace the row.
        await repo.deleteConversion(existing!.id!);
      }
      await repo.insertConversion(UnitConversion(
        fromUnitId: _fromId!,
        toUnitId: _toId!,
        factor: factor,
      ));
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      var message = errorText(context, e);
      if (e.messageKey == 'error.database') {
        // Most likely a UNIQUE(from,to) clash -> friendlier message.
        message = l10n.inventory_conversionExists;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.target != null;
    return AlertDialog(
      title: Text(isEdit
          ? l10n.inventory_editConversion
          : l10n.inventory_addConversion),
      content: FutureBuilder<List<Unit>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
                height: 120, child: Center(child: LoadingState()));
          }
          final units = snapshot.data!;
          final fromUnit = units.where((u) => u.id == _fromId).firstOrNull;
          final toUnit = units.where((u) => u.id == _toId).firstOrNull;
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _fromId,
                        decoration:
                            InputDecoration(labelText: l10n.inventory_from),
                        onChanged:
                            isEdit ? null : (v) => setState(() => _fromId = v),
                        items: [
                          for (final u in units)
                            DropdownMenuItem(
                                value: u.id, child: Text(u.symbol)),
                        ],
                        validator: (v) => v == null ? l10n.val_required : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 18),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _toId,
                        decoration:
                            InputDecoration(labelText: l10n.inventory_to),
                        onChanged:
                            isEdit ? null : (v) => setState(() => _toId = v),
                        items: [
                          for (final u in units)
                            DropdownMenuItem(
                                value: u.id, child: Text(u.symbol)),
                        ],
                        validator: (v) {
                          if (v == null) return l10n.val_required;
                          if (v == _fromId) return l10n.val_required;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField.numeric(
                  controller: _factor,
                  label: l10n.inventory_factor,
                  hint: l10n.inventory_factorHint(
                    fromUnit?.symbol ?? '–',
                    toUnit?.symbol ?? '–',
                  ),
                  autofocus: true,
                  validator: (v) {
                    final f = double.tryParse((v ?? '').trim());
                    if (f == null || f <= 0) {
                      return l10n.inventory_factorPositive;
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final units = await _unitsFuture;
                  await _save(units);
                },
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.common_save),
        ),
      ],
    );
  }
}
