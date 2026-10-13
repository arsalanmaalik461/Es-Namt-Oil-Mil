import 'package:flutter/material.dart';

import 'party_ledger_screen.dart';

/// Customer ledger (`/customer-ledger`, args: customer id).
class CustomerLedgerScreen extends StatelessWidget {
  const CustomerLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    return PartyLedgerView(partyId: id, isCustomer: true);
  }
}
