import 'package:flutter/material.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';
import 'package:namt_oil_mil/utils/money.dart';

/// Displays a money amount stored as integer paisa.
///
/// [positive] controls the color: `true` -> green (credit/advance),
/// `false` -> red (debit/udhaar), `null` -> default on-surface color.
class AmountText extends StatelessWidget {
  final int paisa;
  final bool? positive;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.paisa,
    this.positive,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (positive) {
      true => isDark ? AppColors.creditOnDark : AppColors.credit,
      false => isDark ? AppColors.debitOnDark : AppColors.debit,
      null => null,
    };
    // Amounts must NEVER wrap mid-number or ellipsize on narrow phones:
    // render on one line and scale down to fit the available width.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        formatPkr(paisa),
        style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
