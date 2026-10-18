import 'package:flutter/material.dart';

/// Centered loading indicator with an optional localized message.
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton rows for list loading: soft placeholder bars that gently pulse
/// via [AnimatedOpacity] (no shimmer package — 100% offline friendly).
/// Use where a spinner feels heavy, e.g. above the khata party list.
class ListShimmer extends StatefulWidget {
  /// Number of skeleton rows to render.
  final int itemCount;

  /// Vertical gap between rows.
  final double spacing;

  const ListShimmer({super.key, this.itemCount = 5, this.spacing = 10});

  @override
  State<ListShimmer> createState() => _ListShimmerState();
}

class _ListShimmerState extends State<ListShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => AnimatedOpacity(
        // Gentle pulse between 45% and 100% opacity.
        opacity: 0.45 + 0.55 * _pulse.value,
        duration: const Duration(milliseconds: 120),
        child: child,
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.itemCount; i++) ...[
            if (i > 0) SizedBox(height: widget.spacing),
            _ShimmerRow(color: barColor),
          ],
        ],
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final Color color;
  const _ShimmerRow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
