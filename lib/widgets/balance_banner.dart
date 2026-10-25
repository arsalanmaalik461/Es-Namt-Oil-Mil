import 'package:flutter/material.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';

/// Pink/green balance banner in the v2 style:
/// "Rs 442,800  Maine lene hain" with a circular arrow icon.
///
/// [isReceivable] picks the pink (money to receive) vs green
/// (money to pay) treatment. Pass [neutral] for the
/// "Hisaab clear hai" zero state.
class BalanceBanner extends StatelessWidget {
  final String amountText;
  final String caption;
  final bool isReceivable;
  final bool neutral;

  const BalanceBanner({
    super.key,
    required this.amountText,
    required this.caption,
    required this.isReceivable,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    if (neutral) {
      bg = Theme.of(context).colorScheme.surfaceContainerHighest;
      fg = Theme.of(context).colorScheme.onSurfaceVariant;
      icon = Icons.check_circle_outline;
    } else if (isReceivable) {
      bg = AppColors.pastelPink;
      fg = AppColors.pastelPinkText;
      icon = Icons.arrow_downward;
    } else {
      bg = AppColors.pastelGreen;
      fg = AppColors.pastelGreenText;
      icon = Icons.arrow_upward;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: neutral ? fg.withValues(alpha: 0.15) : fg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: neutral ? fg : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Amount + caption stay on one line; scale down rather than
            // wrap the amount mid-number on narrow phones.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$amountText  ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: caption,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                textDirection: TextDirection.ltr,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
