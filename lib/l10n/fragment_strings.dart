// GENERATED — do not edit by hand.
// Built from lib/l10n/fragments/*_{en,ur}.json (plus the previously
// generated tables, whose source fragments were consumed earlier).
// Regenerate: python3 lib/l10n/fragments/gen_fragment_strings.py
//
// Why this file exists: fragment keys are merged into the ARB files
// by Agent A / the orchestrator at release time. Until then, module UI
// code reads its strings through this bridge so the project compiles
// with zero hardcoded UI strings. After the merge this file keeps
// working unchanged (it is self-contained).
import 'package:flutter/widgets.dart';

const Map<String, String> _fragmentEn = {
  'backup_chooseFile': 'Choose backup file',
  'backup_confirmMessage': 'All current data will be REPLACED by the backup. This cannot be undone.',
  'backup_confirmRestore': 'Restore',
  'backup_confirmTitle': 'Restore this backup?',
  'backup_create': 'Create Backup',
  'backup_created': 'Backup created — {count} records in {tables} tables.',
  'backup_creating': 'Creating backup…',
  'backup_driveAutoBackup': '24-hour auto-backup',
  'backup_driveAutoBackupHint': 'Every 24 hours, the full day\'s data is automatically uploaded to Drive.',
  'backup_driveBackupFailed': 'Backup failed: {error}',
  'backup_driveBackupNow': 'Backup now',
  'backup_driveBackupSaved': 'Backup saved to Drive: {name}',
  'backup_driveConnect': 'Connect with Google',
  'backup_driveConnectFailed': 'Could not connect to Google. Please connect from Settings first.',
  'backup_driveConnectIntro': 'Connect with Google so your data is automatically backed up to Drive.',
  'backup_driveConnected': 'Connected to Google: {email}',
  'backup_driveDisconnect': 'Disconnect',
  'backup_driveDisconnectMessage': 'Auto-backup will be turned off. Backups already saved on Drive will stay there.',
  'backup_driveDisconnectTitle': 'Disconnect Google?',
  'backup_driveExportFailed': 'Export failed: {error}',
  'backup_driveExportRange': 'Export — custom date range',
  'backup_driveExportSaved': 'Export saved to Drive: {name}',
  'backup_driveLastBackup': 'Last backup: {date}',
  'backup_driveNoBackupYet': 'No backup yet',
  'backup_driveTitle': 'Google Drive Backup',
  'backup_errorChecksum': 'Backup data is corrupted (checksum mismatch in {table}).',
  'backup_errorInvalidFile': 'This file is not a valid Namt Oil Mil backup.',
  'backup_errorMissingTables': 'Backup is missing tables: {tables}.',
  'backup_errorUnsupportedVersion': 'Unsupported backup version: {version}.',
  'backup_exportedAt': 'Exported {date}',
  'backup_intro': 'Keep a safe copy of all your data. Backups are a single JSON file stored on this device only — nothing is uploaded.',
  'backup_reading': 'Reading backup…',
  'backup_recordsCount': '{count} records',
  'backup_restore': 'Restore Backup',
  'backup_restored': 'Restore complete — {count} records restored.',
  'backup_restoring': 'Restoring…',
  'backup_savedTo': 'Saved to {path}',
  'backup_summaryTitle': 'Backup summary',
  'backup_tablesCount': '{count} tables',
  'backup_title': 'Backup & Restore',
  'cashbook_accountName': 'Account name',
  'cashbook_accountType': 'Account type',
  'cashbook_accounts': 'Accounts',
  'cashbook_addAccount': 'Add account',
  'cashbook_addPayment': 'Add payment',
  'cashbook_addReceipt': 'Add receipt',
  'cashbook_amount': 'Amount',
  'cashbook_balance': 'Balance',
  'cashbook_customer': 'Customer',
  'cashbook_date': 'Date',
  'cashbook_editAccount': 'Edit account',
  'cashbook_entries': 'Entries',
  'cashbook_errAccountNotFound': 'Account not found',
  'cashbook_errInvalidAmount': 'Enter a valid amount',
  'cashbook_errTransferSame': 'The From and To accounts must be different',
  'cashbook_from': 'From',
  'cashbook_in': 'In',
  'cashbook_method': 'Method',
  'cashbook_methodBank': 'Bank',
  'cashbook_methodCash': 'Cash',
  'cashbook_newTransfer': 'New transfer',
  'cashbook_noAccounts': 'No accounts yet',
  'cashbook_noEntries': 'No entries in this period',
  'cashbook_notes': 'Notes',
  'cashbook_openingBalance': 'Opening balance',
  'cashbook_out': 'Out',
  'cashbook_payment': 'Payment',
  'cashbook_pickAccount': 'Select account',
  'cashbook_receipt': 'Receipt',
  'cashbook_reference': 'Reference',
  'cashbook_selectCustomer': 'Select customer',
  'cashbook_selectSupplier': 'Select supplier',
  'cashbook_supplier': 'Supplier',
  'cashbook_title': 'Cashbook',
  'cashbook_to': 'To',
  'cashbook_totalIn': 'Total in',
  'cashbook_totalOut': 'Total out',
  'cashbook_transfer': 'Transfer',
  'cashbook_transferInfo': 'A transfer moves money between two accounts. It is never income or expense.',
  'cashbook_typeBank': 'Bank',
  'cashbook_typeCash': 'Cash',
  'common_cancel': 'Cancel',
  'customers_account': 'Account',
  'customers_addCustomer': 'New customer',
  'customers_addFirstHint': 'Add your first customer to track credit',
  'customers_addFirstSupplierHint': 'Add your first supplier to track purchases',
  'customers_addSupplier': 'New supplier',
  'customers_address': 'Address',
  'customers_amount': 'Amount (PKR)',
  'customers_archive': 'Archive',
  'customers_archiveMessage': 'They will be hidden from lists, but their history is kept.',
  'customers_archiveTitle': 'Archive {name}?',
  'customers_bank': 'Bank',
  'customers_businessName': 'Business name',
  'customers_cash': 'Cash',
  'customers_code': 'Code',
  'customers_copied': 'Copied to clipboard',
  'customers_copyText': 'Copy text',
  'customers_customRange': 'Custom range',
  'customers_customerArchived': 'Customer archived',
  'customers_customerRestored': 'Customer restored',
  'customers_date': 'Date',
  'customers_editCustomer': 'Edit customer',
  'customers_editSupplier': 'Edit supplier',
  'customers_englishVersion': 'English',
  'customers_filterAdvance': 'Advance',
  'customers_filterAdvancePaid': 'Advance paid',
  'customers_filterAll': 'All',
  'customers_filterPayable': 'To pay',
  'customers_filterReceivable': 'To receive',
  'customers_giveUdhaar': 'Give credit',
  'customers_ledgerTitle': 'Ledger',
  'customers_makePayment': 'Make payment',
  'customers_method': 'Method',
  'customers_name': 'Name',
  'customers_newCustomer': 'New customer',
  'customers_newSupplier': 'New supplier',
  'customers_noCustomers': 'No customers yet',
  'customers_noEntries': 'No entries in this period',
  'customers_noMatch': 'No matches found',
  'customers_noSuppliers': 'No suppliers yet',
  'customers_notFound': 'Record not found',
  'customers_note': 'Note',
  'customers_notes': 'Notes',
  'customers_openingBalance': 'Opening balance',
  'customers_openingBalanceHint': 'Optional. Amount in PKR.',
  'customers_openingBalanceLabel': 'Opening balance',
  'customers_openingHelpCustomer': 'Positive: the customer owes you. Negative: you owe the customer.',
  'customers_openingHelpSupplier': 'Positive: you owe the supplier. Negative: the supplier owes you.',
  'customers_paymentSaved': 'Payment recorded',
  'customers_paymentTitlePay': 'Make payment',
  'customers_paymentTitleReceive': 'Receive payment',
  'customers_phone': 'Phone',
  'customers_receivePayment': 'Receive payment',
  'customers_recordPurchase': 'Record purchase',
  'customers_reminder': 'Reminder',
  'customers_reminderTitle': 'Payment reminder',
  'customers_saved': 'Saved',
  'customers_searchHint': 'Search name, phone, code',
  'customers_searchLedgerHint': 'Search description',
  'customers_selectAccount': 'Select account',
  'customers_statement': 'Statement',
  'customers_supplierArchived': 'Supplier archived',
  'customers_supplierRestored': 'Supplier restored',
  'customers_supplierTitle': 'Suppliers',
  'customers_title': 'Customers',
  'customers_totalCredit': 'Total credit given',
  'customers_totalPaid': 'Total paid',
  'customers_totalPurchases': 'Total purchases',
  'customers_totalReceived': 'Total received',
  'customers_unarchive': 'Unarchive',
  'customers_urduVersion': 'Urdu',
  'customers_viewLedger': 'View ledger',
  'customers_waAdd': 'Add',
  'customers_waAddMessage': 'Save {name}\'s WhatsApp number so their account statement can be sent straight to their chat.',
  'customers_waAddTitle': 'Add WhatsApp number',
  'customers_waOpenChat': 'Open chat',
  'customers_waOpenFailed': 'WhatsApp could not be opened. Check the number or install WhatsApp.',
  'customers_waSendStatement': 'Send statement PDF',
  'customers_waSendStatementHint': 'The account statement PDF will be created and shared.',
  'customers_waStatementText': '{name} — account statement',
  'customers_whatsappNumber': 'WhatsApp number',
  'dashboard_activityExpense': 'Expense',
  'dashboard_activityIncome': 'Income',
  'dashboard_activityPaymentIn': 'Payment received',
  'dashboard_activityPaymentOut': 'Payment made',
  'dashboard_activityPurchase': 'Purchase {no}',
  'dashboard_activitySale': 'Sale {no}',
  'dashboard_bankBalance': 'Bank balance',
  'dashboard_cashInHand': 'Cash in hand',
  'dashboard_lowStock': 'Low stock alerts',
  'dashboard_lowStockOk': 'Stock levels are healthy',
  'dashboard_monthExpense': 'Expenses this month',
  'dashboard_monthIncome': 'Income this month',
  'dashboard_noActivity': 'No recent activity',
  'dashboard_noActivityHint': 'Sales, purchases and payments will appear here',
  'dashboard_paidToday': 'Paid today',
  'dashboard_pickCustomer': 'Choose customer',
  'dashboard_pickSupplier': 'Choose supplier',
  'dashboard_qaAddCustomer': 'Add customer',
  'dashboard_qaAddExpense': 'Add expense',
  'dashboard_qaAddPurchase': 'Add purchase',
  'dashboard_qaAddSale': 'Add sale',
  'dashboard_qaAddSupplier': 'Add supplier',
  'dashboard_qaGiveUdhaar': 'Give credit',
  'dashboard_qaMakePayment': 'Make payment',
  'dashboard_qaReceivePayment': 'Receive payment',
  'dashboard_qaRecordProduction': 'Record production',
  'dashboard_qaViewReports': 'View reports',
  'dashboard_quickActions': 'Quick actions',
  'dashboard_receivedToday': 'Received today',
  'dashboard_recentActivity': 'Recent activity',
  'dashboard_stockLeft': '{qty} {unit} left',
  'dashboard_thisMonth': 'This month',
  'dashboard_title': 'Dashboard',
  'dashboard_today': 'Today',
  'dashboard_todayPurchases': 'Today\'s purchases',
  'dashboard_todaySales': 'Today\'s sales',
  'dashboard_totalBalance': 'Total balance',
  'dashboard_totalPayable': 'To pay',
  'dashboard_totalReceivable': 'To receive',
  'dashboard_viewAll': 'View all',
  'expenses_account': 'Account',
  'expenses_addCategory': 'New category',
  'expenses_addExpense': 'Add expense',
  'expenses_addIncome': 'Add income',
  'expenses_amount': 'Amount',
  'expenses_category': 'Category',
  'expenses_categoryName': 'Category name',
  'expenses_categorySaved': 'Category saved',
  'expenses_date': 'Date',
  'expenses_description': 'Description',
  'expenses_errAccountNotFound': 'Account not found',
  'expenses_errCategoryNotFound': 'Category not found',
  'expenses_errInvalidAmount': 'Enter a valid amount',
  'expenses_expenseSaved': 'Expense saved',
  'expenses_incomeCategory': 'Income type (optional)',
  'expenses_incomeSaved': 'Income saved',
  'expenses_noEntries': 'No entries yet',
  'expenses_reference': 'Reference',
  'expenses_tabExpenses': 'Expenses',
  'expenses_tabIncome': 'Income',
  'expenses_thisMonth': 'This month',
  'expenses_thisYear': 'This year',
  'expenses_title': 'Expenses & income',
  'expenses_today': 'Today',
  'expenses_totalExpenses': 'Total expenses',
  'expenses_totalIncome': 'Total income',
  'inventory_addConversion': 'Add conversion',
  'inventory_addProduct': 'Add product',
  'inventory_adjust': 'Adjust stock',
  'inventory_adjustment': 'Adjustment',
  'inventory_all': 'All',
  'inventory_available': 'Available',
  'inventory_avgCost': 'Average cost',
  'inventory_catConsumable': 'Consumables',
  'inventory_catContainer': 'Containers',
  'inventory_catFinishedOil': 'Finished oil',
  'inventory_catOilCake': 'Oil cake',
  'inventory_catPackaging': 'Packaging',
  'inventory_catRawMaterial': 'Raw material',
  'inventory_catSpare': 'Spares',
  'inventory_category': 'Category',
  'inventory_conversionExists': 'A conversion for this pair already exists',
  'inventory_conversionsTitle': 'Conversions',
  'inventory_editConversion': 'Edit conversion',
  'inventory_editProduct': 'Edit product',
  'inventory_errDatabase': 'Something went wrong. Please try again.',
  'inventory_errInsufficientStock': 'Insufficient stock of {product} (available {available}, needed {needed})',
  'inventory_errInvalidAmount': 'Enter a valid amount',
  'inventory_errInvalidQty': 'Enter a valid quantity greater than zero',
  'inventory_errNoConversion': 'No conversion defined between these units',
  'inventory_errProductNotFound': 'Product not found',
  'inventory_factor': 'Factor',
  'inventory_factorHint': 'How many {to} in 1 {from}?',
  'inventory_factorPositive': 'Factor must be greater than zero',
  'inventory_from': 'From',
  'inventory_in': 'In',
  'inventory_lowStock': 'Low stock',
  'inventory_movements': 'Movement history',
  'inventory_name': 'Product name',
  'inventory_noConversions': 'No conversions defined yet',
  'inventory_noMovements': 'No movements recorded yet',
  'inventory_noProducts': 'No products found',
  'inventory_noProductsHint': 'Add your first product to start tracking stock.',
  'inventory_openingStock': 'Opening stock',
  'inventory_openingStockReason': 'Opening stock',
  'inventory_out': 'Out',
  'inventory_productSaved': 'Product saved',
  'inventory_qty': 'Quantity',
  'inventory_reason': 'Reason',
  'inventory_reasonRequired': 'Please enter a reason',
  'inventory_reorderLevel': 'Reorder level',
  'inventory_salePrice': 'Default sale price (optional)',
  'inventory_searchHint': 'Search products',
  'inventory_sku': 'SKU (optional)',
  'inventory_stock': 'Stock',
  'inventory_stockIn': 'Stock in',
  'inventory_stockInReason': 'Stock receipt',
  'inventory_stockOut': 'Stock out',
  'inventory_stockOutReason': 'Stock dispatch',
  'inventory_stockUpdated': 'Stock updated',
  'inventory_stockValue': 'Stock value',
  'inventory_title': 'Inventory',
  'inventory_to': 'To',
  'inventory_typeAdjustment': 'Adjustment',
  'inventory_typeProduction': 'Production',
  'inventory_typePurchase': 'Purchase',
  'inventory_typeReturn': 'Return',
  'inventory_typeSale': 'Sale',
  'inventory_unit': 'Unit',
  'inventory_units': 'Units & conversions',
  'inventory_unitsTitle': 'Units',
  'khata_addBills': 'Add bills',
  'khata_addCustomerBtn': 'Add customer',
  'khata_addSupplierBtn': 'Add supplier',
  'khata_balAfter': 'Bal: {amount}',
  'khata_billAttached': 'Bill image attached',
  'khata_businessName': 'Namt Oil Mil',
  'khata_camera': 'Camera',
  'khata_customerSince': 'Customer since {date}',
  'khata_customers': 'Customers',
  'khata_diye': 'GAVE',
  'khata_errorAccountInactive': 'This account is inactive.',
  'khata_errorAccountNotFound': 'Account not found.',
  'khata_errorAlreadyReversed': 'This entry has already been reversed.',
  'khata_errorCategoryInactive': 'This category is inactive.',
  'khata_errorCategoryNotFound': 'Category not found.',
  'khata_errorCustomerArchived': 'This customer is archived.',
  'khata_errorCustomerNotFound': 'Customer not found.',
  'khata_errorDatabase': 'Database error. Please try again.',
  'khata_errorDriveConnectFailed': 'Could not connect to Google. Check your internet and try again.',
  'khata_errorDriveSignInCanceled': 'Google sign-in was canceled.',
  'khata_errorDriveSignInInterrupted': 'Sign-in was interrupted — please try again.',
  'khata_errorEmptyBatchInputs': 'A batch needs at least one input.',
  'khata_errorEmptyBatchOutputs': 'A batch needs at least one output.',
  'khata_errorEmptyInvoice': 'The invoice has no items.',
  'khata_errorEmptyJournal': 'The journal has no entries.',
  'khata_errorEmptyReturn': 'The return has no items.',
  'khata_errorEntryNotFound': 'Ledger entry not found.',
  'khata_errorInsufficientStock': 'Not enough stock of {product}.',
  'khata_errorInvalidAmount': 'Invalid amount.',
  'khata_errorInvalidJournalLine': 'Invalid journal entry.',
  'khata_errorInvalidQty': 'Invalid quantity.',
  'khata_errorInvoiceNotFound': 'Invoice not found.',
  'khata_errorMethodAccountMismatch': 'The payment method does not match the account.',
  'khata_errorNegativeCost': 'Cost cannot be negative.',
  'khata_errorNegativePrice': 'Price cannot be negative.',
  'khata_errorNegativeTax': 'Tax cannot be negative.',
  'khata_errorNegativeTotal': 'The total cannot be negative.',
  'khata_errorNoConversion': 'Unit conversion is not available.',
  'khata_errorNotADraft': 'Only drafts can be changed like this.',
  'khata_errorOilCostAllocation': 'Could not allocate the oil cost.',
  'khata_errorOverAllocated': 'The payment is more than the outstanding amount.',
  'khata_errorOverAllocatedInvoice': 'The payment is more than the invoice balance.',
  'khata_errorProductArchived': 'This product is archived.',
  'khata_errorProductNotFound': 'Product not found.',
  'khata_errorReasonRequired': 'A reason is required.',
  'khata_errorReturnExceedsBought': 'The return is more than what was bought.',
  'khata_errorReturnExceedsSold': 'The return is more than what was sold.',
  'khata_errorSmsChannelMissing': 'SMS channel is not available — open the SMS app to send.',
  'khata_errorSmsEmptyMessage': 'Message is empty.',
  'khata_errorSmsGeneric': 'Something went wrong while sending the SMS.',
  'khata_errorSmsNoNumber': 'Phone number is missing.',
  'khata_errorSmsNotAvailable': 'SMS cannot be sent on this device.',
  'khata_errorSmsPermissionDenied': 'SMS permission was not granted. Allow SMS permission in Settings.',
  'khata_errorSmsSendFailed': 'SMS could not be sent. {details}',
  'khata_errorSupplierArchived': 'This supplier is archived.',
  'khata_errorSupplierNotFound': 'Supplier not found.',
  'khata_errorTransferSameAccount': 'Cannot transfer to the same account.',
  'khata_errorUnbalancedJournal': 'The journal is not balanced.',
  'khata_errorUnitNotFound': 'Unit not found.',
  'khata_gallery': 'Gallery',
  'khata_hisaabClear': 'Account clear',
  'khata_imageAddKarein': 'Add image',
  'khata_lastTransacted': 'last transacted on {date}',
  'khata_liye': 'RECEIVED',
  'khata_maineDeneHain': 'I have to pay',
  'khata_maineLeneHain': 'I have to receive',
  'khata_maineyDiye': 'I gave',
  'khata_maineyLiye': 'I received',
  'khata_noCamera': 'Camera is not available on this device right now.',
  'khata_noDues': 'All settled up',
  'khata_noDuesHint': 'No outstanding balances',
  'khata_noPhone': 'No phone number saved for this customer.',
  'khata_remindersCount': 'Reminders ({count} overdue)',
  'khata_searchCustomer': 'Search Customer',
  'khata_searchSupplier': 'Search Supplier',
  'khata_sms': 'SMS',
  'khata_supplierSince': 'Supplier since {date}',
  'khata_suppliers': 'Suppliers',
  'khata_tareekhRakhein': 'Set date',
  'khata_time': 'TIME',
  'khata_title': 'Khata',
  'khata_toPay': 'To pay',
  'khata_toReceive': 'To receive',
  'khata_totalBalance': 'TOTAL BALANCE',
  'khata_viewAllCustomers': 'View customers',
  'khata_viewAllSuppliers': 'View suppliers',
  'khata_whatsapp': 'WhatsApp',
  'production_addInput': 'Add input',
  'production_addOutput': 'Add output',
  'production_available': 'Available: {qty} {unit}',
  'production_batchAuto': 'Auto-generated when the batch is posted',
  'production_batchNo': 'Batch no.',
  'production_costBreakdown': 'Cost breakdown',
  'production_costsCashHint': 'When selected, labour, electricity and other costs are posted as expenses from this account.',
  'production_date': 'Date',
  'production_electricityCost': 'Electricity cost',
  'production_emptyInputs': 'Add at least one input',
  'production_emptyOutputs': 'Add at least one output',
  'production_errNegativeCost': 'Costs cannot be negative',
  'production_expectedYield': 'Expected yield % (optional)',
  'production_inputs': 'Inputs (raw material)',
  'production_inputsCount': '{count} inputs',
  'production_labourCost': 'Labour cost',
  'production_materialCost': 'Material cost',
  'production_newBatch': 'New batch',
  'production_noBatches': 'No batches yet',
  'production_noBatchesHint': 'Start your first production batch.',
  'production_notes': 'Notes',
  'production_otherCost': 'Other cost',
  'production_outOfStock': 'No raw-material products yet',
  'production_outputType': 'Output type',
  'production_outputs': 'Outputs',
  'production_payCostsFrom': 'Pay costs from',
  'production_payCostsNone': 'None (record separately)',
  'production_postBatch': 'Post batch',
  'production_qtyGtZero': 'Quantity must be greater than zero',
  'production_rawOnly': 'Only raw-material products can be inputs',
  'production_removeLine': 'Remove line',
  'production_resultNoYield': 'Yield could not be computed — add a kg conversion for the units used.',
  'production_resultTitle': 'Batch posted',
  'production_resultYield': 'Yield: {pct}%',
  'production_selectProduct': 'Select product',
  'production_statusCostsPosted': 'Costs in cashbook',
  'production_statusPosted': 'Posted',
  'production_title': 'Production',
  'production_totalCost': 'Total cost',
  'production_typeByProduct': 'By-product',
  'production_typeFinishedOil': 'Finished oil',
  'production_typeOilCake': 'Oil cake',
  'production_wastage': 'Wastage / loss',
  'production_yield': 'Yield',
  'purchases_confirmPost': 'Post this purchase? Stock will increase.',
  'purchases_deleteDraft': 'Delete draft',
  'purchases_detailTitle': 'Purchase detail',
  'purchases_draftDeleted': 'Draft deleted',
  'purchases_draftSaved': 'Draft {invoiceNo} saved',
  'purchases_emptyTitle': 'No purchases yet',
  'purchases_formTitle': 'New purchase',
  'purchases_lineItems': 'Items',
  'purchases_newPurchase': 'New purchase',
  'purchases_noItems': 'Add at least one item',
  'purchases_noSupplierSelected': 'Select a supplier first',
  'purchases_payments': 'Payments',
  'purchases_postDraft': 'Post draft',
  'purchases_postPurchase': 'Post purchase',
  'purchases_purchasePosted': 'Purchase {invoiceNo} posted',
  'purchases_recordPayment': 'Record payment',
  'purchases_returnTitle': 'Purchase return',
  'purchases_searchHint': 'Search voucher no. or supplier…',
  'purchases_searchSupplier': 'Search suppliers…',
  'purchases_selectSupplier': 'Select supplier',
  'purchases_statusCancelled': 'Cancelled',
  'purchases_statusDraft': 'Draft',
  'purchases_statusPaid': 'Paid',
  'purchases_statusPartial': 'Partial',
  'purchases_statusReturned': 'Returned',
  'purchases_statusUnpaid': 'Unpaid',
  'purchases_supplier': 'Supplier',
  'purchases_title': 'Purchases',
  'purchases_voucherPdf': 'Purchase voucher PDF',
  'reminders_daysOverdue': '{days} days overdue',
  'reminders_dueOn': 'Due {date}',
  'reminders_editMessage': 'Edit message',
  'reminders_emptyMessage': 'No overdue or upcoming payments. All clear!',
  'reminders_emptyTitle': 'No reminders',
  'reminders_failed': 'Could not send. Try again.',
  'reminders_noPhone': 'No phone number saved for {name}.',
  'reminders_overdue': 'Overdue',
  'reminders_pickScript': 'Choose message language',
  'reminders_scriptEnglish': 'English',
  'reminders_scriptUrdu': 'Urdu',
  'reminders_send': 'Send',
  'reminders_sendSms': 'Send SMS reminder',
  'reminders_sendWhatsapp': 'Send WhatsApp reminder',
  'reminders_sent': 'Reminder sent.',
  'reminders_title': 'Payment Reminders',
  'reminders_upcoming': 'Upcoming',
  'reports_accounts': 'Accounts',
  'reports_all': 'All',
  'reports_avgCost': 'Avg. cost',
  'reports_avgYield': 'Average yield',
  'reports_batches': 'Batches',
  'reports_cashBankBalances': 'Cash & Bank Balances',
  'reports_cashbook': 'Cashbook',
  'reports_change': 'Change',
  'reports_closingBalance': 'Closing balance',
  'reports_copied': 'Copied to clipboard',
  'reports_copyReminder': 'Copy reminder',
  'reports_customRange': 'Custom range',
  'reports_customerLedger': 'Customer Ledger',
  'reports_customers': 'Customers',
  'reports_dailySummary': 'Daily Summary',
  'reports_daybook': 'Daybook',
  'reports_doc_account': 'Account',
  'reports_doc_amount': 'Amount',
  'reports_doc_balance': 'Balance',
  'reports_doc_bank': 'Bank',
  'reports_doc_batchNo': 'Batch no.',
  'reports_doc_billTo': 'Bill to',
  'reports_doc_byProduct': 'By-product',
  'reports_doc_cash': 'Cash',
  'reports_doc_cashReceipt': 'Cash Receipt',
  'reports_doc_category': 'Category',
  'reports_doc_closingBalance': 'Closing balance',
  'reports_doc_credit': 'Credit',
  'reports_doc_customer': 'Customer',
  'reports_doc_customerStatement': 'Customer Statement',
  'reports_doc_date': 'Date',
  'reports_doc_debit': 'Debit',
  'reports_doc_description': 'Description',
  'reports_doc_discount': 'Discount',
  'reports_doc_due': 'Balance due',
  'reports_doc_electricity': 'Electricity',
  'reports_doc_expenseVoucher': 'Expense Voucher',
  'reports_doc_from': 'From',
  'reports_doc_generatedOn': 'Generated on {date}',
  'reports_doc_inputs': 'Inputs (raw material)',
  'reports_doc_invoiceNo': 'Invoice no.',
  'reports_doc_item': 'Item',
  'reports_doc_items': 'Items',
  'reports_doc_labour': 'Labour',
  'reports_doc_method': 'Method',
  'reports_doc_notes': 'Notes',
  'reports_doc_oilCake': 'Oil cake',
  'reports_doc_openingBalance': 'Opening balance',
  'reports_doc_other': 'Other',
  'reports_doc_outputs': 'Outputs',
  'reports_doc_paid': 'Paid',
  'reports_doc_paidTo': 'Paid to',
  'reports_doc_paymentReceipt': 'Payment Receipt',
  'reports_doc_pdfSaved': 'PDF saved.',
  'reports_doc_period': 'Period',
  'reports_doc_price': 'Price',
  'reports_doc_print': 'Print',
  'reports_doc_productionReport': 'Production Report',
  'reports_doc_purchaseVoucher': 'Purchase Voucher',
  'reports_doc_qty': 'Qty',
  'reports_doc_receivedFrom': 'Received from',
  'reports_doc_reference': 'Reference',
  'reports_doc_saleInvoice': 'Sale Invoice',
  'reports_doc_savePdf': 'Save PDF',
  'reports_doc_share': 'Share',
  'reports_doc_status': 'Status',
  'reports_doc_subtotal': 'Subtotal',
  'reports_doc_supplier': 'Supplier',
  'reports_doc_supplierPaymentVoucher': 'Supplier Payment Voucher',
  'reports_doc_supplierStatement': 'Supplier Statement',
  'reports_doc_tax': 'Tax',
  'reports_doc_to': 'To',
  'reports_doc_total': 'Total',
  'reports_doc_yield': 'Yield',
  'reports_due': 'Due',
  'reports_estimatedNote': 'Estimated — cost data is incomplete for this period.',
  'reports_expense': 'Expenses',
  'reports_expensesByCategory': 'Expenses by category',
  'reports_grandTotal': 'Grand total',
  'reports_income': 'Income',
  'reports_inventoryValuation': 'Inventory Valuation',
  'reports_invoices': 'Invoices',
  'reports_lowStock': 'Low Stock',
  'reports_monthlySummary': 'Monthly Summary',
  'reports_netLoss': 'Net loss',
  'reports_netProfit': 'Net profit',
  'reports_noData': 'No data for this period.',
  'reports_onHand': 'On hand',
  'reports_openingBalance': 'Opening balance',
  'reports_outstandingInvoices': 'Outstanding Invoices',
  'reports_paid': 'Paid',
  'reports_partial': 'Partially paid',
  'reports_payables': 'Payables',
  'reports_paymentsMade': 'Payments Made',
  'reports_paymentsReceived': 'Payments Received',
  'reports_pickDate': 'Pick date',
  'reports_pickMonth': 'Pick month',
  'reports_production': 'Production',
  'reports_profitLoss': 'Profit & Loss',
  'reports_purchase': 'Purchases',
  'reports_purchaseInvoices': 'Purchase invoices',
  'reports_purchaseReturns': 'Purchase Returns',
  'reports_quantity': 'Quantity',
  'reports_receivables': 'Receivables',
  'reports_recordsCount': '{count} records',
  'reports_reorderLevel': 'Reorder level',
  'reports_saleInvoices': 'Sale invoices',
  'reports_sales': 'Sales',
  'reports_salesReturns': 'Sales Returns',
  'reports_selectAccount': 'Select account',
  'reports_selectCustomer': 'Select customer',
  'reports_selectProduct': 'Select product',
  'reports_selectSupplier': 'Select supplier',
  'reports_stockMovement': 'Stock Movement',
  'reports_stockValue': 'Stock value',
  'reports_supplierLedger': 'Supplier Ledger',
  'reports_suppliers': 'Suppliers',
  'reports_title': 'Reports',
  'reports_totalExpenses': 'Total expenses',
  'reports_totalIncome': 'Total income',
  'reports_totalPaid': 'Total paid',
  'reports_totalPurchases': 'Total purchases',
  'reports_totalReceived': 'Total received',
  'reports_totalSales': 'Total sales',
  'reports_trialBalance': 'Trial Balance',
  'reports_unpaid': 'Unpaid',
  'reports_value': 'Value',
  'reports_yield': 'Yield',
  'sales_apniMarzi': 'Custom',
  'sales_confirmPost': 'Post this sale? Stock will be reduced.',
  'sales_customer': 'Customer',
  'sales_deleteDraft': 'Delete draft',
  'sales_detailTitle': 'Sale detail',
  'sales_draftDeleted': 'Draft deleted',
  'sales_draftSaved': 'Draft {invoiceNo} saved',
  'sales_emptyTitle': 'No sales yet',
  'sales_formTitle': 'New sale',
  'sales_haaliSales': 'RECENT SALES',
  'sales_hafta': 'Week',
  'sales_invoicePdf': 'Invoice PDF',
  'sales_itemsManage': 'Manage items',
  'sales_itemsManageHint': 'Add, update or remove the items you sell',
  'sales_kullNaqad': 'TOTAL CASH',
  'sales_kullOrders': 'TOTAL ORDERS',
  'sales_kullSales': 'TOTAL SALES',
  'sales_kullUdhaar': 'TOTAL CREDIT',
  'sales_lineItems': 'Items',
  'sales_maheena': 'Month',
  'sales_manageItems': 'Manage items',
  'sales_nataij': '{count} results',
  'sales_newSale': 'New sale',
  'sales_noCustomerSelected': 'Select a customer first',
  'sales_noItems': 'Add at least one item',
  'sales_noSalesPeriod': 'No sales in this period',
  'sales_payments': 'Payments',
  'sales_periodCustom': 'in this period',
  'sales_periodHafta': 'this week',
  'sales_periodMaheena': 'this month',
  'sales_postDraft': 'Post draft',
  'sales_postSale': 'Post sale',
  'sales_recordPayment': 'Record payment',
  'sales_returnTitle': 'Sales return',
  'sales_saleDarjKarein': 'Record sale',
  'sales_salePosted': 'Sale {invoiceNo} posted',
  'sales_searchCustomer': 'Search customers…',
  'sales_searchHint': 'Search invoice no. or customer…',
  'sales_searchSales': 'Search by name or amount',
  'sales_selectCustomer': 'Select customer',
  'sales_share': 'Share',
  'sales_statusCancelled': 'Cancelled',
  'sales_statusDraft': 'Draft',
  'sales_statusPaid': 'Paid',
  'sales_statusPartial': 'Partial',
  'sales_statusReturned': 'Returned',
  'sales_statusUnpaid': 'Unpaid',
  'sales_title': 'Sales',
  'transactions_account': 'Account',
  'transactions_addItem': 'Add item',
  'transactions_adjustment': 'Adjustment',
  'transactions_bank': 'Bank',
  'transactions_cash': 'Cash',
  'transactions_category': 'Category',
  'transactions_credit': 'Credit',
  'transactions_customRange': 'Custom range',
  'transactions_customRangeHint': '{from} – {to}',
  'transactions_customRangeTitle': 'Select date range',
  'transactions_date': 'Date',
  'transactions_debit': 'Debit',
  'transactions_description': 'Description',
  'transactions_detailTitle': 'Transaction detail',
  'transactions_discount': 'Discount',
  'transactions_discountPct': 'Discount %',
  'transactions_due': 'Due',
  'transactions_emptyTitle': 'No transactions',
  'transactions_entriesCount': '{count} entries',
  'transactions_entryNo': 'Entry no.',
  'transactions_expense': 'Expense',
  'transactions_filterAll': 'All',
  'transactions_filterPaymentPaid': 'Payment paid',
  'transactions_filterPaymentReceived': 'Payment received',
  'transactions_income': 'Income',
  'transactions_invalidPrice': 'Enter a valid price',
  'transactions_invalidQty': 'Enter a valid quantity',
  'transactions_invoiceDiscount': 'Invoice discount %',
  'transactions_lineTotal': 'Line total',
  'transactions_maxQty': 'Max {qty}',
  'transactions_noDescription': '—',
  'transactions_notes': 'Notes',
  'transactions_paidAmount': 'Paid now',
  'transactions_paymentAccount': 'Account',
  'transactions_paymentAmount': 'Amount',
  'transactions_paymentMethod': 'Method',
  'transactions_paymentReference': 'Reference',
  'transactions_paymentSaved': 'Payment saved',
  'transactions_paymentTitle': 'Record payment',
  'transactions_production': 'Production',
  'transactions_purchase': 'Purchase',
  'transactions_qty': 'Qty',
  'transactions_reference': 'Reference',
  'transactions_removeLine': 'Remove line',
  'transactions_return': 'Return',
  'transactions_returnPosted': 'Return posted',
  'transactions_returnReason': 'Reason (optional)',
  'transactions_returnTitle': 'Return items',
  'transactions_reversal': 'Reversal',
  'transactions_reversalOf': 'Reversal of {entryNo}',
  'transactions_reversed': 'Reversed',
  'transactions_sale': 'Sale',
  'transactions_saveDraft': 'Save as draft',
  'transactions_searchHint': 'Search description, entry no…',
  'transactions_searchProduct': 'Search products…',
  'transactions_selectProduct': 'Select product',
  'transactions_sortNewest': 'Newest',
  'transactions_sortOldest': 'Oldest',
  'transactions_submitPayment': 'Save payment',
  'transactions_submitReturn': 'Post return',
  'transactions_subtotal': 'Subtotal',
  'transactions_tax': 'Tax',
  'transactions_taxPct': 'Tax %',
  'transactions_title': 'Transactions',
  'transactions_total': 'Journal total',
  'transactions_transfer': 'Transfer',
  'transactions_unit': 'Unit',
  'transactions_unitPrice': 'Unit price',
  'udhaar_saved': 'Credit recorded',
  'udhaar_title': 'Give credit',
};

