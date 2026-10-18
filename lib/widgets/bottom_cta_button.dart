import 'package:flutter/material.dart';

/// Near-black full-width call-to-action button in the v2 style
/// (e.g. "Sale darj karein", "Add customer").
///
/// Adds press-scale feedback: the button shrinks to 0.96 while pressed and
/// springs back on release.
class BottomCtaButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const BottomCtaButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  State<BottomCtaButton> createState() => _BottomCtaButtonState();
}

class _BottomCtaButtonState extends State<BottomCtaButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onPressed == null ? null : (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: animate && _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B1B1B),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFF1B1B1B).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 22),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
