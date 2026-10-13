import 'package:flutter/material.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';

/// Generic transaction row: leading icon, title, subtitle, amount, tap.
class TxnRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int? paisa;
  final bool? positive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TxnRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.paisa,
    this.positive,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.6),
        child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
      trailing: trailing ??
          (paisa == null
              ? null
              : AmountText(
                  paisa: paisa!,
                  positive: positive,
                  style: Theme.of(context).textTheme.titleSmall,
                )),
    );
  }
}