const Map<String, String> _fragmentUr = {
  'backup_chooseFile': 'بیک اپ فائل منتخب کریں',
  'backup_confirmMessage': 'موجودہ تمام ڈیٹا بیک اپ سے بدل دیا جائے گا۔ یہ عمل واپس نہیں ہو سکتا۔',
  'backup_confirmRestore': 'بحال کریں',
  'backup_confirmTitle': 'کیا یہ بیک اپ بحال کریں؟',
  'backup_create': 'بیک اپ بنائیں',
  'backup_created': 'بیک اپ تیار — {tables} ٹیبلز میں {count} ریکارڈ۔',
  'backup_creating': 'بیک اپ بنایا جا رہا ہے…',
  'backup_driveAutoBackup': '24 گھنٹے خودکار بیک اپ',
  'backup_driveAutoBackupHint': 'ہر 24 گھنٹے بعد پورے دن کا ڈیٹا خود بخود ڈرائیو پر اپ لوڈ ہو جائے گا۔',
  'backup_driveBackupFailed': 'بیک اپ ناکام ہو گیا: {error}',
  'backup_driveBackupNow': 'ابھی بیک اپ کریں',
  'backup_driveBackupSaved': 'بیک اپ ڈرائیو پر محفوظ ہو گیا: {name}',
  'backup_driveConnect': 'گوگل سے منسلک کریں',
  'backup_driveConnectFailed': 'گوگل سے منسلک نہیں ہو سکا۔ پہلے سیٹنگز سے منسلک کریں۔',
  'backup_driveConnectIntro': 'گوگل سے منسلک کریں تاکہ آپ کا ڈیٹا خود بخود ڈرائیو پر بیک اپ ہو۔',
  'backup_driveConnected': 'گوگل سے منسلک ہو گیا: {email}',
  'backup_driveDisconnect': 'منقطع کریں',
  'backup_driveDisconnectMessage': 'خودکار بیک اپ بند ہو جائے گا۔ ڈرائیو پر پہلے سے محفوظ بیک اپ وہیں رہیں گے۔',
  'backup_driveDisconnectTitle': 'گوگل منقطع کریں؟',
  'backup_driveExportFailed': 'ایکسپورٹ ناکام ہو گیا: {error}',
  'backup_driveExportRange': 'برآمد — حسبِ منشا تاریخ کی حد',
  'backup_driveExportSaved': 'ایکسپورٹ ڈرائیو پر محفوظ ہو گیا: {name}',
  'backup_driveLastBackup': 'آخری بیک اپ: {date}',
  'backup_driveNoBackupYet': 'ابھی تک کوئی بیک اپ نہیں ہوا',
  'backup_driveTitle': 'گوگل ڈرائیو بیک اپ',
  'backup_errorChecksum': 'بیک اپ ڈیٹا خراب ہے ({table} میں چیک سم مماثل نہیں)۔',
  'backup_errorInvalidFile': 'یہ فائل نمت آئل مل کا درست بیک اپ نہیں ہے۔',
  'backup_errorMissingTables': 'بیک اپ میں یہ ٹیبلز غائب ہیں: {tables}۔',
  'backup_errorUnsupportedVersion': 'غیر تعاون یافتہ بیک اپ ورژن: {version}۔',
  'backup_exportedAt': 'برآمد شدہ: {date}',
  'backup_intro': 'اپنے تمام ڈیٹا کی محفوظ نقل رکھیں۔ بیک اپ ایک JSON فائل ہے جو صرف اس ڈیوائس پر محفوظ ہوتی ہے — کچھ بھی اپ لوڈ نہیں ہوتا۔',
  'backup_reading': 'بیک اپ پڑھا جا رہا ہے…',
  'backup_recordsCount': '{count} ریکارڈ',
  'backup_restore': 'بیک اپ بحال کریں',
  'backup_restored': 'بحالی مکمل — {count} ریکارڈ بحال ہوئے۔',
  'backup_restoring': 'بحال کیا جا رہا ہے…',
  'backup_savedTo': '{path} میں محفوظ ہو گیا',
  'backup_summaryTitle': 'بیک اپ کا خلاصہ',
  'backup_tablesCount': '{count} ٹیبلز',
  'backup_title': 'بیک اپ و بحالی',
  'cashbook_accountName': 'کھاتے کا نام',
  'cashbook_accountType': 'کھاتے کی قسم',
  'cashbook_accounts': 'کھاتے',
  'cashbook_addAccount': 'کھاتہ شامل کریں',
  'cashbook_addPayment': 'ادائیگی شامل کریں',
  'cashbook_addReceipt': 'رسید شامل کریں',
  'cashbook_amount': 'رقم',
  'cashbook_balance': 'بیلنس',
  'cashbook_customer': 'گاہک',
  'cashbook_date': 'تاریخ',
  'cashbook_editAccount': 'کھاتے میں ترمیم کریں',
  'cashbook_entries': 'اندراجات',
  'cashbook_errAccountNotFound': 'کھاتہ نہیں ملا',
  'cashbook_errInvalidAmount': 'درست رقم درج کریں',
  'cashbook_errTransferSame': 'از اور تک کے کھاتے مختلف ہونے چاہئیں',
  'cashbook_from': 'از',
  'cashbook_in': 'آمد',
  'cashbook_method': 'طریقہ',
  'cashbook_methodBank': 'بینک',
  'cashbook_methodCash': 'نقد',
  'cashbook_newTransfer': 'نئی منتقلی',
  'cashbook_noAccounts': 'ابھی کوئی کھاتہ نہیں',
  'cashbook_noEntries': 'اس مدت میں کوئی اندراج نہیں',
  'cashbook_notes': 'نوٹس',
  'cashbook_openingBalance': 'ابتدائی بیلنس',
  'cashbook_out': 'خرچ',
  'cashbook_payment': 'ادائیگی',
  'cashbook_pickAccount': 'کھاتہ منتخب کریں',
  'cashbook_receipt': 'رسید',
  'cashbook_reference': 'حوالہ',
  'cashbook_selectCustomer': 'گاہک منتخب کریں',
  'cashbook_selectSupplier': 'سپلائر منتخب کریں',
  'cashbook_supplier': 'سپلائر',
  'cashbook_title': 'کیش بک',
  'cashbook_to': 'تک',
  'cashbook_totalIn': 'کل آمد',
  'cashbook_totalOut': 'کل خرچ',
  'cashbook_transfer': 'منتقلی',
  'cashbook_transferInfo': 'منتقلی دو کھاتوں کے درمیان رقم منتقل کرتی ہے۔ یہ کبھی آمدنی یا خرچ نہیں ہوتی۔',
  'cashbook_typeBank': 'بینک',
  'cashbook_typeCash': 'نقد',
  'common_cancel': 'منسوخ کریں',
  'customers_account': 'اکاؤنٹ',
  'customers_addCustomer': 'نیا گاہک',
  'customers_addFirstHint': 'ادھار کا حساب رکھنے کے لیے پہلا گاہک شامل کریں',
  'customers_addFirstSupplierHint': 'خریداری کا حساب رکھنے کے لیے پہلا سپلائر شامل کریں',
  'customers_addSupplier': 'نیا سپلائر',
  'customers_address': 'پتہ',
  'customers_amount': 'رقم (روپے)',
  'customers_archive': 'آرکائیو',
  'customers_archiveMessage': 'وہ فہرستوں سے چھپ جائیں گے، لیکن ان کا ریکارڈ محفوظ رہے گا۔',
  'customers_archiveTitle': '{name} کو آرکائیو کریں؟',
  'customers_bank': 'بینک',
  'customers_businessName': 'کاروبار کا نام',
  'customers_cash': 'نقد',
  'customers_code': 'کوڈ',
  'customers_copied': 'کلپ بورڈ میں کاپی ہو گیا',
  'customers_copyText': 'متن کاپی کریں',
  'customers_customRange': 'اپنی مدت',
  'customers_customerArchived': 'گاہک آرکائیو ہو گیا',
  'customers_customerRestored': 'گاہک بحال ہو گیا',
  'customers_date': 'تاریخ',
  'customers_editCustomer': 'گاہک کی تدوین',
  'customers_editSupplier': 'سپلائر کی تدوین',
  'customers_englishVersion': 'انگریزی',
  'customers_filterAdvance': 'ایڈوانس',
  'customers_filterAdvancePaid': 'ایڈوانس دیا گیا',
  'customers_filterAll': 'سب',
  'customers_filterPayable': 'ادا کرنا ہے',
  'customers_filterReceivable': 'وصول کرنا ہے',
  'customers_giveUdhaar': 'ادھار دیں',
  'customers_ledgerTitle': 'لیجر',
  'customers_makePayment': 'ادائیگی کریں',
  'customers_method': 'طریقہ',
  'customers_name': 'نام',
  'customers_newCustomer': 'نیا گاہک',
  'customers_newSupplier': 'نیا سپلائر',
  'customers_noCustomers': 'ابھی کوئی گاہک نہیں',
  'customers_noEntries': 'اس مدت میں کوئی اندراج نہیں',
  'customers_noMatch': 'کوئی نتیجہ نہیں ملا',
  'customers_noSuppliers': 'ابھی کوئی سپلائر نہیں',
  'customers_notFound': 'ریکارڈ نہیں ملا',
  'customers_note': 'نوٹ',
  'customers_notes': 'نوٹس',
  'customers_openingBalance': 'ابتدائی بیلنس',
  'customers_openingBalanceHint': 'اختیاری۔ رقم روپے میں۔',
  'customers_openingBalanceLabel': 'ابتدائی بیلنس',
  'customers_openingHelpCustomer': 'مثبت: گاہک آپ کا مقروض ہے۔ منفی: آپ گاہک کے مقروض ہیں۔',
  'customers_openingHelpSupplier': 'مثبت: آپ سپلائر کے مقروض ہیں۔ منفی: سپلائر آپ کا مقروض ہے۔',
  'customers_paymentSaved': 'ادائیگی درج ہو گئی',
  'customers_paymentTitlePay': 'ادائیگی کریں',
  'customers_paymentTitleReceive': 'ادائیگی وصول کریں',
  'customers_phone': 'فون',
  'customers_receivePayment': 'ادائیگی وصول کریں',
  'customers_recordPurchase': 'خریداری درج کریں',
  'customers_reminder': 'یاد دہانی',
  'customers_reminderTitle': 'ادائیگی کی یاددہانی',
  'customers_saved': 'محفوظ ہو گیا',
  'customers_searchHint': 'نام، فون یا کوڈ تلاش کریں',
  'customers_searchLedgerHint': 'تفصیل تلاش کریں',
  'customers_selectAccount': 'اکاؤنٹ منتخب کریں',
  'customers_statement': 'اسٹیٹمنٹ',
  'customers_supplierArchived': 'سپلائر آرکائیو ہو گیا',
  'customers_supplierRestored': 'سپلائر بحال ہو گیا',
  'customers_supplierTitle': 'سپلائرز',
  'customers_title': 'گاہک',
  'customers_totalCredit': 'کل ادھار دیا گیا',
  'customers_totalPaid': 'کل ادا شدہ',
  'customers_totalPurchases': 'کل خریداری',
  'customers_totalReceived': 'کل وصول شدہ',
  'customers_unarchive': 'بحال کریں',
  'customers_urduVersion': 'اردو',
  'customers_viewLedger': 'لیجر دیکھیں',
  'customers_waAdd': 'شامل کریں',
  'customers_waAddMessage': '{name} کا واٹس ایپ نمبر محفوظ کریں تاکہ حساب سیدھا ان کی چیٹ میں بھیجا جا سکے۔',
  'customers_waAddTitle': 'واٹس ایپ نمبر شامل کریں',
  'customers_waOpenChat': 'چیٹ کھولیں',
  'customers_waOpenFailed': 'واٹس ایپ نہیں کھل سکا۔ نمبر چیک کریں یا واٹس ایپ انسٹال کریں۔',
  'customers_waSendStatement': 'اسٹیٹمنٹ PDF بھیجیں',
  'customers_waSendStatementHint': 'حساب کتاب کی PDF بن کر شیئر ہو گی۔',
  'customers_waStatementText': '{name} — کھاتہ اسٹیٹمنٹ',
  'customers_whatsappNumber': 'واٹس ایپ نمبر',
  'dashboard_activityExpense': 'خرچ',
  'dashboard_activityIncome': 'آمدنی',
  'dashboard_activityPaymentIn': 'ادائیگی موصول',
  'dashboard_activityPaymentOut': 'ادائیگی کی گئی',
  'dashboard_activityPurchase': 'خریداری {no}',
  'dashboard_activitySale': 'فروخت {no}',
  'dashboard_bankBalance': 'بینک بیلنس',
  'dashboard_cashInHand': 'نقد رقم',
  'dashboard_lowStock': 'کم اسٹاک الرٹس',
  'dashboard_lowStockOk': 'اسٹاک کی سطح بہتر ہے',
  'dashboard_monthExpense': 'اس ماہ اخراجات',
  'dashboard_monthIncome': 'اس ماہ آمدنی',
  'dashboard_noActivity': 'کوئی حالیہ سرگرمی نہیں',
  'dashboard_noActivityHint': 'فروخت، خریداری اور ادائیگیاں یہاں نظر آئیں گی',
  'dashboard_paidToday': 'آج ادا شدہ',
  'dashboard_pickCustomer': 'گاہک منتخب کریں',
  'dashboard_pickSupplier': 'سپلائر منتخب کریں',
  'dashboard_qaAddCustomer': 'گاہک شامل کریں',
  'dashboard_qaAddExpense': 'خرچ درج کریں',
  'dashboard_qaAddPurchase': 'خریداری درج کریں',
  'dashboard_qaAddSale': 'فروخت درج کریں',
  'dashboard_qaAddSupplier': 'سپلائر شامل کریں',
  'dashboard_qaGiveUdhaar': 'ادھار دیں',
  'dashboard_qaMakePayment': 'ادائیگی کریں',
  'dashboard_qaReceivePayment': 'ادائیگی وصول کریں',
  'dashboard_qaRecordProduction': 'پیداوار درج کریں',
  'dashboard_qaViewReports': 'رپورٹس دیکھیں',
  'dashboard_quickActions': 'فوری اقدامات',
  'dashboard_receivedToday': 'آج وصول شدہ',
  'dashboard_recentActivity': 'حالیہ سرگرمی',
  'dashboard_stockLeft': '{qty} {unit} باقی',
  'dashboard_thisMonth': 'اس ماہ',
  'dashboard_title': 'ڈیش بورڈ',
  'dashboard_today': 'آج',
  'dashboard_todayPurchases': 'آج کی خریداری',
  'dashboard_todaySales': 'آج کی فروخت',
  'dashboard_totalBalance': 'کل بیلنس',
  'dashboard_totalPayable': 'ادا کرنا ہے',
  'dashboard_totalReceivable': 'وصول کرنا ہے',
  'dashboard_viewAll': 'سب دیکھیں',
  'expenses_account': 'کھاتہ',
  'expenses_addCategory': 'نئی مد شامل کریں',
  'expenses_addExpense': 'خرچ شامل کریں',
  'expenses_addIncome': 'آمدنی شامل کریں',
  'expenses_amount': 'رقم',
  'expenses_category': 'مد',
  'expenses_categoryName': 'مد کا نام',
  'expenses_categorySaved': 'مد محفوظ ہو گئی',
  'expenses_date': 'تاریخ',
  'expenses_description': 'تفصیل',
  'expenses_errAccountNotFound': 'کھاتہ نہیں ملا',
  'expenses_errCategoryNotFound': 'مد نہیں ملی',
  'expenses_errInvalidAmount': 'درست رقم درج کریں',
  'expenses_expenseSaved': 'خرچ محفوظ ہو گیا',
  'expenses_incomeCategory': 'آمدنی کی قسم (اختیاری)',
  'expenses_incomeSaved': 'آمدنی محفوظ ہو گئی',
  'expenses_noEntries': 'ابھی کوئی اندراج نہیں',
  'expenses_reference': 'حوالہ',
  'expenses_tabExpenses': 'اخراجات',
  'expenses_tabIncome': 'آمدنی',
  'expenses_thisMonth': 'اس ماہ',
  'expenses_thisYear': 'اس سال',
  'expenses_title': 'اخراجات و آمدنی',
  'expenses_today': 'آج',
  'expenses_totalExpenses': 'کل اخراجات',
  'expenses_totalIncome': 'کل آمدنی',
  'inventory_addConversion': 'تبادلہ شامل کریں',
  'inventory_addProduct': 'مصنوعات شامل کریں',
  'inventory_adjust': 'اسٹاک درست کریں',
  'inventory_adjustment': 'درستگی',
  'inventory_all': 'تمام',
  'inventory_available': 'دستیاب',
  'inventory_avgCost': 'اوسط لاگت',
  'inventory_catConsumable': 'استعمال کی اشیاء',
  'inventory_catContainer': 'ڈبے',
  'inventory_catFinishedOil': 'تیار تیل',
  'inventory_catOilCake': 'کھل',
  'inventory_catPackaging': 'پیکنگ',
  'inventory_catRawMaterial': 'خام مال',
  'inventory_catSpare': 'اسپیئر پارٹس',
  'inventory_category': 'قسم',
  'inventory_conversionExists': 'اس جوڑے کے لیے تبادلہ پہلے سے موجود ہے',
  'inventory_conversionsTitle': 'تبادلے',
  'inventory_editConversion': 'تبادلے میں ترمیم کریں',
  'inventory_editProduct': 'مصنوعات میں ترمیم کریں',
  'inventory_errDatabase': 'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔',
  'inventory_errInsufficientStock': '{product} کا اسٹاک ناکافی ہے (دستیاب {available}، درکار {needed})',
  'inventory_errInvalidAmount': 'درست رقم درج کریں',
  'inventory_errInvalidQty': 'صفر سے بڑی درست مقدار درج کریں',
  'inventory_errNoConversion': 'ان اکائیوں کے درمیان کوئی تبادلہ مقرر نہیں',
  'inventory_errProductNotFound': 'مصنوعات نہیں ملی',
  'inventory_factor': 'تناسب',
  'inventory_factorHint': '1 {from} میں کتنے {to}؟',
  'inventory_factorPositive': 'تناسب صفر سے بڑا ہونا چاہیے',
  'inventory_from': 'از',
  'inventory_in': 'آمد',
  'inventory_lowStock': 'کم اسٹاک',
  'inventory_movements': 'اسٹاک کا ریکارڈ',
  'inventory_name': 'مصنوعات کا نام',
  'inventory_noConversions': 'ابھی کوئی تبادلہ مقرر نہیں',
  'inventory_noMovements': 'ابھی کوئی ریکارڈ درج نہیں',
  'inventory_noProducts': 'کوئی مصنوعات نہیں ملی',
  'inventory_noProductsHint': 'اسٹاک کا ریکارڈ رکھنے کے لیے پہلی مصنوعات شامل کریں۔',
  'inventory_openingStock': 'ابتدائی اسٹاک',
  'inventory_openingStockReason': 'ابتدائی اسٹاک',
  'inventory_out': 'خرچ',
  'inventory_productSaved': 'مصنوعات محفوظ ہو گئی',
  'inventory_qty': 'مقدار',
  'inventory_reason': 'وجہ',
  'inventory_reasonRequired': 'براہ کرم وجہ درج کریں',
  'inventory_reorderLevel': 'دوبارہ آرڈر کی حد',
  'inventory_salePrice': 'طے شدہ فروخت قیمت (اختیاری)',
  'inventory_searchHint': 'مصنوعات تلاش کریں',
  'inventory_sku': 'SKU (اختیاری)',
  'inventory_stock': 'اسٹاک',
  'inventory_stockIn': 'اسٹاک وصول کریں',
  'inventory_stockInReason': 'اسٹاک وصولی',
  'inventory_stockOut': 'اسٹاک جاری کریں',
  'inventory_stockOutReason': 'اسٹاک اجراء',
  'inventory_stockUpdated': 'اسٹاک اپ ڈیٹ ہو گیا',
  'inventory_stockValue': 'اسٹاک کی مالیت',
  'inventory_title': 'انوینٹری',
  'inventory_to': 'تک',
  'inventory_typeAdjustment': 'درستگی',
  'inventory_typeProduction': 'پیداوار',
  'inventory_typePurchase': 'خریداری',
  'inventory_typeReturn': 'واپسی',
  'inventory_typeSale': 'فروخت',
  'inventory_unit': 'اکائی',
  'inventory_units': 'اکائیاں اور تبادلے',
  'inventory_unitsTitle': 'اکائیاں',
  'khata_addBills': 'بل شامل کریں',
  'khata_addCustomerBtn': 'گاہک شامل کریں',
  'khata_addSupplierBtn': 'سپلائر شامل کریں',
  'khata_balAfter': 'بیلنس: {amount}',
  'khata_billAttached': 'بل کی تصویر منسلک ہو گئی',
  'khata_businessName': 'نمت آئل مل',
  'khata_camera': 'کیمرہ',
  'khata_customerSince': 'گاہک از {date}',
  'khata_customers': 'گاہک',
  'khata_diye': 'دیے',
  'khata_errorAccountInactive': 'یہ اکاؤنٹ غیر فعال ہے۔',
  'khata_errorAccountNotFound': 'اکاؤنٹ نہیں ملا۔',
  'khata_errorAlreadyReversed': 'اس اندراج کو پہلے ہی کالعدم کیا جا چکا ہے۔',
  'khata_errorCategoryInactive': 'یہ کیٹیگری غیر فعال ہے۔',
  'khata_errorCategoryNotFound': 'کیٹیگری نہیں ملی۔',
  'khata_errorCustomerArchived': 'یہ گاہک آرکائیو شدہ ہے۔',
  'khata_errorCustomerNotFound': 'گاہک نہیں ملا۔',
  'khata_errorDatabase': 'ڈیٹا بیس میں خرابی۔ دوبارہ کوشش کریں۔',
  'khata_errorDriveConnectFailed': 'گوگل سے منسلک نہیں ہو سکا۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔',
  'khata_errorDriveSignInCanceled': 'گوگل سائن اِن منسوخ کر دیا گیا۔',
  'khata_errorDriveSignInInterrupted': 'سائن اِن ادھورا رہ گیا — دوبارہ کوشش کریں۔',
  'khata_errorEmptyBatchInputs': 'بیچ کے لیے کم از کم ایک ان پٹ ضروری ہے۔',
  'khata_errorEmptyBatchOutputs': 'بیچ کے لیے کم از کم ایک آؤٹ پٹ ضروری ہے۔',
  'khata_errorEmptyInvoice': 'انوائس میں کوئی آئٹم نہیں۔',
  'khata_errorEmptyJournal': 'جرنل میں کوئی اندراج نہیں۔',
  'khata_errorEmptyReturn': 'واپسی میں کوئی آئٹم نہیں۔',
  'khata_errorEntryNotFound': 'لیجر اندراج نہیں ملا۔',
  'khata_errorInsufficientStock': '{product} کا اسٹاک ناکافی ہے۔',
  'khata_errorInvalidAmount': 'غلط رقم۔',
  'khata_errorInvalidJournalLine': 'غلط جرنل اندراج۔',
  'khata_errorInvalidQty': 'غلط مقدار۔',
  'khata_errorInvoiceNotFound': 'انوائس نہیں ملی۔',
  'khata_errorMethodAccountMismatch': 'ادائیگی کا طریقہ اکاؤنٹ سے مطابقت نہیں رکھتا۔',
  'khata_errorNegativeCost': 'لاگت منفی نہیں ہو سکتی۔',
  'khata_errorNegativePrice': 'قیمت منفی نہیں ہو سکتی۔',
  'khata_errorNegativeTax': 'ٹیکس منفی نہیں ہو سکتا۔',
  'khata_errorNegativeTotal': 'کل رقم منفی نہیں ہو سکتی۔',
  'khata_errorNoConversion': 'یونٹ کی تبدیلی دستیاب نہیں۔',
  'khata_errorNotADraft': 'اس طرح صرف ڈرافٹ تبدیل ہو سکتا ہے۔',
  'khata_errorOilCostAllocation': 'تیل کی لاگت تقسیم نہیں ہو سکی۔',
  'khata_errorOverAllocated': 'ادائیگی بقایا رقم سے زیادہ ہے۔',
  'khata_errorOverAllocatedInvoice': 'ادائیگی انوائس کے بقایا سے زیادہ ہے۔',
  'khata_errorProductArchived': 'یہ پراڈکٹ آرکائیو شدہ ہے۔',
  'khata_errorProductNotFound': 'پراڈکٹ نہیں ملا۔',
  'khata_errorReasonRequired': 'وجہ بتانا ضروری ہے۔',
  'khata_errorReturnExceedsBought': 'واپسی خریداری سے زیادہ ہے۔',
  'khata_errorReturnExceedsSold': 'واپسی فروخت سے زیادہ ہے۔',
  'khata_errorSmsChannelMissing': 'SMS چینل دستیاب نہیں — بھیجنے کے لیے SMS ایپ کھولیں۔',
  'khata_errorSmsEmptyMessage': 'پیغام خالی ہے۔',
  'khata_errorSmsGeneric': 'SMS بھیجنے میں مسئلہ ہوا۔',
  'khata_errorSmsNoNumber': 'فون نمبر موجود نہیں ہے۔',
  'khata_errorSmsNotAvailable': 'اس ڈیوائس پر SMS بھیجنا ممکن نہیں۔',
  'khata_errorSmsPermissionDenied': 'SMS کی اجازت نہیں ملی۔ سیٹنگز میں SMS کی اجازت دیں۔',
  'khata_errorSmsSendFailed': 'SMS نہیں بھیجا جا سکا۔ {details}',
  'khata_errorSupplierArchived': 'یہ سپلائر آرکائیو شدہ ہے۔',
  'khata_errorSupplierNotFound': 'سپلائر نہیں ملا۔',
  'khata_errorTransferSameAccount': 'ایک ہی اکاؤنٹ میں منتقلی نہیں ہو سکتی۔',
  'khata_errorUnbalancedJournal': 'جرنل متوازن نہیں ہے۔',
  'khata_errorUnitNotFound': 'یونٹ نہیں ملا۔',
  'khata_gallery': 'گیلری',
  'khata_hisaabClear': 'حساب کلیئر ہے',
  'khata_imageAddKarein': 'تصویر شامل کریں',
  'khata_lastTransacted': 'آخری لین دین {date}',
  'khata_liye': 'لیے',
  'khata_maineDeneHain': 'میں نے دینے ہیں',
  'khata_maineLeneHain': 'میں نے لینے ہیں',
  'khata_maineyDiye': 'میں نے دیے',
  'khata_maineyLiye': 'میں نے لیے',
  'khata_noCamera': 'اس ڈیوائس پر کیمرہ دستیاب نہیں ہے۔',
  'khata_noDues': 'سب حساب برابر ہے',
  'khata_noDuesHint': 'کوئی بقایا رقم نہیں',
  'khata_noPhone': 'اس گاہک کا فون نمبر محفوظ نہیں ہے۔',
  'khata_remindersCount': 'یاد دہانیاں ({count} زائد المیعاد)',
  'khata_searchCustomer': 'گاہک تلاش کریں',
  'khata_searchSupplier': 'سپلائر تلاش کریں',
  'khata_sms': 'ایس ایم ایس',
  'khata_supplierSince': 'سپلائر از {date}',
  'khata_suppliers': 'سپلائرز',
  'khata_tareekhRakhein': 'تاریخ رکھیں',
  'khata_time': 'وقت',
  'khata_title': 'کھاتہ',
  'khata_toPay': 'ادا کرنا ہے',
  'khata_toReceive': 'وصول کرنا ہے',
  'khata_totalBalance': 'کل بیلنس',
  'khata_viewAllCustomers': 'گاہک دیکھیں',
  'khata_viewAllSuppliers': 'سپلائرز دیکھیں',
  'khata_whatsapp': 'واٹس ایپ',
  'production_addInput': 'ان پٹ شامل کریں',
  'production_addOutput': 'آؤٹ پٹ شامل کریں',
  'production_available': 'دستیاب: {qty} {unit}',
  'production_batchAuto': 'بیچ پوسٹ کرتے وقت خود بن جائے گا',
  'production_batchNo': 'بیچ نمبر',
  'production_costBreakdown': 'لاگت کی تفصیل',
  'production_costsCashHint': 'منتخب کرنے کی صورت میں مزدوری، بجلی اور دیگر اخراجات اس کھاتے سے پوسٹ ہوں گے۔',
  'production_date': 'تاریخ',
  'production_electricityCost': 'بجلی کی لاگت',
  'production_emptyInputs': 'کم از کم ایک ان پٹ شامل کریں',
  'production_emptyOutputs': 'کم از کم ایک آؤٹ پٹ شامل کریں',
  'production_errNegativeCost': 'لاگت منفی نہیں ہو سکتی',
  'production_expectedYield': 'متوقع پیداوار ٪ (اختیاری)',
  'production_inputs': 'خام مال (ان پٹ)',
  'production_inputsCount': '{count} ان پٹ',
  'production_labourCost': 'مزدوری کی لاگت',
  'production_materialCost': 'خام مال کی لاگت',
  'production_newBatch': 'نیا بیچ',
  'production_noBatches': 'ابھی کوئی بیچ نہیں بنا',
  'production_noBatchesHint': 'پہلا پیداواری بیچ شروع کریں۔',
  'production_notes': 'نوٹس',
  'production_otherCost': 'دیگر لاگت',
  'production_outOfStock': 'ابھی خام مال کی کوئی مصنوعات نہیں',
  'production_outputType': 'آؤٹ پٹ کی قسم',
  'production_outputs': 'آؤٹ پٹ',
  'production_payCostsFrom': 'اخراجات کی ادائیگی',
  'production_payCostsNone': 'کوئی نہیں (الگ سے درج کریں)',
  'production_postBatch': 'بیچ پوسٹ کریں',
  'production_qtyGtZero': 'مقدار صفر سے بڑی ہونی چاہیے',
  'production_rawOnly': 'ان پٹ کے لیے صرف خام مال کی مصنوعات',
  'production_removeLine': 'لائن ہٹائیں',
  'production_resultNoYield': 'پیداوار معلوم نہیں ہو سکی — استعمال شدہ اکائیوں کے لیے کلوگرام کا تبادلہ شامل کریں۔',
  'production_resultTitle': 'بیچ پوسٹ ہو گیا',
  'production_resultYield': 'پیداوار: {pct}٪',
  'production_selectProduct': 'مصنوعات منتخب کریں',
  'production_statusCostsPosted': 'اخراجات کیش بک میں',
  'production_statusPosted': 'پوسٹ شدہ',
  'production_title': 'پیداوار',
  'production_totalCost': 'کل لاگت',
  'production_typeByProduct': 'ضمنی پیداوار',
  'production_typeFinishedOil': 'تیار تیل',
  'production_typeOilCake': 'کھل',
  'production_wastage': 'ضیاع / نقصان',
  'production_yield': 'پیداوار کی شرح',
  'purchases_confirmPost': 'کیا یہ خریداری درج کریں؟ اسٹاک بڑھ جائے گا۔',
  'purchases_deleteDraft': 'مسودہ حذف کریں',
  'purchases_detailTitle': 'خریداری کی تفصیل',
  'purchases_draftDeleted': 'مسودہ حذف ہو گیا',
  'purchases_draftSaved': 'مسودہ {invoiceNo} محفوظ ہو گیا',
  'purchases_emptyTitle': 'ابھی کوئی خریداری نہیں',
  'purchases_formTitle': 'نئی خریداری',
  'purchases_lineItems': 'آئٹمز',
  'purchases_newPurchase': 'نئی خریداری',
  'purchases_noItems': 'کم از کم ایک آئٹم شامل کریں',
  'purchases_noSupplierSelected': 'پہلے سپلائر منتخب کریں',
  'purchases_payments': 'ادائیگیاں',
  'purchases_postDraft': 'مسودہ درج کریں',
  'purchases_postPurchase': 'خریداری درج کریں',
  'purchases_purchasePosted': 'خریداری {invoiceNo} درج ہو گئی',
  'purchases_recordPayment': 'ادائیگی درج کریں',
  'purchases_returnTitle': 'خریداری واپسی',
  'purchases_searchHint': 'واؤچر نمبر یا سپلائر تلاش کریں…',
  'purchases_searchSupplier': 'سپلائر تلاش کریں…',
  'purchases_selectSupplier': 'سپلائر منتخب کریں',
  'purchases_statusCancelled': 'منسوخ شدہ',
  'purchases_statusDraft': 'مسودہ',
  'purchases_statusPaid': 'ادا شدہ',
  'purchases_statusPartial': 'جزوی ادا شدہ',
  'purchases_statusReturned': 'واپس شدہ',
  'purchases_statusUnpaid': 'غیر ادا شدہ',
  'purchases_supplier': 'سپلائر',
  'purchases_title': 'خریداری',
  'purchases_voucherPdf': 'خریداری واؤچر PDF',
  'reminders_daysOverdue': '{days} دن سے واجب الادا',
  'reminders_dueOn': 'واجب الادا {date}',
  'reminders_editMessage': 'پیغام میں ترمیم کریں',
  'reminders_emptyMessage': 'کوئی واجب الادا یا آئندہ ادائیگی نہیں۔ سب کلیئر ہے!',
  'reminders_emptyTitle': 'کوئی یاددہانی نہیں',
  'reminders_failed': 'نہیں بھیجی جا سکی۔ دوبارہ کوشش کریں۔',
  'reminders_noPhone': '{name} کا فون نمبر محفوظ نہیں۔',
  'reminders_overdue': 'واجب الادا',
  'reminders_pickScript': 'پیغام کی زبان منتخب کریں',
  'reminders_scriptEnglish': 'انگریزی',
  'reminders_scriptUrdu': 'اردو',
  'reminders_send': 'بھیجیں',
  'reminders_sendSms': 'SMS یاددہانی بھیجیں',
  'reminders_sendWhatsapp': 'واٹس ایپ یاددہانی بھیجیں',
  'reminders_sent': 'یاددہانی بھیج دی گئی۔',
  'reminders_title': 'ادائیگی کی یاددہانی',
  'reminders_upcoming': 'آئندہ',
  'reports_accounts': 'اکاؤنٹس',
  'reports_all': 'تمام',
  'reports_avgCost': 'اوسط لاگت',
  'reports_avgYield': 'اوسط پیداواری شرح',
  'reports_batches': 'بیچز',
  'reports_cashBankBalances': 'نقد و بینک بیلنس',
  'reports_cashbook': 'کیش بک',
  'reports_change': 'تبدیل کریں',
  'reports_closingBalance': 'اختتامی بیلنس',
  'reports_copied': 'کلپ بورڈ میں نقل ہو گیا',
  'reports_copyReminder': 'یاددہانی نقل کریں',
  'reports_customRange': 'اپنی مدت',
  'reports_customerLedger': 'گاہک کھاتہ',
  'reports_customers': 'گاہک',
  'reports_dailySummary': 'یومیہ خلاصہ',
  'reports_daybook': 'روزنامچہ',
  'reports_doc_account': 'اکاؤنٹ',
  'reports_doc_amount': 'رقم',
  'reports_doc_balance': 'بیلنس',
  'reports_doc_bank': 'بینک',
  'reports_doc_batchNo': 'بیچ نمبر',
  'reports_doc_billTo': 'بل برائے',
  'reports_doc_byProduct': 'ذیلی پیداوار',
  'reports_doc_cash': 'نقد',
  'reports_doc_cashReceipt': 'نقد رسید',
  'reports_doc_category': 'زمرہ',
  'reports_doc_closingBalance': 'اختتامی بیلنس',
  'reports_doc_credit': 'کریڈٹ',
  'reports_doc_customer': 'گاہک',
  'reports_doc_customerStatement': 'گاہک کھاتہ اسٹیٹمنٹ',
  'reports_doc_date': 'تاریخ',
  'reports_doc_debit': 'ڈیبٹ',
  'reports_doc_description': 'تفصیل',
  'reports_doc_discount': 'رعایت',
  'reports_doc_due': 'بقایا رقم',
  'reports_doc_electricity': 'بجلی',
  'reports_doc_expenseVoucher': 'اخراجات کا واؤچر',
  'reports_doc_from': 'از',
  'reports_doc_generatedOn': '{date} کو تیار کردہ',
  'reports_doc_inputs': 'استعمال شدہ خام مال',
  'reports_doc_invoiceNo': 'انوائس نمبر',
  'reports_doc_item': 'آئٹم',
  'reports_doc_items': 'آئٹمز',
  'reports_doc_labour': 'مزدوری',
  'reports_doc_method': 'طریقہ',
  'reports_doc_notes': 'نوٹس',
  'reports_doc_oilCake': 'تیل کی کھلی',
  'reports_doc_openingBalance': 'ابتدائی بیلنس',
  'reports_doc_other': 'دیگر',
  'reports_doc_outputs': 'حاصل شدہ پیداوار',
  'reports_doc_paid': 'ادا شدہ',
  'reports_doc_paidTo': 'ادا شدہ بہ',
  'reports_doc_paymentReceipt': 'ادائیگی کی رسید',
  'reports_doc_pdfSaved': 'پی ڈی ایف محفوظ ہو گئی۔',
  'reports_doc_period': 'مدت',
  'reports_doc_price': 'قیمت',
  'reports_doc_print': 'پرنٹ کریں',
  'reports_doc_productionReport': 'پیداوار کی رپورٹ',
  'reports_doc_purchaseVoucher': 'خریداری واؤچر',
  'reports_doc_qty': 'مقدار',
  'reports_doc_receivedFrom': 'موصول از',
  'reports_doc_reference': 'حوالہ',
  'reports_doc_saleInvoice': 'فروخت انوائس',
  'reports_doc_savePdf': 'پی ڈی ایف محفوظ کریں',
  'reports_doc_share': 'شیئر کریں',
  'reports_doc_status': 'حالت',
  'reports_doc_subtotal': 'ذیلی میزان',
  'reports_doc_supplier': 'سپلائر',
  'reports_doc_supplierPaymentVoucher': 'سپلائر ادائیگی واؤچر',
  'reports_doc_supplierStatement': 'سپلائر کھاتہ اسٹیٹمنٹ',
  'reports_doc_tax': 'ٹیکس',
  'reports_doc_to': 'تا',
  'reports_doc_total': 'کل میزان',
  'reports_doc_yield': 'پیداواری شرح',
  'reports_due': 'بقایا',
  'reports_estimatedNote': 'تخمینہ — اس مدت کے لاگت کے اعداد و شمار نامکمل ہیں۔',
  'reports_expense': 'اخراجات',
  'reports_expensesByCategory': 'زمرہ کے حساب سے اخراجات',
  'reports_grandTotal': 'مجموعی میزان',
  'reports_income': 'آمدنی',
  'reports_inventoryValuation': 'اسٹاک کی مالیت',
  'reports_invoices': 'انوائسز',
  'reports_lowStock': 'کم اسٹاک',
  'reports_monthlySummary': 'ماہانہ خلاصہ',
  'reports_netLoss': 'خالص نقصان',
  'reports_netProfit': 'خالص نفع',
  'reports_noData': 'اس مدت کے لیے کوئی ڈیٹا نہیں ہے۔',
  'reports_onHand': 'موجودہ اسٹاک',
  'reports_openingBalance': 'ابتدائی بیلنس',
  'reports_outstandingInvoices': 'بقایا انوائسز',
  'reports_paid': 'ادا شدہ',
  'reports_partial': 'جزوی ادائیگی',
  'reports_payables': 'قابلِ ادائیگی رقوم',
  'reports_paymentsMade': 'ادا شدہ ادائیگیاں',
  'reports_paymentsReceived': 'موصولہ ادائیگیاں',
  'reports_pickDate': 'تاریخ منتخب کریں',
  'reports_pickMonth': 'مہینہ منتخب کریں',
  'reports_production': 'پیداوار',
  'reports_profitLoss': 'نفع و نقصان',
  'reports_purchase': 'خریداری',
  'reports_purchaseInvoices': 'خریداری کی انوائسز',
  'reports_purchaseReturns': 'خریداری واپسی',
  'reports_quantity': 'مقدار',
  'reports_receivables': 'قابلِ وصول رقوم',
  'reports_recordsCount': '{count} ریکارڈ',
  'reports_reorderLevel': 'دوبارہ آرڈر کی حد',
  'reports_saleInvoices': 'فروخت کی انوائسز',
  'reports_sales': 'فروخت',
  'reports_salesReturns': 'فروخت واپسی',
  'reports_selectAccount': 'اکاؤنٹ منتخب کریں',
  'reports_selectCustomer': 'گاہک منتخب کریں',
  'reports_selectProduct': 'پراڈکٹ منتخب کریں',
  'reports_selectSupplier': 'سپلائر منتخب کریں',
  'reports_stockMovement': 'اسٹاک کی نقل و حرکت',
  'reports_stockValue': 'اسٹاک کی مالیت',
  'reports_supplierLedger': 'سپلائر کھاتہ',
  'reports_suppliers': 'سپلائرز',
  'reports_title': 'رپورٹس',
  'reports_totalExpenses': 'کل اخراجات',
  'reports_totalIncome': 'کل آمدنی',
  'reports_totalPaid': 'کل ادائیگی',
  'reports_totalPurchases': 'کل خریداری',
  'reports_totalReceived': 'کل موصول',
  'reports_totalSales': 'کل فروخت',
  'reports_trialBalance': 'ٹرائل بیلنس',
  'reports_unpaid': 'غیر ادا شدہ',
  'reports_value': 'مالیت',
  'reports_yield': 'پیداواری شرح',
  'sales_apniMarzi': 'اپنی مرضی',
  'sales_confirmPost': 'کیا یہ فروخت درج کریں؟ اسٹاک کم ہو جائے گا۔',
  'sales_customer': 'گاہک',
  'sales_deleteDraft': 'مسودہ حذف کریں',
  'sales_detailTitle': 'فروخت کی تفصیل',
  'sales_draftDeleted': 'مسودہ حذف ہو گیا',
  'sales_draftSaved': 'مسودہ {invoiceNo} محفوظ ہو گیا',
  'sales_emptyTitle': 'ابھی کوئی فروخت نہیں',
  'sales_formTitle': 'نئی فروخت',
  'sales_haaliSales': 'حالیہ فروخت',
  'sales_hafta': 'ہفتہ',
  'sales_invoicePdf': 'انوائس PDF',
  'sales_itemsManage': 'آئٹمز مینج کریں',
  'sales_itemsManageHint': 'جو چیزیں بیچتے ہیں انہیں شامل، اپ ڈیٹ یا حذف کریں',
  'sales_kullNaqad': 'کل نقد',
  'sales_kullOrders': 'کل آرڈرز',
  'sales_kullSales': 'کل فروخت',
  'sales_kullUdhaar': 'کل ادھار',
  'sales_lineItems': 'آئٹمز',
  'sales_maheena': 'مہینہ',
  'sales_manageItems': 'آئٹمز',
  'sales_nataij': '{count} نتائج',
  'sales_newSale': 'نئی فروخت',
  'sales_noCustomerSelected': 'پہلے گاہک منتخب کریں',
  'sales_noItems': 'کم از کم ایک آئٹم شامل کریں',
  'sales_noSalesPeriod': 'اس مدت میں کوئی فروخت نہیں',
  'sales_payments': 'ادائیگیاں',
  'sales_periodCustom': 'اس مدت میں',
  'sales_periodHafta': 'اس ہفتے',
  'sales_periodMaheena': 'اس مہینے',
  'sales_postDraft': 'مسودہ درج کریں',
  'sales_postSale': 'فروخت درج کریں',
  'sales_recordPayment': 'ادائیگی درج کریں',
  'sales_returnTitle': 'فروخت واپسی',
  'sales_saleDarjKarein': 'سیل درج کریں',
  'sales_salePosted': 'فروخت {invoiceNo} درج ہو گئی',
  'sales_searchCustomer': 'گاہک تلاش کریں…',
  'sales_searchHint': 'انوائس نمبر یا گاہک تلاش کریں…',
  'sales_searchSales': 'نام یا رقم سے تلاش کریں',
  'sales_selectCustomer': 'گاہک منتخب کریں',
  'sales_share': 'شیئر کریں',
  'sales_statusCancelled': 'منسوخ شدہ',
  'sales_statusDraft': 'مسودہ',
  'sales_statusPaid': 'ادا شدہ',
  'sales_statusPartial': 'جزوی ادا شدہ',
  'sales_statusReturned': 'واپس شدہ',
  'sales_statusUnpaid': 'غیر ادا شدہ',
  'sales_title': 'فروخت',
  'transactions_account': 'اکاؤنٹ',
  'transactions_addItem': 'آئٹم شامل کریں',
  'transactions_adjustment': 'ایڈجسٹمنٹ',
  'transactions_bank': 'بینک',
  'transactions_cash': 'نقد',
  'transactions_category': 'زمرہ',
  'transactions_credit': 'کریڈٹ',
  'transactions_customRange': 'مرضی کی مدت',
  'transactions_customRangeHint': '{from} – {to}',
  'transactions_customRangeTitle': 'مدت منتخب کریں',
  'transactions_date': 'تاریخ',
  'transactions_debit': 'ڈیبٹ',
  'transactions_description': 'تفصیل',
  'transactions_detailTitle': 'لین دین کی تفصیل',
  'transactions_discount': 'رعایت',
  'transactions_discountPct': 'رعایت ٪',
  'transactions_due': 'بقایا',
  'transactions_emptyTitle': 'کوئی لین دین نہیں',
  'transactions_entriesCount': '{count} اندراجات',
  'transactions_entryNo': 'اندراج نمبر',
  'transactions_expense': 'اخراجات',
  'transactions_filterAll': 'تمام',
  'transactions_filterPaymentPaid': 'ادا شدہ ادائیگی',
  'transactions_filterPaymentReceived': 'موصولہ ادائیگی',
  'transactions_income': 'آمدنی',
  'transactions_invalidPrice': 'درست قیمت درج کریں',
  'transactions_invalidQty': 'درست مقدار درج کریں',
  'transactions_invoiceDiscount': 'انوائس رعایت ٪',
  'transactions_lineTotal': 'لائن کل',
  'transactions_maxQty': 'زیادہ سے زیادہ {qty}',
  'transactions_noDescription': '—',
  'transactions_notes': 'نوٹس',
  'transactions_paidAmount': 'ابھی ادائیگی',
  'transactions_paymentAccount': 'اکاؤنٹ',
  'transactions_paymentAmount': 'رقم',
  'transactions_paymentMethod': 'طریقہ',
  'transactions_paymentReference': 'حوالہ',
  'transactions_paymentSaved': 'ادائیگی محفوظ ہو گئی',
  'transactions_paymentTitle': 'ادائیگی درج کریں',
  'transactions_production': 'پیداوار',
  'transactions_purchase': 'خریداری',
  'transactions_qty': 'مقدار',
  'transactions_reference': 'حوالہ',
  'transactions_removeLine': 'لائن ہٹائیں',
  'transactions_return': 'واپسی',
  'transactions_returnPosted': 'واپسی درج ہو گئی',
  'transactions_returnReason': 'وجہ (اختیاری)',
  'transactions_returnTitle': 'آئٹم واپسی',
  'transactions_reversal': 'تنسیخی اندراج',
  'transactions_reversalOf': '{entryNo} کی تنسیخ',
  'transactions_reversed': 'کالعدم',
  'transactions_sale': 'فروخت',
  'transactions_saveDraft': 'مسودہ محفوظ کریں',
  'transactions_searchHint': 'تفصیل یا اندراج نمبر تلاش کریں…',
  'transactions_searchProduct': 'مصنوعات تلاش کریں…',
  'transactions_selectProduct': 'مصنوعات منتخب کریں',
  'transactions_sortNewest': 'تازہ ترین',
  'transactions_sortOldest': 'قدیم ترین',
  'transactions_submitPayment': 'ادائیگی محفوظ کریں',
  'transactions_submitReturn': 'واپسی درج کریں',
  'transactions_subtotal': 'ذیلی کل',
  'transactions_tax': 'ٹیکس',
  'transactions_taxPct': 'ٹیکس ٪',
  'transactions_title': 'لین دین',
  'transactions_total': 'جرنل کل',
  'transactions_transfer': 'منتقلی',
  'transactions_unit': 'اکائی',
  'transactions_unitPrice': 'فی اکائی قیمت',
  'udhaar_saved': 'ادھار درج کر دیا گیا',
  'udhaar_title': 'ادھار دیں',
};

