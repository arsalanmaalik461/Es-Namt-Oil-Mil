import 'package:flutter/material.dart';

/// Calculator-style number pad in the v2 entry screens.
///
/// Layout mirrors the reference flow: `C ÷ × ⌫` / `7 8 9 −` / `4 5 6 +` /
/// `1 2 3` / `0 00 . =`. Every keypress re-evaluates the expression and
/// reports the numeric [onValue]; `=` finalises the current total.
class CalculatorPad extends StatefulWidget {
  final void Function(double value) onValue;

  const CalculatorPad({super.key, required this.onValue});

  @override
  State<CalculatorPad> createState() => CalculatorPadState();
}

class CalculatorPadState extends State<CalculatorPad> {
  String _expr = '';

  /// Current evaluated value (0 when the expression is empty/invalid).
  double get value => _evaluate(_expr);

  /// Display text for the amount field.
  String get display => _expr.isEmpty ? '0' : _expr;

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
        case '=':
          final v = _evaluate(_expr);
          _expr = _formatNumber(v);
        case '00':
          if (_expr.isNotEmpty) _expr += '00';
        case '.':
          if (_canAppendDot()) _expr += '.';
        case '+':
        case '−':
        case '×':
        case '÷':
          if (_expr.isEmpty) {
            if (key == '−') _expr = '−'; // allow negative start
          } else if (_isOperator(_expr[_expr.length - 1])) {
            _expr = _expr.substring(0, _expr.length - 1) + key;
          } else {
            _expr += key;
          }
        default: // digits
          _expr += key;
      }
    });
    widget.onValue(value);
  }

  bool _isOperator(String ch) => '+-−×÷'.contains(ch);

  bool _canAppendDot() {
    // Only one dot per number segment.
    var i = _expr.length - 1;
    while (i >= 0 && !_isOperator(_expr[i])) {
      if (_expr[i] == '.') return false;
      i--;
    }
    // Don't start a segment with a bare dot.
    if (_expr.isEmpty || _isOperator(_expr[_expr.length - 1])) {
      _expr += '0';
    }
    return true;
  }

  /// Evaluates with × ÷ before + −. Trailing operators are ignored.
  static double _evaluate(String expr) {
    if (expr.isEmpty) return 0;
    var e = expr;
    while (e.isNotEmpty && '+-−×÷'.contains(e[e.length - 1])) {
      e = e.substring(0, e.length - 1);
    }
    if (e.isEmpty || e == '−') return 0;
    try {
      final tokens = <String>[];
      final buf = StringBuffer();
      for (var i = 0; i < e.length; i++) {
        final ch = e[i];
        if ('+-−×÷'.contains(ch) && !(ch == '−' && buf.isEmpty)) {
          if (buf.isNotEmpty) {
            tokens.add(buf.toString());
            buf.clear();
          }
          tokens.add(ch);
        } else {
          buf.write(ch == '−' ? '-' : ch);
        }
      }
      if (buf.isNotEmpty) tokens.add(buf.toString());

      // First pass: × ÷
      final reduced = <String>[];
      var i = 0;
      while (i < tokens.length) {
        final t = tokens[i];
        if ((t == '×' || t == '÷') && reduced.isNotEmpty && i + 1 < tokens.length) {
          final left = double.parse(reduced.removeLast());
          final right = double.parse(tokens[i + 1]);
          final res = t == '×' ? left * right : (right == 0 ? 0 : left / right);
          reduced.add(res.toString());
          i += 2;
        } else {
          reduced.add(t);
          i++;
        }
      }
      // Second pass: + −
      var result = double.parse(reduced[0]);
      i = 1;
      while (i < reduced.length) {
        final op = reduced[i];
        final next = double.parse(reduced[i + 1]);
        result = op == '+' ? result + next : result - next;
        i += 2;
      }
      return result;
    } catch (_) {
      return 0;
    }
  }

  static String _formatNumber(double v) {
    if (v == v.truncateToDouble()) return v.truncate().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyStyle = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w500);
    final opBg = scheme.surfaceContainerHighest;

    Widget key(String label,
        {Color? bg, Color? fg, double fontSize = 26, int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: bg ?? scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _press(label),
              child: SizedBox(
                height: 58,
                child: Center(
                  child: label == '⌫'
                      ? Icon(Icons.backspace_outlined,
                          color: fg ?? scheme.onSurface)
                      : Text(
                          label,
                          style: keyStyle?.copyWith(
                            fontSize: fontSize,
                            color: fg ?? scheme.onSurface,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final opFg = scheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            display,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
            textAlign: TextAlign.end,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            key('C', bg: opBg, fg: opFg),
            key('÷', bg: opBg, fg: opFg),
            key('×', bg: opBg, fg: opFg),
            key('⌫', bg: opBg, fg: opFg),
          ],
        ),
        Row(
          children: [
            key('7'),
            key('8'),
            key('9'),
            key('−', bg: opBg, fg: opFg),
          ],
        ),
        Row(
          children: [
            key('4'),
            key('5'),
            key('6'),
            key('+', bg: opBg, fg: opFg),
          ],
        ),
        Row(
          children: [
            key('1'),
            key('2'),
            key('3'),
            key('=', bg: scheme.primary, fg: scheme.onPrimary),
          ],
        ),
        Row(
          children: [
            key('0'),
            key('00', fontSize: 22),
            key('.', fontSize: 30),
          ],
        ),
      ],
    );
  }
}
