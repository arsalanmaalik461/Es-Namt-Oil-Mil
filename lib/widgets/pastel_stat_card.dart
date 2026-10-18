import 'package:flutter/material.dart';

/// Pastel stat card in the v2 "soft khata" style: a light pastel tile with
/// a small uppercase label, a large value, and a muted sub-label.
class PastelStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color background;
  final Color valueColor;
  final VoidCallback? onTap;

  const PastelStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.background,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 6),
          Text(
            '— $sublabel',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}