/// Localised strings for the wave-2 modules (Agents C/D/E/F).
///
/// Usage: `final t = FragmentStrings.of(context); Text(t.reports_title)`
/// Falls back to English, then to the key itself — never throws.
class FragmentStrings {
  final Map<String, String> _map;
  const FragmentStrings._(this._map);

  /// Picks the fragment table matching the ambient locale.
  static FragmentStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return FragmentStrings._(code == 'ur' ? _fragmentUr : _fragmentEn);
  }

  String _t(String key) => _map[key] ?? _fragmentEn[key] ?? key;

  String _f(String key, Map<String, Object?> params) {
    var s = _t(key);
    params.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));
    return s;
  }

  String get backup_chooseFile => _t('backup_chooseFile');
  String get backup_confirmMessage => _t('backup_confirmMessage');
  String get backup_confirmRestore => _t('backup_confirmRestore');
  String get backup_confirmTitle => _t('backup_confirmTitle');
  String get backup_create => _t('backup_create');
  String backup_created({required Object count, required Object tables}) => _f('backup_created', {'count': count, 'tables': tables});
  String get backup_creating => _t('backup_creating');
  String get backup_driveAutoBackup => _t('backup_driveAutoBackup');
  String get backup_driveAutoBackupHint => _t('backup_driveAutoBackupHint');
  String backup_driveBackupFailed({required Object error}) => _f('backup_driveBackupFailed', {'error': error});
  String get backup_driveBackupNow => _t('backup_driveBackupNow');
  String backup_driveBackupSaved({required Object name}) => _f('backup_driveBackupSaved', {'name': name});
  String get backup_driveConnect => _t('backup_driveConnect');
  String get backup_driveConnectFailed => _t('backup_driveConnectFailed');
  String get backup_driveConnectIntro => _t('backup_driveConnectIntro');
  String backup_driveConnected({required Object email}) => _f('backup_driveConnected', {'email': email});
  String get backup_driveDisconnect => _t('backup_driveDisconnect');
  String get backup_driveDisconnectMessage => _t('backup_driveDisconnectMessage');
  String get backup_driveDisconnectTitle => _t('backup_driveDisconnectTitle');
  String backup_driveExportFailed({required Object error}) => _f('backup_driveExportFailed', {'error': error});
  String get backup_driveExportRange => _t('backup_driveExportRange');
  String backup_driveExportSaved({required Object name}) => _f('backup_driveExportSaved', {'name': name});
  String backup_driveLastBackup({required Object date}) => _f('backup_driveLastBackup', {'date': date});
  String get backup_driveNoBackupYet => _t('backup_driveNoBackupYet');
  String get backup_driveTitle => _t('backup_driveTitle');
  String backup_errorChecksum({required Object table}) => _f('backup_errorChecksum', {'table': table});
  String get backup_errorInvalidFile => _t('backup_errorInvalidFile');
  String backup_errorMissingTables({required Object tables}) => _f('backup_errorMissingTables', {'tables': tables});
  String backup_errorUnsupportedVersion({required Object version}) => _f('backup_errorUnsupportedVersion', {'version': version});
  String backup_exportedAt({required Object date}) => _f('backup_exportedAt', {'date': date});
  String get backup_intro => _t('backup_intro');
  String get backup_reading => _t('backup_reading');
  String backup_recordsCount({required Object count}) => _f('backup_recordsCount', {'count': count});
  String get backup_restore => _t('backup_restore');
  String backup_restored({required Object count}) => _f('backup_restored', {'count': count});
  String get backup_restoring => _t('backup_restoring');
  String backup_savedTo({required Object path}) => _f('backup_savedTo', {'path': path});
  String get backup_summaryTitle => _t('backup_summaryTitle');
  String backup_tablesCount({required Object count}) => _f('backup_tablesCount', {'count': count});
  String get backup_title => _t('backup_title');
  String get cashbook_accountName => _t('cashbook_accountName');
  String get cashbook_accountType => _t('cashbook_accountType');
  String get cashbook_accounts => _t('cashbook_accounts');
  String get cashbook_addAccount => _t('cashbook_addAccount');
  String get cashbook_addPayment => _t('cashbook_addPayment');
  String get cashbook_addReceipt => _t('cashbook_addReceipt');
  String get cashbook_amount => _t('cashbook_amount');
  String get cashbook_balance => _t('cashbook_balance');
  String get cashbook_customer => _t('cashbook_customer');
  String get cashbook_date => _t('cashbook_date');
  String get cashbook_editAccount => _t('cashbook_editAccount');
  String get cashbook_entries => _t('cashbook_entries');
  String get cashbook_errAccountNotFound => _t('cashbook_errAccountNotFound');
  String get cashbook_errInvalidAmount => _t('cashbook_errInvalidAmount');
  String get cashbook_errTransferSame => _t('cashbook_errTransferSame');
  String get cashbook_from => _t('cashbook_from');
  String get cashbook_in => _t('cashbook_in');
  String get cashbook_method => _t('cashbook_method');
  String get cashbook_methodBank => _t('cashbook_methodBank');
  String get cashbook_methodCash => _t('cashbook_methodCash');
  String get cashbook_newTransfer => _t('cashbook_newTransfer');
  String get cashbook_noAccounts => _t('cashbook_noAccounts');
  String get cashbook_noEntries => _t('cashbook_noEntries');
  String get cashbook_notes => _t('cashbook_notes');
  String get cashbook_openingBalance => _t('cashbook_openingBalance');
  String get cashbook_out => _t('cashbook_out');
  String get cashbook_payment => _t('cashbook_payment');
  String get cashbook_pickAccount => _t('cashbook_pickAccount');
  String get cashbook_receipt => _t('cashbook_receipt');
  String get cashbook_reference => _t('cashbook_reference');
  String get cashbook_selectCustomer => _t('cashbook_selectCustomer');
  String get cashbook_selectSupplier => _t('cashbook_selectSupplier');
  String get cashbook_supplier => _t('cashbook_supplier');
  String get cashbook_title => _t('cashbook_title');
  String get cashbook_to => _t('cashbook_to');
  String get cashbook_totalIn => _t('cashbook_totalIn');
  String get cashbook_totalOut => _t('cashbook_totalOut');
  String get cashbook_transfer => _t('cashbook_transfer');
  String get cashbook_transferInfo => _t('cashbook_transferInfo');
  String get cashbook_typeBank => _t('cashbook_typeBank');
  String get cashbook_typeCash => _t('cashbook_typeCash');
  String get common_cancel => _t('common_cancel');
  String get customers_account => _t('customers_account');
  String get customers_addCustomer => _t('customers_addCustomer');
  String get customers_addFirstHint => _t('customers_addFirstHint');
  String get customers_addFirstSupplierHint => _t('customers_addFirstSupplierHint');
  String get customers_addSupplier => _t('customers_addSupplier');
  String get customers_address => _t('customers_address');
  String get customers_amount => _t('customers_amount');
  String get customers_archive => _t('customers_archive');
  String get customers_archiveMessage => _t('customers_archiveMessage');
  String customers_archiveTitle({required Object name}) => _f('customers_archiveTitle', {'name': name});
  String get customers_bank => _t('customers_bank');
  String get customers_businessName => _t('customers_businessName');
  String get customers_cash => _t('customers_cash');
  String get customers_code => _t('customers_code');
  String get customers_copied => _t('customers_copied');
  String get customers_copyText => _t('customers_copyText');
  String get customers_customRange => _t('customers_customRange');
  String get customers_customerArchived => _t('customers_customerArchived');
  String get customers_customerRestored => _t('customers_customerRestored');
  String get customers_date => _t('customers_date');
  String get customers_editCustomer => _t('customers_editCustomer');
  String get customers_editSupplier => _t('customers_editSupplier');
  String get customers_englishVersion => _t('customers_englishVersion');
  String get customers_filterAdvance => _t('customers_filterAdvance');
  String get customers_filterAdvancePaid => _t('customers_filterAdvancePaid');
  String get customers_filterAll => _t('customers_filterAll');
  String get customers_filterPayable => _t('customers_filterPayable');
  String get customers_filterReceivable => _t('customers_filterReceivable');
  String get customers_giveUdhaar => _t('customers_giveUdhaar');
  String get customers_ledgerTitle => _t('customers_ledgerTitle');
  String get customers_makePayment => _t('customers_makePayment');
  String get customers_method => _t('customers_method');
  String get customers_name => _t('customers_name');
  String get customers_newCustomer => _t('customers_newCustomer');
  String get customers_newSupplier => _t('customers_newSupplier');
  String get customers_noCustomers => _t('customers_noCustomers');
  String get customers_noEntries => _t('customers_noEntries');
  String get customers_noMatch => _t('customers_noMatch');
  String get customers_noSuppliers => _t('customers_noSuppliers');
  String get customers_notFound => _t('customers_notFound');
  String get customers_note => _t('customers_note');
  String get customers_notes => _t('customers_notes');
  String get customers_openingBalance => _t('customers_openingBalance');
  String get customers_openingBalanceHint => _t('customers_openingBalanceHint');
  String get customers_openingBalanceLabel => _t('customers_openingBalanceLabel');
  String get customers_openingHelpCustomer => _t('customers_openingHelpCustomer');
  String get customers_openingHelpSupplier => _t('customers_openingHelpSupplier');
  String get customers_paymentSaved => _t('customers_paymentSaved');
  String get customers_paymentTitlePay => _t('customers_paymentTitlePay');
  String get customers_paymentTitleReceive => _t('customers_paymentTitleReceive');
  String get customers_phone => _t('customers_phone');
  String get customers_receivePayment => _t('customers_receivePayment');
  String get customers_recordPurchase => _t('customers_recordPurchase');
  String get customers_reminder => _t('customers_reminder');
  String get customers_reminderTitle => _t('customers_reminderTitle');
  String get customers_saved => _t('customers_saved');
  String get customers_searchHint => _t('customers_searchHint');
  String get customers_searchLedgerHint => _t('customers_searchLedgerHint');
  String get customers_selectAccount => _t('customers_selectAccount');
  String get customers_statement => _t('customers_statement');
  String get customers_supplierArchived => _t('customers_supplierArchived');
  String get customers_supplierRestored => _t('customers_supplierRestored');
  String get customers_supplierTitle => _t('customers_supplierTitle');
  String get customers_title => _t('customers_title');
  String get customers_totalCredit => _t('customers_totalCredit');
  String get customers_totalPaid => _t('customers_totalPaid');
  String get customers_totalPurchases => _t('customers_totalPurchases');
  String get customers_totalReceived => _t('customers_totalReceived');
  String get customers_unarchive => _t('customers_unarchive');
  String get customers_urduVersion => _t('customers_urduVersion');
  String get customers_viewLedger => _t('customers_viewLedger');
  String get customers_waAdd => _t('customers_waAdd');
  String customers_waAddMessage({required Object name}) => _f('customers_waAddMessage', {'name': name});
  String get customers_waAddTitle => _t('customers_waAddTitle');
  String get customers_waOpenChat => _t('customers_waOpenChat');
  String get customers_waOpenFailed => _t('customers_waOpenFailed');
  String get customers_waSendStatement => _t('customers_waSendStatement');
  String get customers_waSendStatementHint => _t('customers_waSendStatementHint');
  String customers_waStatementText({required Object name}) => _f('customers_waStatementText', {'name': name});
  String get customers_whatsappNumber => _t('customers_whatsappNumber');
  String get dashboard_activityExpense => _t('dashboard_activityExpense');
  String get dashboard_activityIncome => _t('dashboard_activityIncome');
  String get dashboard_activityPaymentIn => _t('dashboard_activityPaymentIn');
  String get dashboard_activityPaymentOut => _t('dashboard_activityPaymentOut');
  String dashboard_activityPurchase({required Object no}) => _f('dashboard_activityPurchase', {'no': no});
  String dashboard_activitySale({required Object no}) => _f('dashboard_activitySale', {'no': no});
  String get dashboard_bankBalance => _t('dashboard_bankBalance');
  String get dashboard_cashInHand => _t('dashboard_cashInHand');
  String get dashboard_lowStock => _t('dashboard_lowStock');
  String get dashboard_lowStockOk => _t('dashboard_lowStockOk');
  String get dashboard_monthExpense => _t('dashboard_monthExpense');
  String get dashboard_monthIncome => _t('dashboard_monthIncome');
  String get dashboard_noActivity => _t('dashboard_noActivity');
  String get dashboard_noActivityHint => _t('dashboard_noActivityHint');
  String get dashboard_paidToday => _t('dashboard_paidToday');
  String get dashboard_pickCustomer => _t('dashboard_pickCustomer');
  String get dashboard_pickSupplier => _t('dashboard_pickSupplier');
  String get dashboard_qaAddCustomer => _t('dashboard_qaAddCustomer');
  String get dashboard_qaAddExpense => _t('dashboard_qaAddExpense');
  String get dashboard_qaAddPurchase => _t('dashboard_qaAddPurchase');
  String get dashboard_qaAddSale => _t('dashboard_qaAddSale');
  String get dashboard_qaAddSupplier => _t('dashboard_qaAddSupplier');
  String get dashboard_qaGiveUdhaar => _t('dashboard_qaGiveUdhaar');
  String get dashboard_qaMakePayment => _t('dashboard_qaMakePayment');
  String get dashboard_qaReceivePayment => _t('dashboard_qaReceivePayment');
  String get dashboard_qaRecordProduction => _t('dashboard_qaRecordProduction');
  String get dashboard_qaViewReports => _t('dashboard_qaViewReports');
  String get dashboard_quickActions => _t('dashboard_quickActions');
  String get dashboard_receivedToday => _t('dashboard_receivedToday');
  String get dashboard_recentActivity => _t('dashboard_recentActivity');
  String dashboard_stockLeft({required Object qty, required Object unit}) => _f('dashboard_stockLeft', {'qty': qty, 'unit': unit});
  String get dashboard_thisMonth => _t('dashboard_thisMonth');
  String get dashboard_title => _t('dashboard_title');
  String get dashboard_today => _t('dashboard_today');
  String get dashboard_todayPurchases => _t('dashboard_todayPurchases');
  String get dashboard_todaySales => _t('dashboard_todaySales');
  String get dashboard_totalBalance => _t('dashboard_totalBalance');
  String get dashboard_totalPayable => _t('dashboard_totalPayable');
  String get dashboard_totalReceivable => _t('dashboard_totalReceivable');
  String get dashboard_viewAll => _t('dashboard_viewAll');
  String get expenses_account => _t('expenses_account');
  String get expenses_addCategory => _t('expenses_addCategory');
  String get expenses_addExpense => _t('expenses_addExpense');
  String get expenses_addIncome => _t('expenses_addIncome');
  String get expenses_amount => _t('expenses_amount');
  String get expenses_category => _t('expenses_category');
  String get expenses_categoryName => _t('expenses_categoryName');
  String get expenses_categorySaved => _t('expenses_categorySaved');
  String get expenses_date => _t('expenses_date');
  String get expenses_description => _t('expenses_description');
  String get expenses_errAccountNotFound => _t('expenses_errAccountNotFound');
  String get expenses_errCategoryNotFound => _t('expenses_errCategoryNotFound');
  String get expenses_errInvalidAmount => _t('expenses_errInvalidAmount');
  String get expenses_expenseSaved => _t('expenses_expenseSaved');
  String get expenses_incomeCategory => _t('expenses_incomeCategory');
  String get expenses_incomeSaved => _t('expenses_incomeSaved');
  String get expenses_noEntries => _t('expenses_noEntries');
  String get expenses_reference => _t('expenses_reference');
  String get expenses_tabExpenses => _t('expenses_tabExpenses');
  String get expenses_tabIncome => _t('expenses_tabIncome');
  String get expenses_thisMonth => _t('expenses_thisMonth');
  String get expenses_thisYear => _t('expenses_thisYear');
  String get expenses_title => _t('expenses_title');
  String get expenses_today => _t('expenses_today');
  String get expenses_totalExpenses => _t('expenses_totalExpenses');
  String get expenses_totalIncome => _t('expenses_totalIncome');
  String get inventory_addConversion => _t('inventory_addConversion');
  String get inventory_addProduct => _t('inventory_addProduct');
  String get inventory_adjust => _t('inventory_adjust');
  String get inventory_adjustment => _t('inventory_adjustment');
  String get inventory_all => _t('inventory_all');
  String get inventory_available => _t('inventory_available');
  String get inventory_avgCost => _t('inventory_avgCost');
  String get inventory_catConsumable => _t('inventory_catConsumable');
  String get inventory_catContainer => _t('inventory_catContainer');
  String get inventory_catFinishedOil => _t('inventory_catFinishedOil');
  String get inventory_catOilCake => _t('inventory_catOilCake');
  String get inventory_catPackaging => _t('inventory_catPackaging');
  String get inventory_catRawMaterial => _t('inventory_catRawMaterial');
  String get inventory_catSpare => _t('inventory_catSpare');
  String get inventory_category => _t('inventory_category');
  String get inventory_conversionExists => _t('inventory_conversionExists');
  String get inventory_conversionsTitle => _t('inventory_conversionsTitle');
  String get inventory_editConversion => _t('inventory_editConversion');
  String get inventory_editProduct => _t('inventory_editProduct');
  String get inventory_errDatabase => _t('inventory_errDatabase');
  String inventory_errInsufficientStock({required Object available, required Object needed, required Object product}) => _f('inventory_errInsufficientStock', {'available': available, 'needed': needed, 'product': product});
  String get inventory_errInvalidAmount => _t('inventory_errInvalidAmount');
  String get inventory_errInvalidQty => _t('inventory_errInvalidQty');
  String get inventory_errNoConversion => _t('inventory_errNoConversion');
  String get inventory_errProductNotFound => _t('inventory_errProductNotFound');
  String get inventory_factor => _t('inventory_factor');
  String inventory_factorHint({required Object from, required Object to}) => _f('inventory_factorHint', {'from': from, 'to': to});
  String get inventory_factorPositive => _t('inventory_factorPositive');
  String get inventory_from => _t('inventory_from');
  String get inventory_in => _t('inventory_in');
  String get inventory_lowStock => _t('inventory_lowStock');
  String get inventory_movements => _t('inventory_movements');
  String get inventory_name => _t('inventory_name');
  String get inventory_noConversions => _t('inventory_noConversions');
  String get inventory_noMovements => _t('inventory_noMovements');
  String get inventory_noProducts => _t('inventory_noProducts');
  String get inventory_noProductsHint => _t('inventory_noProductsHint');
  String get inventory_openingStock => _t('inventory_openingStock');
  String get inventory_openingStockReason => _t('inventory_openingStockReason');
  String get inventory_out => _t('inventory_out');
  String get inventory_productSaved => _t('inventory_productSaved');
  String get inventory_qty => _t('inventory_qty');
  String get inventory_reason => _t('inventory_reason');
  String get inventory_reasonRequired => _t('inventory_reasonRequired');
  String get inventory_reorderLevel => _t('inventory_reorderLevel');
  String get inventory_salePrice => _t('inventory_salePrice');
  String get inventory_searchHint => _t('inventory_searchHint');
  String get inventory_sku => _t('inventory_sku');
  String get inventory_stock => _t('inventory_stock');
  String get inventory_stockIn => _t('inventory_stockIn');
  String get inventory_stockInReason => _t('inventory_stockInReason');
  String get inventory_stockOut => _t('inventory_stockOut');
  String get inventory_stockOutReason => _t('inventory_stockOutReason');
  String get inventory_stockUpdated => _t('inventory_stockUpdated');
  String get inventory_stockValue => _t('inventory_stockValue');
  String get inventory_title => _t('inventory_title');
  String get inventory_to => _t('inventory_to');
  String get inventory_typeAdjustment => _t('inventory_typeAdjustment');
  String get inventory_typeProduction => _t('inventory_typeProduction');
  String get inventory_typePurchase => _t('inventory_typePurchase');
  String get inventory_typeReturn => _t('inventory_typeReturn');
  String get inventory_typeSale => _t('inventory_typeSale');
  String get inventory_unit => _t('inventory_unit');
  String get inventory_units => _t('inventory_units');
  String get inventory_unitsTitle => _t('inventory_unitsTitle');
  String get khata_addBills => _t('khata_addBills');
  String get khata_addCustomerBtn => _t('khata_addCustomerBtn');
  String get khata_addSupplierBtn => _t('khata_addSupplierBtn');
  String khata_balAfter({required Object amount}) => _f('khata_balAfter', {'amount': amount});
  String get khata_billAttached => _t('khata_billAttached');
  String get khata_businessName => _t('khata_businessName');
  String get khata_camera => _t('khata_camera');
  String khata_customerSince({required Object date}) => _f('khata_customerSince', {'date': date});
  String get khata_customers => _t('khata_customers');
  String get khata_diye => _t('khata_diye');
  String get khata_errorAccountInactive => _t('khata_errorAccountInactive');
  String get khata_errorAccountNotFound => _t('khata_errorAccountNotFound');
  String get khata_errorAlreadyReversed => _t('khata_errorAlreadyReversed');
  String get khata_errorCategoryInactive => _t('khata_errorCategoryInactive');
  String get khata_errorCategoryNotFound => _t('khata_errorCategoryNotFound');
  String get khata_errorCustomerArchived => _t('khata_errorCustomerArchived');
  String get khata_errorCustomerNotFound => _t('khata_errorCustomerNotFound');
  String get khata_errorDatabase => _t('khata_errorDatabase');
  String get khata_errorDriveConnectFailed => _t('khata_errorDriveConnectFailed');
  String get khata_errorDriveSignInCanceled => _t('khata_errorDriveSignInCanceled');
  String get khata_errorDriveSignInInterrupted => _t('khata_errorDriveSignInInterrupted');
  String get khata_errorEmptyBatchInputs => _t('khata_errorEmptyBatchInputs');
  String get khata_errorEmptyBatchOutputs => _t('khata_errorEmptyBatchOutputs');
  String get khata_errorEmptyInvoice => _t('khata_errorEmptyInvoice');
  String get khata_errorEmptyJournal => _t('khata_errorEmptyJournal');
  String get khata_errorEmptyReturn => _t('khata_errorEmptyReturn');
  String get khata_errorEntryNotFound => _t('khata_errorEntryNotFound');
  String khata_errorInsufficientStock({required Object product}) => _f('khata_errorInsufficientStock', {'product': product});
  String get khata_errorInvalidAmount => _t('khata_errorInvalidAmount');
  String get khata_errorInvalidJournalLine => _t('khata_errorInvalidJournalLine');
  String get khata_errorInvalidQty => _t('khata_errorInvalidQty');
  String get khata_errorInvoiceNotFound => _t('khata_errorInvoiceNotFound');
  String get khata_errorMethodAccountMismatch => _t('khata_errorMethodAccountMismatch');
  String get khata_errorNegativeCost => _t('khata_errorNegativeCost');
  String get khata_errorNegativePrice => _t('khata_errorNegativePrice');
  String get khata_errorNegativeTax => _t('khata_errorNegativeTax');
  String get khata_errorNegativeTotal => _t('khata_errorNegativeTotal');
  String get khata_errorNoConversion => _t('khata_errorNoConversion');
  String get khata_errorNotADraft => _t('khata_errorNotADraft');
  String get khata_errorOilCostAllocation => _t('khata_errorOilCostAllocation');
  String get khata_errorOverAllocated => _t('khata_errorOverAllocated');
  String get khata_errorOverAllocatedInvoice => _t('khata_errorOverAllocatedInvoice');
  String get khata_errorProductArchived => _t('khata_errorProductArchived');
  String get khata_errorProductNotFound => _t('khata_errorProductNotFound');
  String get khata_errorReasonRequired => _t('khata_errorReasonRequired');
  String get khata_errorReturnExceedsBought => _t('khata_errorReturnExceedsBought');
  String get khata_errorReturnExceedsSold => _t('khata_errorReturnExceedsSold');
  String get khata_errorSmsChannelMissing => _t('khata_errorSmsChannelMissing');
  String get khata_errorSmsEmptyMessage => _t('khata_errorSmsEmptyMessage');
  String get khata_errorSmsGeneric => _t('khata_errorSmsGeneric');
  String get khata_errorSmsNoNumber => _t('khata_errorSmsNoNumber');
  String get khata_errorSmsNotAvailable => _t('khata_errorSmsNotAvailable');
  String get khata_errorSmsPermissionDenied => _t('khata_errorSmsPermissionDenied');
  String khata_errorSmsSendFailed({required Object details}) => _f('khata_errorSmsSendFailed', {'details': details});
  String get khata_errorSupplierArchived => _t('khata_errorSupplierArchived');
  String get khata_errorSupplierNotFound => _t('khata_errorSupplierNotFound');
  String get khata_errorTransferSameAccount => _t('khata_errorTransferSameAccount');
  String get khata_errorUnbalancedJournal => _t('khata_errorUnbalancedJournal');
  String get khata_errorUnitNotFound => _t('khata_errorUnitNotFound');
  String get khata_gallery => _t('khata_gallery');
  String get khata_hisaabClear => _t('khata_hisaabClear');
  String get khata_imageAddKarein => _t('khata_imageAddKarein');
  String khata_lastTransacted({required Object date}) => _f('khata_lastTransacted', {'date': date});
  String get khata_liye => _t('khata_liye');
  String get khata_maineDeneHain => _t('khata_maineDeneHain');
  String get khata_maineLeneHain => _t('khata_maineLeneHain');
  String get khata_maineyDiye => _t('khata_maineyDiye');
  String get khata_maineyLiye => _t('khata_maineyLiye');
  String get khata_noCamera => _t('khata_noCamera');
  String get khata_noDues => _t('khata_noDues');
  String get khata_noDuesHint => _t('khata_noDuesHint');
  String get khata_noPhone => _t('khata_noPhone');
  String khata_remindersCount({required Object count}) => _f('khata_remindersCount', {'count': count});
  String get khata_searchCustomer => _t('khata_searchCustomer');
  String get khata_searchSupplier => _t('khata_searchSupplier');
  String get khata_sms => _t('khata_sms');
  String khata_supplierSince({required Object date}) => _f('khata_supplierSince', {'date': date});
  String get khata_suppliers => _t('khata_suppliers');
  String get khata_tareekhRakhein => _t('khata_tareekhRakhein');
  String get khata_time => _t('khata_time');
  String get khata_title => _t('khata_title');
  String get khata_toPay => _t('khata_toPay');
  String get khata_toReceive => _t('khata_toReceive');
  String get khata_totalBalance => _t('khata_totalBalance');
  String get khata_viewAllCustomers => _t('khata_viewAllCustomers');
  String get khata_viewAllSuppliers => _t('khata_viewAllSuppliers');
  String get khata_whatsapp => _t('khata_whatsapp');
  String get production_addInput => _t('production_addInput');
  String get production_addOutput => _t('production_addOutput');
  String production_available({required Object qty, required Object unit}) => _f('production_available', {'qty': qty, 'unit': unit});
  String get production_batchAuto => _t('production_batchAuto');
  String get production_batchNo => _t('production_batchNo');
  String get production_costBreakdown => _t('production_costBreakdown');
  String get production_costsCashHint => _t('production_costsCashHint');
  String get production_date => _t('production_date');
  String get production_electricityCost => _t('production_electricityCost');
  String get production_emptyInputs => _t('production_emptyInputs');
  String get production_emptyOutputs => _t('production_emptyOutputs');
  String get production_errNegativeCost => _t('production_errNegativeCost');
  String get production_expectedYield => _t('production_expectedYield');
  String get production_inputs => _t('production_inputs');
  String production_inputsCount({required Object count}) => _f('production_inputsCount', {'count': count});
  String get production_labourCost => _t('production_labourCost');
  String get production_materialCost => _t('production_materialCost');
  String get production_newBatch => _t('production_newBatch');
  String get production_noBatches => _t('production_noBatches');
  String get production_noBatchesHint => _t('production_noBatchesHint');
  String get production_notes => _t('production_notes');
  String get production_otherCost => _t('production_otherCost');
  String get production_outOfStock => _t('production_outOfStock');
  String get production_outputType => _t('production_outputType');
  String get production_outputs => _t('production_outputs');
  String get production_payCostsFrom => _t('production_payCostsFrom');
  String get production_payCostsNone => _t('production_payCostsNone');
  String get production_postBatch => _t('production_postBatch');
  String get production_qtyGtZero => _t('production_qtyGtZero');
  String get production_rawOnly => _t('production_rawOnly');
  String get production_removeLine => _t('production_removeLine');
  String get production_resultNoYield => _t('production_resultNoYield');
  String get production_resultTitle => _t('production_resultTitle');
  String production_resultYield({required Object pct}) => _f('production_resultYield', {'pct': pct});
  String get production_selectProduct => _t('production_selectProduct');
  String get production_statusCostsPosted => _t('production_statusCostsPosted');
  String get production_statusPosted => _t('production_statusPosted');
  String get production_title => _t('production_title');
  String get production_totalCost => _t('production_totalCost');
  String get production_typeByProduct => _t('production_typeByProduct');
  String get production_typeFinishedOil => _t('production_typeFinishedOil');
  String get production_typeOilCake => _t('production_typeOilCake');
  String get production_wastage => _t('production_wastage');
  String get production_yield => _t('production_yield');
  String get purchases_confirmPost => _t('purchases_confirmPost');
  String get purchases_deleteDraft => _t('purchases_deleteDraft');
  String get purchases_detailTitle => _t('purchases_detailTitle');
  String get purchases_draftDeleted => _t('purchases_draftDeleted');
  String purchases_draftSaved({required Object invoiceNo}) => _f('purchases_draftSaved', {'invoiceNo': invoiceNo});
  String get purchases_emptyTitle => _t('purchases_emptyTitle');
  String get purchases_formTitle => _t('purchases_formTitle');
  String get purchases_lineItems => _t('purchases_lineItems');
  String get purchases_newPurchase => _t('purchases_newPurchase');
  String get purchases_noItems => _t('purchases_noItems');
  String get purchases_noSupplierSelected => _t('purchases_noSupplierSelected');
  String get purchases_payments => _t('purchases_payments');
  String get purchases_postDraft => _t('purchases_postDraft');
  String get purchases_postPurchase => _t('purchases_postPurchase');
  String purchases_purchasePosted({required Object invoiceNo}) => _f('purchases_purchasePosted', {'invoiceNo': invoiceNo});
  String get purchases_recordPayment => _t('purchases_recordPayment');
  String get purchases_returnTitle => _t('purchases_returnTitle');
  String get purchases_searchHint => _t('purchases_searchHint');
  String get purchases_searchSupplier => _t('purchases_searchSupplier');
  String get purchases_selectSupplier => _t('purchases_selectSupplier');
  String get purchases_statusCancelled => _t('purchases_statusCancelled');
  String get purchases_statusDraft => _t('purchases_statusDraft');
  String get purchases_statusPaid => _t('purchases_statusPaid');
  String get purchases_statusPartial => _t('purchases_statusPartial');
  String get purchases_statusReturned => _t('purchases_statusReturned');
  String get purchases_statusUnpaid => _t('purchases_statusUnpaid');
  String get purchases_supplier => _t('purchases_supplier');
  String get purchases_title => _t('purchases_title');
  String get purchases_voucherPdf => _t('purchases_voucherPdf');
  String reminders_daysOverdue({required Object days}) => _f('reminders_daysOverdue', {'days': days});
  String reminders_dueOn({required Object date}) => _f('reminders_dueOn', {'date': date});
  String get reminders_editMessage => _t('reminders_editMessage');
  String get reminders_emptyMessage => _t('reminders_emptyMessage');
  String get reminders_emptyTitle => _t('reminders_emptyTitle');
  String get reminders_failed => _t('reminders_failed');
  String reminders_noPhone({required Object name}) => _f('reminders_noPhone', {'name': name});
  String get reminders_overdue => _t('reminders_overdue');
  String get reminders_pickScript => _t('reminders_pickScript');
  String get reminders_scriptEnglish => _t('reminders_scriptEnglish');
  String get reminders_scriptUrdu => _t('reminders_scriptUrdu');
  String get reminders_send => _t('reminders_send');
  String get reminders_sendSms => _t('reminders_sendSms');
  String get reminders_sendWhatsapp => _t('reminders_sendWhatsapp');
  String get reminders_sent => _t('reminders_sent');
  String get reminders_title => _t('reminders_title');
  String get reminders_upcoming => _t('reminders_upcoming');
  String get reports_accounts => _t('reports_accounts');
  String get reports_all => _t('reports_all');
  String get reports_avgCost => _t('reports_avgCost');
  String get reports_avgYield => _t('reports_avgYield');
  String get reports_batches => _t('reports_batches');
  String get reports_cashBankBalances => _t('reports_cashBankBalances');
  String get reports_cashbook => _t('reports_cashbook');
  String get reports_change => _t('reports_change');
  String get reports_closingBalance => _t('reports_closingBalance');
  String get reports_copied => _t('reports_copied');
  String get reports_copyReminder => _t('reports_copyReminder');
  String get reports_customRange => _t('reports_customRange');
  String get reports_customerLedger => _t('reports_customerLedger');
  String get reports_customers => _t('reports_customers');
  String get reports_dailySummary => _t('reports_dailySummary');
  String get reports_daybook => _t('reports_daybook');
  String get reports_doc_account => _t('reports_doc_account');
  String get reports_doc_amount => _t('reports_doc_amount');
  String get reports_doc_balance => _t('reports_doc_balance');
  String get reports_doc_bank => _t('reports_doc_bank');
  String get reports_doc_batchNo => _t('reports_doc_batchNo');
  String get reports_doc_billTo => _t('reports_doc_billTo');
  String get reports_doc_byProduct => _t('reports_doc_byProduct');
  String get reports_doc_cash => _t('reports_doc_cash');
  String get reports_doc_cashReceipt => _t('reports_doc_cashReceipt');
  String get reports_doc_category => _t('reports_doc_category');
  String get reports_doc_closingBalance => _t('reports_doc_closingBalance');
  String get reports_doc_credit => _t('reports_doc_credit');
  String get reports_doc_customer => _t('reports_doc_customer');
  String get reports_doc_customerStatement => _t('reports_doc_customerStatement');
  String get reports_doc_date => _t('reports_doc_date');
  String get reports_doc_debit => _t('reports_doc_debit');
  String get reports_doc_description => _t('reports_doc_description');
  String get reports_doc_discount => _t('reports_doc_discount');
  String get reports_doc_due => _t('reports_doc_due');
  String get reports_doc_electricity => _t('reports_doc_electricity');
  String get reports_doc_expenseVoucher => _t('reports_doc_expenseVoucher');
  String get reports_doc_from => _t('reports_doc_from');
  String reports_doc_generatedOn({required Object date}) => _f('reports_doc_generatedOn', {'date': date});
  String get reports_doc_inputs => _t('reports_doc_inputs');
  String get reports_doc_invoiceNo => _t('reports_doc_invoiceNo');
  String get reports_doc_item => _t('reports_doc_item');
  String get reports_doc_items => _t('reports_doc_items');
  String get reports_doc_labour => _t('reports_doc_labour');
  String get reports_doc_method => _t('reports_doc_method');
  String get reports_doc_notes => _t('reports_doc_notes');
  String get reports_doc_oilCake => _t('reports_doc_oilCake');
  String get reports_doc_openingBalance => _t('reports_doc_openingBalance');
  String get reports_doc_other => _t('reports_doc_other');
  String get reports_doc_outputs => _t('reports_doc_outputs');
  String get reports_doc_paid => _t('reports_doc_paid');
  String get reports_doc_paidTo => _t('reports_doc_paidTo');
  String get reports_doc_paymentReceipt => _t('reports_doc_paymentReceipt');
  String get reports_doc_pdfSaved => _t('reports_doc_pdfSaved');
  String get reports_doc_period => _t('reports_doc_period');
  String get reports_doc_price => _t('reports_doc_price');
  String get reports_doc_print => _t('reports_doc_print');
  String get reports_doc_productionReport => _t('reports_doc_productionReport');
  String get reports_doc_purchaseVoucher => _t('reports_doc_purchaseVoucher');
  String get reports_doc_qty => _t('reports_doc_qty');
  String get reports_doc_receivedFrom => _t('reports_doc_receivedFrom');
  String get reports_doc_reference => _t('reports_doc_reference');
  String get reports_doc_saleInvoice => _t('reports_doc_saleInvoice');
  String get reports_doc_savePdf => _t('reports_doc_savePdf');
  String get reports_doc_share => _t('reports_doc_share');
  String get reports_doc_status => _t('reports_doc_status');
  String get reports_doc_subtotal => _t('reports_doc_subtotal');
  String get reports_doc_supplier => _t('reports_doc_supplier');
  String get reports_doc_supplierPaymentVoucher => _t('reports_doc_supplierPaymentVoucher');
  String get reports_doc_supplierStatement => _t('reports_doc_supplierStatement');
  String get reports_doc_tax => _t('reports_doc_tax');
  String get reports_doc_to => _t('reports_doc_to');
  String get reports_doc_total => _t('reports_doc_total');
  String get reports_doc_yield => _t('reports_doc_yield');
  String get reports_due => _t('reports_due');
  String get reports_estimatedNote => _t('reports_estimatedNote');
  String get reports_expense => _t('reports_expense');
  String get reports_expensesByCategory => _t('reports_expensesByCategory');
  String get reports_grandTotal => _t('reports_grandTotal');
  String get reports_income => _t('reports_income');
  String get reports_inventoryValuation => _t('reports_inventoryValuation');
  String get reports_invoices => _t('reports_invoices');
  String get reports_lowStock => _t('reports_lowStock');
  String get reports_monthlySummary => _t('reports_monthlySummary');
  String get reports_netLoss => _t('reports_netLoss');
  String get reports_netProfit => _t('reports_netProfit');
  String get reports_noData => _t('reports_noData');
  String get reports_onHand => _t('reports_onHand');
  String get reports_openingBalance => _t('reports_openingBalance');
  String get reports_outstandingInvoices => _t('reports_outstandingInvoices');
  String get reports_paid => _t('reports_paid');
  String get reports_partial => _t('reports_partial');
  String get reports_payables => _t('reports_payables');
  String get reports_paymentsMade => _t('reports_paymentsMade');
  String get reports_paymentsReceived => _t('reports_paymentsReceived');
  String get reports_pickDate => _t('reports_pickDate');
  String get reports_pickMonth => _t('reports_pickMonth');
  String get reports_production => _t('reports_production');
  String get reports_profitLoss => _t('reports_profitLoss');
  String get reports_purchase => _t('reports_purchase');
  String get reports_purchaseInvoices => _t('reports_purchaseInvoices');
  String get reports_purchaseReturns => _t('reports_purchaseReturns');
  String get reports_quantity => _t('reports_quantity');
  String get reports_receivables => _t('reports_receivables');
  String reports_recordsCount({required Object count}) => _f('reports_recordsCount', {'count': count});
  String get reports_reorderLevel => _t('reports_reorderLevel');
  String get reports_saleInvoices => _t('reports_saleInvoices');
  String get reports_sales => _t('reports_sales');
  String get reports_salesReturns => _t('reports_salesReturns');
  String get reports_selectAccount => _t('reports_selectAccount');
  String get reports_selectCustomer => _t('reports_selectCustomer');
  String get reports_selectProduct => _t('reports_selectProduct');
  String get reports_selectSupplier => _t('reports_selectSupplier');
  String get reports_stockMovement => _t('reports_stockMovement');
  String get reports_stockValue => _t('reports_stockValue');
  String get reports_supplierLedger => _t('reports_supplierLedger');
  String get reports_suppliers => _t('reports_suppliers');
  String get reports_title => _t('reports_title');
  String get reports_totalExpenses => _t('reports_totalExpenses');
  String get reports_totalIncome => _t('reports_totalIncome');
  String get reports_totalPaid => _t('reports_totalPaid');
  String get reports_totalPurchases => _t('reports_totalPurchases');
  String get reports_totalReceived => _t('reports_totalReceived');
  String get reports_totalSales => _t('reports_totalSales');
  String get reports_trialBalance => _t('reports_trialBalance');
  String get reports_unpaid => _t('reports_unpaid');
  String get reports_value => _t('reports_value');
  String get reports_yield => _t('reports_yield');
  String get sales_apniMarzi => _t('sales_apniMarzi');
  String get sales_confirmPost => _t('sales_confirmPost');
  String get sales_customer => _t('sales_customer');
  String get sales_deleteDraft => _t('sales_deleteDraft');
  String get sales_detailTitle => _t('sales_detailTitle');
  String get sales_draftDeleted => _t('sales_draftDeleted');
  String sales_draftSaved({required Object invoiceNo}) => _f('sales_draftSaved', {'invoiceNo': invoiceNo});
  String get sales_emptyTitle => _t('sales_emptyTitle');
  String get sales_formTitle => _t('sales_formTitle');
  String get sales_haaliSales => _t('sales_haaliSales');
  String get sales_hafta => _t('sales_hafta');
  String get sales_invoicePdf => _t('sales_invoicePdf');
  String get sales_itemsManage => _t('sales_itemsManage');
  String get sales_itemsManageHint => _t('sales_itemsManageHint');
  String get sales_kullNaqad => _t('sales_kullNaqad');
  String get sales_kullOrders => _t('sales_kullOrders');
  String get sales_kullSales => _t('sales_kullSales');
  String get sales_kullUdhaar => _t('sales_kullUdhaar');
  String get sales_lineItems => _t('sales_lineItems');
  String get sales_maheena => _t('sales_maheena');
  String get sales_manageItems => _t('sales_manageItems');
  String sales_nataij({required Object count}) => _f('sales_nataij', {'count': count});
  String get sales_newSale => _t('sales_newSale');
  String get sales_noCustomerSelected => _t('sales_noCustomerSelected');
  String get sales_noItems => _t('sales_noItems');
  String get sales_noSalesPeriod => _t('sales_noSalesPeriod');
  String get sales_payments => _t('sales_payments');
  String get sales_periodCustom => _t('sales_periodCustom');
  String get sales_periodHafta => _t('sales_periodHafta');
  String get sales_periodMaheena => _t('sales_periodMaheena');
  String get sales_postDraft => _t('sales_postDraft');
  String get sales_postSale => _t('sales_postSale');
  String get sales_recordPayment => _t('sales_recordPayment');
  String get sales_returnTitle => _t('sales_returnTitle');
  String get sales_saleDarjKarein => _t('sales_saleDarjKarein');
  String sales_salePosted({required Object invoiceNo}) => _f('sales_salePosted', {'invoiceNo': invoiceNo});
  String get sales_searchCustomer => _t('sales_searchCustomer');
  String get sales_searchHint => _t('sales_searchHint');
  String get sales_searchSales => _t('sales_searchSales');
  String get sales_selectCustomer => _t('sales_selectCustomer');
  String get sales_share => _t('sales_share');
  String get sales_statusCancelled => _t('sales_statusCancelled');
  String get sales_statusDraft => _t('sales_statusDraft');
  String get sales_statusPaid => _t('sales_statusPaid');
  String get sales_statusPartial => _t('sales_statusPartial');
  String get sales_statusReturned => _t('sales_statusReturned');
  String get sales_statusUnpaid => _t('sales_statusUnpaid');
  String get sales_title => _t('sales_title');
  String get transactions_account => _t('transactions_account');
  String get transactions_addItem => _t('transactions_addItem');
  String get transactions_adjustment => _t('transactions_adjustment');
  String get transactions_bank => _t('transactions_bank');
  String get transactions_cash => _t('transactions_cash');
  String get transactions_category => _t('transactions_category');
  String get transactions_credit => _t('transactions_credit');
  String get transactions_customRange => _t('transactions_customRange');
  String transactions_customRangeHint({required Object from, required Object to}) => _f('transactions_customRangeHint', {'from': from, 'to': to});
  String get transactions_customRangeTitle => _t('transactions_customRangeTitle');
  String get transactions_date => _t('transactions_date');
  String get transactions_debit => _t('transactions_debit');
  String get transactions_description => _t('transactions_description');
  String get transactions_detailTitle => _t('transactions_detailTitle');
  String get transactions_discount => _t('transactions_discount');
  String get transactions_discountPct => _t('transactions_discountPct');
  String get transactions_due => _t('transactions_due');
  String get transactions_emptyTitle => _t('transactions_emptyTitle');
  String transactions_entriesCount({required Object count}) => _f('transactions_entriesCount', {'count': count});
  String get transactions_entryNo => _t('transactions_entryNo');
  String get transactions_expense => _t('transactions_expense');
  String get transactions_filterAll => _t('transactions_filterAll');
  String get transactions_filterPaymentPaid => _t('transactions_filterPaymentPaid');
  String get transactions_filterPaymentReceived => _t('transactions_filterPaymentReceived');
  String get transactions_income => _t('transactions_income');
  String get transactions_invalidPrice => _t('transactions_invalidPrice');
  String get transactions_invalidQty => _t('transactions_invalidQty');
  String get transactions_invoiceDiscount => _t('transactions_invoiceDiscount');
  String get transactions_lineTotal => _t('transactions_lineTotal');
  String transactions_maxQty({required Object qty}) => _f('transactions_maxQty', {'qty': qty});
  String get transactions_noDescription => _t('transactions_noDescription');
  String get transactions_notes => _t('transactions_notes');
  String get transactions_paidAmount => _t('transactions_paidAmount');
  String get transactions_paymentAccount => _t('transactions_paymentAccount');
  String get transactions_paymentAmount => _t('transactions_paymentAmount');
  String get transactions_paymentMethod => _t('transactions_paymentMethod');
  String get transactions_paymentReference => _t('transactions_paymentReference');
  String get transactions_paymentSaved => _t('transactions_paymentSaved');
  String get transactions_paymentTitle => _t('transactions_paymentTitle');
  String get transactions_production => _t('transactions_production');
  String get transactions_purchase => _t('transactions_purchase');
  String get transactions_qty => _t('transactions_qty');
  String get transactions_reference => _t('transactions_reference');
  String get transactions_removeLine => _t('transactions_removeLine');
  String get transactions_return => _t('transactions_return');
  String get transactions_returnPosted => _t('transactions_returnPosted');
  String get transactions_returnReason => _t('transactions_returnReason');
  String get transactions_returnTitle => _t('transactions_returnTitle');
  String get transactions_reversal => _t('transactions_reversal');
  String transactions_reversalOf({required Object entryNo}) => _f('transactions_reversalOf', {'entryNo': entryNo});
  String get transactions_reversed => _t('transactions_reversed');
  String get transactions_sale => _t('transactions_sale');
  String get transactions_saveDraft => _t('transactions_saveDraft');
  String get transactions_searchHint => _t('transactions_searchHint');
  String get transactions_searchProduct => _t('transactions_searchProduct');
  String get transactions_selectProduct => _t('transactions_selectProduct');
  String get transactions_sortNewest => _t('transactions_sortNewest');
  String get transactions_sortOldest => _t('transactions_sortOldest');
  String get transactions_submitPayment => _t('transactions_submitPayment');
  String get transactions_submitReturn => _t('transactions_submitReturn');
  String get transactions_subtotal => _t('transactions_subtotal');
  String get transactions_tax => _t('transactions_tax');
  String get transactions_taxPct => _t('transactions_taxPct');
  String get transactions_title => _t('transactions_title');
  String get transactions_total => _t('transactions_total');
  String get transactions_transfer => _t('transactions_transfer');
  String get transactions_unit => _t('transactions_unit');
  String get transactions_unitPrice => _t('transactions_unitPrice');
  String get udhaar_saved => _t('udhaar_saved');
  String get udhaar_title => _t('udhaar_title');
}
