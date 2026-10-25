import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/utils/money.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';

/// One row of a party ledger: description, date, debit/credit amount and the
/// running balance after this entry.
class LedgerRow extends StatelessWidget {
  final String title;
  final String dateLabel;
  final int paisa;

  /// `true` when the entry increases what the party owes us (shown red),
  /// `false` when it is a payment/advance (shown green).
  final bool isDebit;
  final int? runningBalancePaisa;
  final VoidCallback? onTap;

  const LedgerRow({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.paisa,
    required this.isDebit,
    this.runningBalancePaisa,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isDebit
            ? scheme.error.withValues(alpha: 0.12)
            : scheme.primary.withValues(alpha: 0.12),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebit ? scheme.error : scheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        dateLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AmountText(
            paisa: paisa,
            positive: !isDebit,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (runningBalancePaisa != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${l10n.common_balance}: ${formatPkr(runningBalancePaisa!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textDirection: TextDirection.ltr,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }
}
