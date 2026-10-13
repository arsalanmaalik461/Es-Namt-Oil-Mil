import 'package:flutter_test/flutter_test.dart';
import 'package:namt_oil_mil/utils/money.dart';

void main() {
  group('formatPkr', () {
    test('formats paisa as Rs with grouping and two decimals', () {
      expect(formatPkr(125050), 'Rs 1,250.50');
      expect(formatPkr(0), 'Rs 0.00');
      expect(formatPkr(1), 'Rs 0.01');
      expect(formatPkr(100), 'Rs 1.00');
      expect(formatPkr(-500), 'Rs -5.00');
      expect(formatPkr(123456789), 'Rs 1,234,567.89');
    });
  });

  group('parsePkrToPaisa', () {
    test('parses plain, grouped and Rs-prefixed input', () {
      expect(parsePkrToPaisa('1250'), 125000);
      expect(parsePkrToPaisa('1,250.50'), 125050);
      expect(parsePkrToPaisa('Rs 1,250.50'), 125050);
      expect(parsePkrToPaisa('rs 5'), 500);
      expect(parsePkrToPaisa('0.01'), 1);
    });

    test('rounds extra decimals half-up to the nearest paisa', () {
      expect(parsePkrToPaisa('1.005'), 101); // 100.5 -> 101
      expect(parsePkrToPaisa('1.004'), 100);
    });

    test('throws FormatException on invalid input', () {
      expect(() => parsePkrToPaisa(''), throwsFormatException);
      expect(() => parsePkrToPaisa('abc'), throwsFormatException);
      expect(() => parsePkrToPaisa('12.34.56'), throwsFormatException);
      expect(() => parsePkrToPaisa('Rs'), throwsFormatException);
    });
  });

  group('percentOf (half-up)', () {
    test('exact percentages', () {
      expect(percentOf(10000, 10), 1000);
      expect(percentOf(10000, 0), 0);
      expect(percentOf(10000, 100), 10000);
    });

    test('rounds half-up away from zero', () {
      // 10% of 5 paisa = 0.5 paisa -> rounds to 1.
      expect(percentOf(5, 10), 1);
      // 10% of 15 paisa = 1.5 -> 2.
      expect(percentOf(15, 10), 2);
      // 10% of -5 paisa = -0.5 -> -1 (away from zero).
      expect(percentOf(-5, 10), -1);
    });

    test('fractional percents use integer basis-point math', () {
      // 7.5% of 10000 = 750.
      expect(percentOf(10000, 7.5), 750);
      // 2.5% of 999 = 24.975 -> 25.
      expect(percentOf(999, 2.5), 25);
    });
  });

  group('applyDiscount', () {
    test('subtracts the percentage discount', () {
      expect(applyDiscount(10000, 10), 9000);
      expect(applyDiscount(10000, 0), 10000);
      expect(applyDiscount(999, 2.5), 999 - 25);
    });
  });

  group('lineTotalPaisa', () {
    test('qty * unit price with optional line discount', () {
      expect(
        lineTotalPaisa(unitPricePaisa: 45000, qty: 2),
        90000,
      );
      expect(
        lineTotalPaisa(unitPricePaisa: 45000, qty: 2, discountPercent: 10),
        81000,
      );
    });

    test('fractional qty rounds half-up to the nearest paisa', () {
      // 12.5 kg @ Rs 450 = Rs 5625 exactly.
      expect(
        lineTotalPaisa(unitPricePaisa: 45000, qty: 12.5),
        562500,
      );
      // 1/3 unit @ 100 paisa = 33.33 -> 33.
      expect(
        lineTotalPaisa(unitPricePaisa: 100, qty: 1 / 3),
        33,
      );
    });

    test('discount percent is clamped to 0..100', () {
      expect(
        lineTotalPaisa(unitPricePaisa: 100, qty: 1, discountPercent: 150),
        0,
      );
      expect(
        lineTotalPaisa(unitPricePaisa: 100, qty: 1, discountPercent: -10),
        100,
      );
    });
  });

  group('weightedAverageCostPaisa', () {
    test('blends old stock value with the added purchase value', () {
      // 10 kg @ 400 + 10 kg @ 600 -> 500 avg.
      expect(
        weightedAverageCostPaisa(
          oldQtyBase: 10,
          oldAvgCostPaisa: 40000,
          addedQtyBase: 10,
          addedValuePaisa: 600000,
        ),
        50000,
      );
    });

    test('first-ever stock takes the purchase cost', () {
      expect(
        weightedAverageCostPaisa(
          oldQtyBase: 0,
          oldAvgCostPaisa: 0,
          addedQtyBase: 5,
          addedValuePaisa: 250000,
        ),
        50000,
      );
    });

    test('rounds half-up', () {
      // (0*0 + 100) / 3 = 33.33 -> 33.
      expect(
        weightedAverageCostPaisa(
          oldQtyBase: 0,
          oldAvgCostPaisa: 0,
          addedQtyBase: 3,
          addedValuePaisa: 100,
        ),
        33,
      );
      // (0*0 + 200) / 3 = 66.67 -> 67.
      expect(
        weightedAverageCostPaisa(
          oldQtyBase: 0,
          oldAvgCostPaisa: 0,
          addedQtyBase: 3,
          addedValuePaisa: 200,
        ),
        67,
      );
    });

    test('keeps the old average when resulting stock is zero/negative', () {
      expect(
        weightedAverageCostPaisa(
          oldQtyBase: 10,
          oldAvgCostPaisa: 40000,
          addedQtyBase: -10,
          addedValuePaisa: 0,
        ),
        40000,
      );
    });
  });
}
