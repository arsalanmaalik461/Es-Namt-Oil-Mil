import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/utils/error_text.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/app_search_bar.dart';
import 'package:namt_oil_mil/widgets/empty_state.dart';
import 'package:namt_oil_mil/widgets/error_state.dart';
import 'package:namt_oil_mil/widgets/loading_state.dart';
import 'khata_providers.dart';
import 'party_form_sheet.dart';

/// Shared list UI for customers and suppliers.
///
/// * search by name / phone / code (debounced)
/// * balance filter chips: all / positive / negative
/// * rows show the cached balance via [AmountText]
/// * FAB opens the create sheet; tapping a row opens the detail screen —
///   or, in pick mode, pops the route with the chosen party.
class PartyListView extends ConsumerStatefulWidget {
  final PartyKind kind;
  final bool pickMode;
  final bool openNewOnStart;

  const PartyListView({
    super.key,
    required this.kind,
    this.pickMode = false,
    this.openNewOnStart = false,
  });

  @override
  ConsumerState<PartyListView> createState() => _PartyListViewState();
}

class _PartyListViewState extends ConsumerState<PartyListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  PartyBalanceFilter _filter = PartyBalanceFilter.all;
  bool _newOpened = false;

  bool get _isCustomer => widget.kind == PartyKind.customer;

  @override
  void initState() {
    super.initState();
    if (widget.openNewOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openForm());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _search = value.trim());
    });
  }

  PartyListQuery get _query => PartyListQuery(search: _search, filter: _filter);

  Future<void> _openForm() async {
    if (_newOpened && widget.openNewOnStart) return;
    _newOpened = true;
    final saved = await showPartyFormSheet(
      context,
      ref,
      kind: widget.kind,
    );
    if (saved && mounted) setState(() {});
  }

  void _onTapParty(int id, Object party) {
    if (widget.pickMode) {
      Navigator.of(context).pop(party);
      return;
    }
    Navigator.pushNamed(
      context,
      _isCustomer ? Routes.customerDetail : Routes.supplierDetail,
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = FragmentStrings.of(context);

    final title = widget.pickMode
        ? (_isCustomer ? t.dashboard_pickCustomer : t.dashboard_pickSupplier)
        : (_isCustomer ? t.customers_title : t.customers_supplierTitle);

    final listAsync = _isCustomer
        ? ref.watch(customerListProvider(_query))
        : ref.watch(supplierListProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: widget.pickMode
          ? null
          : FloatingActionButton(
              onPressed: _openForm,
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: AppSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: t.customers_searchHint,
            ),
          ),
          _FilterChips(
            isCustomer: _isCustomer,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: listAsync.when(
              data: (parties) => _buildList(context, parties),
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: e is AppException
                    ? errorText(context, e)
                    : l10n.error_generic,
                onRetry: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> parties) {
    final t = FragmentStrings.of(context);
    if (parties.isEmpty) {
      final isFiltering =
          _search.isNotEmpty || _filter != PartyBalanceFilter.all;
      return EmptyState(
        icon: Icons.people_outline,
        title: isFiltering
            ? t.customers_noMatch
            : (_isCustomer ? t.customers_noCustomers : t.customers_noSuppliers),
        message: isFiltering
            ? null
            : (_isCustomer
                ? t.customers_addFirstHint
                : t.customers_addFirstSupplierHint),
        actionLabel:
            isFiltering || widget.pickMode ? null : l10nActionLabel(context),
        onAction: isFiltering || widget.pickMode ? null : () => _openForm(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        itemCount: parties.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final party = parties[index];
          final name = party.name as String;
          final phone = party.phone as String?;
          final code = party.code as String?;
          final balance = party.balancePaisa as int;
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              ),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: _subtitle(phone, code),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmountText(
                  paisa: balance,
                  positive: balance == 0 ? null : balance < 0,
                ),
                if (!widget.pickMode) const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _onTapParty(party.id as int, party),
          );
        },
      ),
    );
  }

  Widget? _subtitle(String? phone, String? code) {
    final parts = [
      if (phone != null && phone.isNotEmpty) phone,
      if (code != null && code.isNotEmpty) code,
    ];
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '),
        maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  String l10nActionLabel(BuildContext context) {
    final t = FragmentStrings.of(context);
    return _isCustomer ? t.customers_addCustomer : t.customers_addSupplier;
  }
}

class _FilterChips extends StatelessWidget {
  final bool isCustomer;
  final PartyBalanceFilter selected;
  final ValueChanged<PartyBalanceFilter> onSelected;

  const _FilterChips({
    required this.isCustomer,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final options = <PartyBalanceFilter, String>{
      PartyBalanceFilter.all: t.customers_filterAll,
      PartyBalanceFilter.positive:
          isCustomer ? t.customers_filterReceivable : t.customers_filterPayable,
      PartyBalanceFilter.negative: isCustomer
          ? t.customers_filterAdvance
          : t.customers_filterAdvancePaid,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: options.entries.map((entry) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
