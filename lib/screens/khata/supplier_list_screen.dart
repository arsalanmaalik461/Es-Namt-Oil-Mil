import 'package:flutter/material.dart';

import 'party_form_sheet.dart';
import 'party_list_screen.dart';

/// Supplier list (`/suppliers`).
///
/// Optional route arguments: `{'pick': true}` for supplier-picker mode
/// (pops with the chosen [Supplier]), `{'new': true}` to open the create
/// sheet immediately.
class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, Object?>?;
    return PartyListView(
      kind: PartyKind.supplier,
      pickMode: args?['pick'] == true,
      openNewOnStart: args?['new'] == true,
    );
  }
}
