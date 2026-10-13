import 'package:flutter/widgets.dart';

import 'package:namt_oil_mil/core/app_exception.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';

/// Translates an [AppException]'s [AppException.messageKey] into a
/// human-readable, localised message.
///
/// Known `error.*` keys (the full set thrown by the data layer, see
/// `docs/API.md`) map to the khata fragment strings (Agent C owns these;
/// they merge into the ARB at release time). Anything unmapped — including
/// future keys added by other modules — falls back to
/// [AppLocalizations.error_generic], which is the only `error_*` key in the
/// base ARB today.
///
/// Never show `exception.toString()` to users; always go through this.
String errorText(BuildContext context, AppException e) {
  final t = FragmentStrings.of(context);
  switch (e.messageKey) {
    case 'error.database':
      return t.khata_errorDatabase;
    case 'error.insufficientStock':
      return t.khata_errorInsufficientStock(
        product: e.params['product'] ?? '',
      );
    case 'error.noConversion':
      return t.khata_errorNoConversion;
    case 'error.overAllocated':
      return t.khata_errorOverAllocated;
    case 'error.overAllocatedInvoice':
      return t.khata_errorOverAllocatedInvoice;
    case 'error.alreadyReversed':
      return t.khata_errorAlreadyReversed;
    case 'error.customerNotFound':
      return t.khata_errorCustomerNotFound;
    case 'error.supplierNotFound':
      return t.khata_errorSupplierNotFound;
    case 'error.productNotFound':
      return t.khata_errorProductNotFound;
    case 'error.accountNotFound':
      return t.khata_errorAccountNotFound;
    case 'error.invalidQty':
      return t.khata_errorInvalidQty;
    case 'error.invalidAmount':
      return t.khata_errorInvalidAmount;
    case 'error.negativeTotal':
      return t.khata_errorNegativeTotal;
    case 'error.emptyInvoice':
      return t.khata_errorEmptyInvoice;
    case 'error.reasonRequired':
      return t.khata_errorReasonRequired;
    case 'error.returnExceedsSold':
      return t.khata_errorReturnExceedsSold;
    case 'error.returnExceedsBought':
      return t.khata_errorReturnExceedsBought;
    case 'error.transferSameAccount':
      return t.khata_errorTransferSameAccount;
    case 'error.methodAccountMismatch':
      return t.khata_errorMethodAccountMismatch;
    case 'error.unbalancedJournal':
      return t.khata_errorUnbalancedJournal;
    case 'error.notADraft':
      return t.khata_errorNotADraft;
    case 'error.invoiceNotFound':
      return t.khata_errorInvoiceNotFound;
    case 'error.unitNotFound':
      return t.khata_errorUnitNotFound;
    case 'error.negativePrice':
      return t.khata_errorNegativePrice;
    case 'error.productArchived':
      return t.khata_errorProductArchived;
    case 'error.customerArchived':
      return t.khata_errorCustomerArchived;
    case 'error.supplierArchived':
      return t.khata_errorSupplierArchived;
    case 'error.negativeTax':
      return t.khata_errorNegativeTax;
    case 'error.emptyReturn':
      return t.khata_errorEmptyReturn;
    case 'error.emptyBatchInputs':
      return t.khata_errorEmptyBatchInputs;
    case 'error.emptyBatchOutputs':
      return t.khata_errorEmptyBatchOutputs;
    case 'error.negativeCost':
      return t.khata_errorNegativeCost;
    case 'error.oilCostAllocation':
      return t.khata_errorOilCostAllocation;
    case 'error.invalidJournalLine':
      return t.khata_errorInvalidJournalLine;
    case 'error.emptyJournal':
      return t.khata_errorEmptyJournal;
    case 'error.entryNotFound':
      return t.khata_errorEntryNotFound;
    case 'error.categoryNotFound':
      return t.khata_errorCategoryNotFound;
    case 'error.categoryInactive':
      return t.khata_errorCategoryInactive;
    case 'error.accountInactive':
      return t.khata_errorAccountInactive;
    default:
      return AppLocalizations.of(context).error_generic;
  }
}
