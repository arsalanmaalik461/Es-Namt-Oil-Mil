import 'package:flutter/material.dart';

import 'package:namt_oil_mil/widgets/amount_text.dart';

/// True when the user/platform asked to skip animations. All entrance and
/// count-up animations in the app bail out to their final state when this
/// is true.
bool animationsDisabled(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Fade + slight slide-up entrance for staggered screen-load reveals.
///
/// The animation runs once per screen mount (with an optional [delay]),
/// so it plays on first load but not on data refreshes. [delay] should be
/// capped for long lists (e.g. 300ms) so late items don't feel sluggish.
/// When animations are disabled the child renders immediately.
class StaggerEntrance extends StatefulWidget {
  final Widget child;

  /// Stagger delay before the entrance starts.
  final Duration delay;

  /// Length of the fade/slide itself (keep 200-350ms).
  final Duration duration;

  /// Vertical distance (logical px) the child travels while fading in.
  final double slideOffset;

  const StaggerEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.slideOffset = 12,
  });

  @override
  State<StaggerEntrance> createState() => _StaggerEntranceState();
}

class _StaggerEntranceState extends State<StaggerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(curved);
    if (animationsDisabled(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) =>
            Transform.translate(offset: _slide.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Money amount that counts up from zero when it first appears, then
/// smoothly glides between values when the amount changes (e.g. on data
/// refresh). Renders through [AmountText], so colors and tabular figures
/// stay identical to static amounts.
class AnimatedAmountText extends StatelessWidget {
  final int paisa;
  final bool? positive;
  final TextStyle? style;

  /// Length of the count-up (task spec: 600ms).
  final Duration duration;

  const AnimatedAmountText({
    super.key,
    required this.paisa,
    this.positive,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    if (animationsDisabled(context)) {
      return AmountText(paisa: paisa, positive: positive, style: style);
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: paisa),
      duration: duration,
      builder: (context, value, _) => AmountText(
        paisa: value,
        positive: positive,
        style: style,
      ),
    );
  }
}
