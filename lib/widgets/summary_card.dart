import 'package:flutter/material.dart';
import 'package:namt_oil_mil/widgets/amount_text.dart';
import 'package:namt_oil_mil/widgets/entrance_animation.dart';

/// KPI-style card: icon + label + big amount, optionally tappable.
///
/// Set [animateAmount] to count the amount up on first appearance
/// (dashboard usage); leave it off elsewhere so values render instantly.
class SummaryCard extends StatelessWidget {
  final String label;
  final int paisa;
  final IconData icon;
  final bool? positive;
  final VoidCallback? onTap;
  final bool animateAmount;

  const SummaryCard({
    super.key,
    required this.label,
    required this.paisa,
    required this.icon,
    this.positive,
    this.onTap,
    this.animateAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        // Narrow grid cells (2-up KPI grids on 360px phones leave ~160px
        // per card): shrink the icon, padding and text so labels like
        // "Receivables" never break mid-word and amounts keep one line.
        final compact = constraints.maxWidth < 220;
        final iconSize = compact ? 38.0 : 48.0;
        return Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: scheme.onPrimaryContainer, size: compact ? 20 : 24),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: (compact
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodyMedium)
                          ?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    animateAmount
                        ? AnimatedAmountText(
                            paisa: paisa,
                            positive: positive,
                            style: compact
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleLarge,
                          )
                        : AmountText(
                            paisa: paisa,
                            positive: positive,
                            style: compact
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleLarge,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    return Card(
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: content,
            ),
    );
  }
}
