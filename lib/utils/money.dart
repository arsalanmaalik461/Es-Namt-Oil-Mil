import 'package:intl/intl.dart' hide TextDirection;

/// ---------------------------------------------------------------------------
/// MONEY CONTRACT — READ THIS FIRST
///
/// Money is ALWAYS an integer number of **paisa** (1 PKR = 100 paisa) in the
/// database, in every domain model, and in every service/repository signature.
///
/// * NEVER use double/float for money. Not for storage, not for arithmetic,
///   not "temporarily".
/// * Quantities (kg, litres, bags, ...) are doubles in their own unit — money
///   math must round back to integer paisa at every step.
/// * Percentage math (discount, tax) uses integer arithmetic with
///   **half-up** rounding (0.5 rounds away from zero).
///
/// Agent A: this file is the exact contract you import for money handling.
/// ---------------------------------------------------------------------------

/// Paisa per Pakistani Rupee.
const int paisaPerRupee = 100;

final NumberFormat _pkrFormat = NumberFormat('#,##0.00', 'en');

/// Formats integer paisa as e.g. `Rs 1,250.50`.
///
/// `formatPkr(125050)` → `"Rs 1,250.50"`
/// `formatPkr(-500)` → `"Rs -5.00"`
/// `formatPkr(0)` → `"Rs 0.00"`
String formatPkr(int paisa) {
  final rupees = paisa / paisaPerRupee;
  return 'Rs ${_pkrFormat.format(rupees)}';
}

/// Parses user input like `"1250"`, `"1,250.50"` or `"Rs 1,250.50"` into paisa.
///
/// Extra decimal places are rounded half-up to the nearest paisa, computed
/// on the decimal string itself (never through `double`, so `"1.005"`
/// really becomes 101 paisa instead of falling victim to binary-float
/// representation). Throws [FormatException] on invalid input.
int parsePkrToPaisa(String input) {
  var s = input.trim();
  // Strip an optional leading "Rs" (any case) then grouping separators.
  s = s.replaceFirst(RegExp(r'^[Rr][Ss]\s*'), '');
  s = s.replaceAll(RegExp(r'[,\s]'), '');
  if (s.isEmpty || !RegExp(r'^-?\d*\.?\d+$').hasMatch(s)) {
    throw FormatException('Invalid amount: "$input"');
  }
  var negative = false;
  if (s.startsWith('-')) {
    negative = true;
    s = s.substring(1);
  }
  final parts = s.split('.');
  final whole = parts[0].isEmpty ? '0' : parts[0];
  // Take three fractional digits: two for paisa, the third decides half-up.
  final frac = (parts.length > 1 ? parts[1] : '').padRight(3, '0');
  var paisa =
      int.parse(whole) * paisaPerRupee + int.parse(frac.substring(0, 2));
  if (int.parse(frac[2]) >= 5) paisa += 1;
  return negative ? -paisa : paisa;
}

/// Returns [percent]% of [amountPaisa], rounded half-up to the nearest paisa.
///
/// Implemented in integer arithmetic via basis points:
///   result = round_half_up(amountPaisa * percent / 100)
int percentOf(int amountPaisa, num percent) {
  // Convert percent to integer basis points (7.5% -> 750 bps), rounded.
  final basisPoints = (percent * 100).round();
  final product = amountPaisa * basisPoints; // exact integer
  // Half-up: add half the divisor (5000) with the sign of the product,
  // then truncate toward zero.
  final adjusted = product >= 0 ? product + halfDivisor : product - halfDivisor;
  return adjusted ~/ 10000;
}

/// Half of the basis-point divisor (10000), used for half-up rounding.
const int halfDivisor = 5000;

/// Applies a percentage discount: `amountPaisa - percentOf(amountPaisa, discountPercent)`.
int applyDiscount(int amountPaisa, num discountPercent) {
  return amountPaisa - percentOf(amountPaisa, discountPercent);
}

/// Line total for an invoice/return line, in paisa.
///
/// `qty` may be fractional (e.g. 12.5 kg); the discounted extended price is
/// rounded half-up to the nearest paisa.
int lineTotalPaisa({
  required int unitPricePaisa,
  required double qty,
  num discountPercent = 0,
}) {
  final clamped = discountPercent.clamp(0, 100);
  final basisPoints = (clamped * 100).round(); // 0..10000
  final value = qty * unitPricePaisa * (10000 - basisPoints) / 10000;
  return value.round();
}

/// Weighted moving-average unit cost after a purchase, in paisa.
///
/// `oldQtyBase` / `addedQtyBase` are quantities in the product's base unit.
/// `addedValuePaisa` is the total purchase value of the added quantity.
/// Rounded half-up. If the resulting stock is zero/negative, keeps [oldAvgCostPaisa].
int weightedAverageCostPaisa({
  required double oldQtyBase,
  required int oldAvgCostPaisa,
  required double addedQtyBase,
  required int addedValuePaisa,
}) {
  final newQty = oldQtyBase + addedQtyBase;
  if (newQty <= 0) return oldAvgCostPaisa;
  final totalValue = oldQtyBase * oldAvgCostPaisa + addedValuePaisa;
  return (totalValue / newQty).round();
}
