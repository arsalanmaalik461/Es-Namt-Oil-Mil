/// Quantity display formatting (Module E).
///
/// Quantities are doubles in their own unit (never money). This helper
/// renders them compactly: `40.0` -> `"40"`, `40.50` -> `"40.5"`,
/// `0.333333` -> `"0.333"`.
String formatQty(double qty) {
  if (qty.isNaN || qty.isInfinite) return qty.toString();
  var s = qty.toStringAsFixed(3);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  if (s == '-0') s = '0';
  return s.isEmpty ? '0' : s;
}
