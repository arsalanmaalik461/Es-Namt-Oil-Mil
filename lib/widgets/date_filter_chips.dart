import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Quick date-range filter used above transaction/report lists.
enum DateFilter { today, week, month, all }

/// Horizontal scrollable chips: Today / This week / This month / All.
class DateFilterChips extends StatelessWidget {
  final DateFilter selected;
  final ValueChanged<DateFilter> onSelected;

  const DateFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <DateFilter, String>{
      DateFilter.today: l10n.dateFilter_today,
      DateFilter.week: l10n.dateFilter_week,
      DateFilter.month: l10n.dateFilter_month,
      DateFilter.all: l10n.dateFilter_all,
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
