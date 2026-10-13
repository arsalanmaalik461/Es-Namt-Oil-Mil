import 'package:flutter/material.dart';

import 'party_ledger_screen.dart';

/// Supplier ledger (`/supplier-ledger`, args: supplier id).
class SupplierLedgerScreen extends StatelessWidget {
  const SupplierLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    return PartyLedgerView(partyId: id, isCustomer: false);
  }
}
