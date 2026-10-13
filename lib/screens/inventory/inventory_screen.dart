import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/models/unit.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/db_providers.dart';
import 'package:namt_oil_mil/screens/e_labels.dart';
import 'package:namt_oil_mil/screens/inventory/product_form_screen.dart';
import 'package:namt_oil_mil/screens/inventory/units_screen.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/utils/qty.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';

/// Inventory home: category tabs, product rows with stock + low-stock badge,
/// search, FAB -> product form, and an entry point to the Units screen.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryData {
  final List<Product> products;
  final Map<int, Unit> units;

  const _InventoryData(this.products, this.units);
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late Future<_InventoryData> _future;
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0; // 0 = all, 1..n = ProductCategory.values index + 1

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_InventoryData> _load() async {
    final products = await ref.read(productRepositoryProvider.future);
    final units = await ref.read(unitRepositoryProvider.future);
    final list = await products.getAll();
    final allUnits = await units.getAll();
    return _InventoryData(list, {for (final u in allUnits) u.id!: u});
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  List<Product> _filtered(List<Product> products) {
    var list = products;
    if (_tab > 0) {
      final cat = ProductCategory.values[_tab - 1];
      list = list.where((p) => p.category == cat).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_query) ||
              (p.sku ?? '').toLowerCase().contains(_query))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.scale_outlined),
            tooltip: l10n.inventory_units,
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const UnitsScreen()),
                )
                .then((_) => _refresh()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (saved == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: AppSearchBar(
              controller: _searchController,
              hint: l10n.inventory_searchHint,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          _CategoryTabs(
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: FutureBuilder<_InventoryData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error!;
                  return ErrorState(
                    message: err is AppException
                        ? errorText(context, err)
                        : l10n.error_generic,
                    onRetry: _refresh,
                  );
                }
                final data = snapshot.data!;
                final list = _filtered(data.products);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.inventory_noProducts,
                    message: l10n.inventory_noProductsHint,
                    actionLabel: l10n.inventory_addProduct,
                    onAction: () async {
                      final saved = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => const ProductFormScreen()),
                      );
                      if (saved == true) _refresh();
                    },
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final p = list[index];
                    final unit = data.units[p.baseUnitId];
                    final symbol = unit?.symbol ?? '';
                    final lowStock = p.reorderLevelQty > 0 &&
                        p.stockQty <= p.reorderLevelQty;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.6),
                        child: Icon(
                          _categoryIcon(p.category),
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${formatQty(p.stockQty)} $symbol'
                        '${p.sku == null || p.sku!.isEmpty ? '' : ' • ${p.sku}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: lowStock
                          ? Chip(
                              label: Text(
                                l10n.inventory_lowStock,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.errorContainer,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routes.productDetail, arguments: p.id)
                          .then((_) => _refresh()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(ProductCategory c) {
  return switch (c) {
    ProductCategory.rawMaterial => Icons.grain,
    ProductCategory.finishedOil => Icons.oil_barrel_outlined,
    ProductCategory.oilCake => Icons.layers_outlined,
    ProductCategory.packaging => Icons.inventory_outlined,
    ProductCategory.container => Icons.archive_outlined,
    ProductCategory.spare => Icons.build_outlined,
    ProductCategory.consumable => Icons.shopping_basket_outlined,
  };
}

class _CategoryTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _CategoryTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      l10n.inventory_all,
      for (final c in ProductCategory.values) productCategoryLabel(l10n, c),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(labels[i]),
                selected: selected == i,
                onSelected: (_) => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}
