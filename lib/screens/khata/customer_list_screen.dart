import 'package:flutter/material.dart';

import 'party_form_sheet.dart';
import 'party_list_screen.dart';

/// Customer list (`/customers`).
///
/// Optional route arguments: `{'pick': true}` for customer-picker mode
/// (pops with the chosen [Customer]), `{'new': true}` to open the create
/// sheet immediately.
class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, Object?>?;
    return PartyListView(
      kind: PartyKind.customer,
      pickMode: args?['pick'] == true,
      openNewOnStart: args?['new'] == true,
    );
  }
}
