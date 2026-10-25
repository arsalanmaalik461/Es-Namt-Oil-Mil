import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:namt_oil_mil/db/database.dart';
import 'package:namt_oil_mil/models/product.dart';
import 'package:namt_oil_mil/repositories/unit_repository.dart';
import 'package:namt_oil_mil/screens/khata/khata_providers.dart';
import 'package:namt_oil_mil/services/accounting_service.dart';

import '../helpers/test_db.dart';

/// Regression tests for the khata hub TOTAL BALANCE cards.
///
/// The hub used to sum only customers with balance > 0 as "receivable"
/// and only suppliers with balance > 0 as "payable", so a customer the
/// business owed money to (negative balance — overpayment or a purchase
/// FROM the customer) and a supplier holding an advance (negative
/// balance) vanished from both cards, which showed Rs 0.00 / Rs 0.00.
void main() {
  setUpAll(initFfiDatabase);

  late AccountingService accounting;
  late ProviderContainer container;

  setUp(() async {
    accounting = await freshAccountingService();
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('pure sign split across both party types', () {
    final s = aggregateOutstandingBalances(
      customerBalancesPaisa: const [100, -50, 0],
      supplierBalancesPaisa: const [200, -70, 0],
    );
    // Receivable: customer +100, supplier advance |-70|.
    expect(s.receivablePaisa, 170);
    expect(s.receivableCount, 2);
    // Payable: supplier +200, customer |-50|.
    expect(s.payablePaisa, 250);
    expect(s.payableCount, 2);
  });

  test(
      'hub totals include a negative-balance customer and an '
      'advance-paid supplier', () async {
    final cashId = await seededCashAccountId();
    final db = await DatabaseHelper.instance.database;
    final kgId = (await UnitRepository(db).getBySymbol('kg'))!.id!;
    final seedId =
        await makeProduct('Summary Seed', ProductCategory.rawMaterial);

    // Customer who owes the business Rs 5,000 -> receivable side.
    final owingCustomer = await makeCustomer('Owes Us');
    await accounting.postCustomerUdhaar(
      customerId: owingCustomer,
      accountId: cashId,
      amountPaisa: 500000,
      date: DateTime(2026, 10, 25),
    );

    // Customer the business bought seed from: their balance is
    // -Rs 12,000 (business owes THEM) -> payable side. This is the case
    // that used to vanish and leave the hub at Rs 0.00.
    final sellerCustomer = await makeCustomer('Sold To Us');
    await accounting.postPurchaseFromCustomer(
      customerId: sellerCustomer,
      date: DateTime(2026, 10, 25),
      lines: [
        PurchaseLineInput(
            productId: seedId, qty: 80, unitId: kgId, unitPricePaisa: 15000),
      ],
    );
    expect(await accounting.getCustomerBalancePaisa(sellerCustomer), -1200000);

    // Supplier the business owes Rs 8,000 for a credit purchase ->
    // payable side.
    final owedSupplier = await makeSupplier('We Owe');
    await accounting.postPurchase(
      supplierId: owedSupplier,
      date: DateTime(2026, 10, 25),
      lines: [
        PurchaseLineInput(
            productId: seedId, qty: 40, unitId: kgId, unitPricePaisa: 20000),
      ],
    );
    expect(await accounting.getSupplierBalancePaisa(owedSupplier), 800000);

    // Supplier paid a Rs 3,000 advance: their balance is -300000 (they
    // owe the business) -> receivable side. Also used to vanish.
    final advanceSupplier = await makeSupplier('Advance Paid');
    await accounting.postSupplierPayment(
      supplierId: advanceSupplier,
      accountId: cashId,
      amountPaisa: 300000,
      date: DateTime(2026, 10, 25),
    );
    expect(await accounting.getSupplierBalancePaisa(advanceSupplier), -300000);

    final summary = await container.read(khataSummaryProvider.future);
    expect(summary.receivablePaisa, 500000 + 300000);
    expect(summary.receivableCount, 2);
    expect(summary.payablePaisa, 1200000 + 800000);
    expect(summary.payableCount, 2);
  });
}
