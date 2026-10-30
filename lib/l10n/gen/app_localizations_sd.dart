// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sindhi (`sd`).
class AppLocalizationsSd extends AppLocalizations {
  AppLocalizationsSd([String locale = 'sd']) : super(locale);

  @override
  String get about_appName => 'Namt Oil Mil';

  @override
  String get about_offline =>
      '100% آف لائن — توهان جو سمورو ڊيٽا صرف هن ڊوائيس تي محفوظ رهي ٿو.';

  @override
  String about_version(String version) {
    return 'ورزن $version';
  }

  @override
  String get appTagline => 'توهان جو ڊجيٽل کاتو';

  @override
  String get appTitle => 'نعمت آئل مل';

  @override
  String get common_add => 'شامل ڪريو';

  @override
  String get common_amount => 'رقم';

  @override
  String get common_back => 'واپس';

  @override
  String get common_balance => 'بيلنس';

  @override
  String get common_cancel => 'منسوخ ڪريو';

  @override
  String get common_close => 'بند ڪريو';

  @override
  String get common_date => 'تاريخ';

  @override
  String get common_delete => 'ختم ڪريو';

  @override
  String get common_edit => 'ترميم ڪريو';

  @override
  String get common_no => 'نه';

  @override
  String get common_notes => 'نوٽس';

  @override
  String get common_ok => 'ٺيڪ آهي';

  @override
  String get common_retry => 'ٻيهر ڪوشش ڪريو';

  @override
  String get common_save => 'محفوظ ڪريو';

  @override
  String get common_search => 'ڳوليو';

  @override
  String get common_total => 'ڪل';

  @override
  String get common_yes => 'ها';

  @override
  String get confirmDelete_message =>
      'ڇا توهان واقعي هن کي ختم ڪرڻ چاهيو ٿا؟ اهو عمل واپس نه ٿيندو.';

  @override
  String get confirmDelete_title => 'ختم ڪرڻ جي تصديق';

  @override
  String get dateFilter_all => 'سڀ';

  @override
  String get dateFilter_month => 'هن مهيني';

  @override
  String get dateFilter_today => 'اڄ';

  @override
  String get dateFilter_week => 'هن هفتي';

  @override
  String get empty_default => 'اڃا ڪو رڪارڊ ناهي';

  @override
  String get error_generic => 'ڪجهه غلط ٿي ويو. مهرباني ڪري ٻيهر ڪوشش ڪريو.';

  @override
  String get langEnglish => 'English';

  @override
  String get langUrdu => 'Urdu';

  @override
  String get more_about => 'ايپ بابت';

  @override
  String get more_backup => 'بيڪ اپ ۽ بحالي';

  @override
  String get more_cashbook => 'ڪيش بڪ';

  @override
  String get more_expensesIncome => 'خرچ ۽ آمدني';

  @override
  String get more_inventory => 'اسٽاڪ';

  @override
  String get more_production => 'پيداوار';

  @override
  String get more_purchases => 'خريداري';

  @override
  String get more_sales => 'وڪرو';

  @override
  String get more_settings => 'سيٽنگون';

  @override
  String get nav_home => 'ڊيش بورڊ';

  @override
  String get nav_khata => 'کاتو';

  @override
  String get nav_more => 'وڌيڪ';

  @override
  String get nav_reports => 'رپورٽون';

  @override
  String get nav_transactions => 'ليڻ ڏيڻ';

  @override
  String get reminders_autoHistoryTitle => 'Auto reminder history';

  @override
  String get reminders_autoHowItWorks =>
      'WhatsApp does not let apps send messages on their own, so each WhatsApp reminder is prepared with its PDF — tap Send on the Reminders screen to share it. SMS reminders are sent automatically.';

  @override
  String reminders_autoLastSms(String date) {
    return 'Last automatic SMS: $date';
  }

  @override
  String get reminders_autoLastSmsNever =>
      'No automatic SMS has been sent yet.';

  @override
  String get reminders_autoOffMessage =>
      'Turn on daily WhatsApp reminders or weekly SMS reminders in Settings.';

  @override
  String get reminders_autoOffTitle => 'Auto reminders are off';

  @override
  String get reminders_autoOpenSettings => 'Open settings';

  @override
  String get reminders_autoQueueEmpty => 'No WhatsApp reminders are due today.';

  @override
  String get reminders_autoQueueTitle => 'WhatsApp reminders for today';

  @override
  String reminders_autoSmsDue(int count) {
    return '$count SMS reminders due — sent automatically.';
  }

  @override
  String get reminders_autoSmsNoneDue => 'No SMS reminders are due right now.';

  @override
  String get reminders_autoSmsPermissionNeeded =>
      'SMS permission is needed — this device cannot send automatic SMS yet.';

  @override
  String get reminders_autoSmsReady => 'This device can send automatic SMS.';

  @override
  String get reminders_autoSmsWeekly => 'SMS reminders (every 7 days)';

  @override
  String get reminders_autoSmsWeeklyHint =>
      'Sent automatically from your SIM every 7 days to customers with a balance due.';

  @override
  String get reminders_autoStatusFailed => 'Failed';

  @override
  String get reminders_autoTime => 'Daily reminder time';

  @override
  String get reminders_autoTitle => 'Auto Reminders';

  @override
  String get reminders_autoWhatsappDaily => 'WhatsApp reminders (daily)';

  @override
  String get reminders_autoWhatsappDailyHint =>
      'Every day, a reminder with the full ledger PDF is prepared for each customer with a balance due.';

  @override
  String get settings_about => 'ايپ بابت';

  @override
  String get settings_address => 'پتو';

  @override
  String get settings_businessName => 'ڪاروبار جو نالو';

  @override
  String get settings_businessProfile => 'ڪاروباري پروفائيل';

  @override
  String get settings_language => 'ٻولي';

  @override
  String get settings_phone => 'فون نمبر';

  @override
  String get settings_saved => 'سيٽنگون محفوظ ٿي ويون';

  @override
  String get settings_theme => 'ٿيم';

  @override
  String get settings_title => 'سيٽنگون';

  @override
  String get themeDark => 'اوندهه';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeSystem => 'سسٽم مطابق';

  @override
  String get val_invalidAmount => 'Enter a valid amount';

  @override
  String get val_invalidPhone => 'Enter a valid phone number';

  @override
  String get val_required => 'This field is required';

  @override
  String get backup_title => 'بيڪ اپ ۽ بحالي';

  @override
  String get backup_intro =>
      'Keep a safe copy of all your data. Backups are a single JSON file stored on this device only — nothing is uploaded.';

  @override
  String get backup_create => 'بيڪ اپ ٺاهيو';

  @override
  String get backup_creating => 'Creating backup…';

  @override
  String backup_created(String count, String tables) {
    return 'Backup created — $count records in $tables tables.';
  }

  @override
  String backup_savedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get backup_restore => 'بيڪ اپ بحال ڪريو';

  @override
  String get backup_chooseFile => 'Choose backup file';

  @override
  String get backup_reading => 'Reading backup…';

  @override
  String get backup_summaryTitle => 'Backup summary';

  @override
  String backup_exportedAt(String date) {
    return 'Exported $date';
  }

  @override
  String backup_tablesCount(String count) {
    return '$count tables';
  }

  @override
  String backup_recordsCount(String count) {
    return '$count records';
  }

  @override
  String get backup_confirmTitle => 'Restore this backup?';

  @override
  String get backup_confirmMessage =>
      'All current data will be REPLACED by the backup. This cannot be undone.';

  @override
  String get backup_confirmRestore => 'Restore';

  @override
  String get backup_restoring => 'Restoring…';

  @override
  String backup_restored(String count) {
    return 'Restore complete — $count records restored.';
  }

  @override
  String get backup_errorInvalidFile =>
      'This file is not a valid Namt Oil Mil backup.';

  @override
  String backup_errorUnsupportedVersion(String version) {
    return 'Unsupported backup version: $version.';
  }

  @override
  String backup_errorMissingTables(String tables) {
    return 'Backup is missing tables: $tables.';
  }

  @override
  String backup_errorChecksum(String table) {
    return 'Backup data is corrupted (checksum mismatch in $table).';
  }

  @override
  String get cashbook_accountName => 'Account name';

  @override
  String get cashbook_accountType => 'Account type';

  @override
  String get cashbook_accounts => 'Accounts';

  @override
  String get cashbook_addAccount => 'Add account';

  @override
  String get cashbook_addPayment => 'ادائيگي شامل ڪريو';

  @override
  String get cashbook_addReceipt => 'رسيد شامل ڪريو';

  @override
  String get cashbook_amount => 'Amount';

  @override
  String get cashbook_balance => 'بيلنس';

  @override
  String get cashbook_customer => 'Customer';

  @override
  String get cashbook_date => 'Date';

  @override
  String get cashbook_editAccount => 'Edit account';

  @override
  String get cashbook_entries => 'Entries';

  @override
  String get cashbook_errAccountNotFound => 'Account not found';

  @override
  String get cashbook_errInvalidAmount => 'Enter a valid amount';

  @override
  String get cashbook_errTransferSame =>
      'The From and To accounts must be different';

  @override
  String get cashbook_from => 'From';

  @override
  String get cashbook_in => 'آمد';

  @override
  String get cashbook_method => 'Method';

  @override
  String get cashbook_methodBank => 'Bank';

  @override
  String get cashbook_methodCash => 'Cash';

  @override
  String get cashbook_newTransfer => 'New transfer';

  @override
  String get cashbook_noAccounts => 'No accounts yet';

  @override
  String get cashbook_noEntries => 'No entries in this period';

  @override
  String get cashbook_notes => 'Notes';

  @override
  String get cashbook_openingBalance => 'شروعاتي بيلنس';

  @override
  String get cashbook_out => 'خرچ';

  @override
  String get cashbook_payment => 'Payment';

  @override
  String get cashbook_pickAccount => 'Select account';

  @override
  String get cashbook_receipt => 'Receipt';

  @override
  String get cashbook_reference => 'Reference';

  @override
  String get cashbook_selectCustomer => 'Select customer';

  @override
  String get cashbook_selectSupplier => 'Select supplier';

  @override
  String get cashbook_supplier => 'سپلائر';

  @override
  String get cashbook_title => 'ڪيش بڪ';

  @override
  String get cashbook_to => 'To';

  @override
  String get cashbook_totalIn => 'ڪل آمد';

  @override
  String get cashbook_totalOut => 'ڪل خرچ';

  @override
  String get cashbook_transfer => 'Transfer';

  @override
  String get cashbook_transferInfo =>
      'A transfer moves money between two accounts. It is never income or expense.';

  @override
  String get cashbook_typeBank => 'Bank';

  @override
  String get cashbook_typeCash => 'Cash';

  @override
  String get customers_account => 'اکائونٽ';

  @override
  String get customers_addCustomer => 'نئون گراهڪ';

  @override
  String get customers_addFirstHint =>
      'Add your first customer to track credit';

  @override
  String get customers_addFirstSupplierHint =>
      'Add your first supplier to track purchases';

  @override
  String get customers_addSupplier => 'نئون سپلائر';

  @override
  String get customers_address => 'پتو';

  @override
  String get customers_amount => 'رقم (روپيا)';

  @override
  String get customers_archive => 'Archive';

  @override
  String get customers_archiveMessage =>
      'They will be hidden from lists, but their history is kept.';

  @override
  String customers_archiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get customers_bank => 'Bank';

  @override
  String get customers_businessName => 'Business name';

  @override
  String get customers_cash => 'Cash';

  @override
  String get customers_code => 'Code';

  @override
  String get customers_copied => 'Copied to clipboard';

  @override
  String get customers_copyText => 'Copy text';

  @override
  String get customers_customRange => 'Custom range';

  @override
  String get customers_customerArchived => 'Customer archived';

  @override
  String get customers_customerRestored => 'Customer restored';

  @override
  String get customers_date => 'تاريخ';

  @override
  String get customers_editCustomer => 'گراهڪ ۾ ترميم ڪريو';

  @override
  String get customers_editSupplier => 'Edit supplier';

  @override
  String get customers_englishVersion => 'English';

  @override
  String get customers_filterAdvance => 'Advance';

  @override
  String get customers_filterAdvancePaid => 'Advance paid';

  @override
  String get customers_filterAll => 'All';

  @override
  String get customers_filterPayable => 'To pay';

  @override
  String get customers_filterReceivable => 'To receive';

  @override
  String get customers_giveUdhaar => 'Give credit';

  @override
  String get customers_ledgerTitle => 'ليجر';

  @override
  String get customers_makePayment => 'Make payment';

  @override
  String get customers_method => 'Method';

  @override
  String get customers_name => 'Name';

  @override
  String get customers_newCustomer => 'New customer';

  @override
  String get customers_newSupplier => 'New supplier';

  @override
  String get customers_noCustomers => 'No customers yet';

  @override
  String get customers_noEntries => 'No entries in this period';

  @override
  String get customers_noMatch => 'No matches found';

  @override
  String get customers_noSuppliers => 'No suppliers yet';

  @override
  String get customers_notFound => 'Record not found';

  @override
  String get customers_note => 'Note';

  @override
  String get customers_notes => 'Notes';

  @override
  String get customers_openingBalance => 'Opening balance';

  @override
  String get customers_openingBalanceHint => 'Optional. Amount in PKR.';

  @override
  String get customers_openingBalanceLabel => 'Opening balance';

  @override
  String get customers_openingHelpCustomer =>
      'Positive: the customer owes you. Negative: you owe the customer.';

  @override
  String get customers_openingHelpSupplier =>
      'Positive: you owe the supplier. Negative: the supplier owes you.';

  @override
  String get customers_paymentSaved => 'Payment recorded';

  @override
  String get customers_paymentTitlePay => 'Make payment';

  @override
  String get customers_paymentTitleReceive => 'Receive payment';

  @override
  String get customers_phone => 'فون';

  @override
  String get customers_receivePayment => 'Receive payment';

  @override
  String get customers_recordPurchase => 'Record purchase';

  @override
  String get customers_reminder => 'Reminder';

  @override
  String get customers_reminderTitle => 'Payment reminder';

  @override
  String get customers_saved => 'Saved';

  @override
  String get customers_searchHint => 'نالو، فون يا ڪوڊ ڳوليو';

  @override
  String get customers_searchLedgerHint => 'Search description';

  @override
  String get customers_selectAccount => 'Select account';

  @override
  String get customers_statement => 'Statement';

  @override
  String get customers_supplierArchived => 'Supplier archived';

  @override
  String get customers_supplierRestored => 'Supplier restored';

  @override
  String get customers_supplierTitle => 'سپلائرز';

  @override
  String get customers_title => 'گراهڪ';

  @override
  String get customers_totalCredit => 'Total credit given';

  @override
  String get customers_totalPaid => 'Total paid';

  @override
  String get customers_totalPurchases => 'Total purchases';

  @override
  String get customers_totalReceived => 'Total received';

  @override
  String get customers_unarchive => 'Unarchive';

  @override
  String get customers_urduVersion => 'Urdu';

  @override
  String get customers_viewLedger => 'View ledger';

  @override
  String get dashboard_activityExpense => 'Expense';

  @override
  String get dashboard_activityIncome => 'Income';

  @override
  String get dashboard_activityPaymentIn => 'Payment received';

  @override
  String get dashboard_activityPaymentOut => 'Payment made';

  @override
  String dashboard_activityPurchase(String no) {
    return 'Purchase $no';
  }

  @override
  String dashboard_activitySale(String no) {
    return 'Sale $no';
  }

  @override
  String get dashboard_bankBalance => 'Bank balance';

  @override
  String get dashboard_cashInHand => 'نقد رقم';

  @override
  String get dashboard_lowStock => 'گهٽ اسٽاڪ الرٽ';

  @override
  String get dashboard_lowStockOk => 'Stock levels are healthy';

  @override
  String get dashboard_monthExpense => 'Expenses this month';

  @override
  String get dashboard_monthIncome => 'Income this month';

  @override
  String get dashboard_noActivity => 'No recent activity';

  @override
  String get dashboard_noActivityHint =>
      'Sales, purchases and payments will appear here';

  @override
  String get dashboard_paidToday => 'Paid today';

  @override
  String get dashboard_pickCustomer => 'Choose customer';

  @override
  String get dashboard_pickSupplier => 'Choose supplier';

  @override
  String get dashboard_qaAddCustomer => 'Add customer';

  @override
  String get dashboard_qaAddExpense => 'Add expense';

  @override
  String get dashboard_qaAddPurchase => 'Add purchase';

  @override
  String get dashboard_qaAddSale => 'Add sale';

  @override
  String get dashboard_qaAddSupplier => 'Add supplier';

  @override
  String get dashboard_qaGiveUdhaar => 'Give credit';

  @override
  String get dashboard_qaMakePayment => 'Make payment';

  @override
  String get dashboard_qaReceivePayment => 'Receive payment';

  @override
  String get dashboard_qaRecordProduction => 'Record production';

  @override
  String get dashboard_qaViewReports => 'View reports';

  @override
  String get dashboard_quickActions => 'Quick actions';

  @override
  String get dashboard_receivedToday => 'Received today';

  @override
  String get dashboard_recentActivity => 'Recent activity';

  @override
  String dashboard_stockLeft(String qty, String unit) {
    return '$qty $unit left';
  }

  @override
  String get dashboard_thisMonth => 'This month';

  @override
  String get dashboard_title => 'ڊيش بورڊ';

  @override
  String get dashboard_today => 'Today';

  @override
  String get dashboard_todayPurchases => 'اڄ جي خريداري';

  @override
  String get dashboard_todaySales => 'اڄ جو وڪرو';

  @override
  String get dashboard_totalBalance => 'Total balance';

  @override
  String get dashboard_totalPayable => 'ادا ڪرڻو آهي';

  @override
  String get dashboard_totalReceivable => 'وصول ڪرڻو آهي';

  @override
  String get dashboard_viewAll => 'View all';

  @override
  String get expenses_account => 'Account';

  @override
  String get expenses_addCategory => 'New category';

  @override
  String get expenses_addExpense => 'Add expense';

  @override
  String get expenses_addIncome => 'Add income';

  @override
  String get expenses_amount => 'Amount';

  @override
  String get expenses_category => 'Category';

  @override
  String get expenses_categoryName => 'Category name';

  @override
  String get expenses_categorySaved => 'Category saved';

  @override
  String get expenses_date => 'Date';

  @override
  String get expenses_description => 'Description';

  @override
  String get expenses_errAccountNotFound => 'Account not found';

  @override
  String get expenses_errCategoryNotFound => 'Category not found';

  @override
  String get expenses_errInvalidAmount => 'Enter a valid amount';

  @override
  String get expenses_expenseSaved => 'Expense saved';

  @override
  String get expenses_incomeCategory => 'Income type (optional)';

  @override
  String get expenses_incomeSaved => 'Income saved';

  @override
  String get expenses_noEntries => 'No entries yet';

  @override
  String get expenses_reference => 'Reference';

  @override
  String get expenses_tabExpenses => 'Expenses';

  @override
  String get expenses_tabIncome => 'Income';

  @override
  String get expenses_thisMonth => 'This month';

  @override
  String get expenses_thisYear => 'This year';

  @override
  String get expenses_title => 'Expenses & income';

  @override
  String get expenses_today => 'Today';

  @override
  String get expenses_totalExpenses => 'Total expenses';

  @override
  String get expenses_totalIncome => 'Total income';

  @override
  String get inventory_addConversion => 'Add conversion';

  @override
  String get inventory_addProduct => 'Add product';

  @override
  String get inventory_adjust => 'Adjust stock';

  @override
  String get inventory_adjustment => 'Adjustment';

  @override
  String get inventory_all => 'All';

  @override
  String get inventory_available => 'Available';

  @override
  String get inventory_avgCost => 'Average cost';

  @override
  String get inventory_catConsumable => 'Consumables';

  @override
  String get inventory_catContainer => 'Containers';

  @override
  String get inventory_catFinishedOil => 'Finished oil';

  @override
  String get inventory_catOilCake => 'Oil cake';

  @override
  String get inventory_catPackaging => 'Packaging';

  @override
  String get inventory_catRawMaterial => 'Raw material';

  @override
  String get inventory_catSpare => 'Spares';

  @override
  String get inventory_category => 'Category';

  @override
  String get inventory_conversionExists =>
      'A conversion for this pair already exists';

  @override
  String get inventory_conversionsTitle => 'Conversions';

  @override
  String get inventory_editConversion => 'Edit conversion';

  @override
  String get inventory_editProduct => 'Edit product';

  @override
  String get inventory_errDatabase => 'Something went wrong. Please try again.';

  @override
  String inventory_errInsufficientStock(
      String available, String needed, String product) {
    return 'Insufficient stock of $product (available $available, needed $needed)';
  }

  @override
  String get inventory_errInvalidAmount => 'Enter a valid amount';

  @override
  String get inventory_errInvalidQty =>
      'Enter a valid quantity greater than zero';

  @override
  String get inventory_errNoConversion =>
      'No conversion defined between these units';

  @override
  String get inventory_errProductNotFound => 'Product not found';

  @override
  String get inventory_factor => 'Factor';

  @override
  String inventory_factorHint(String from, String to) {
    return 'How many $to in 1 $from?';
  }

  @override
  String get inventory_factorPositive => 'Factor must be greater than zero';

  @override
  String get inventory_from => 'From';

  @override
  String get inventory_in => 'In';

  @override
  String get inventory_lowStock => 'Low stock';

  @override
  String get inventory_movements => 'Movement history';

  @override
  String get inventory_name => 'Product name';

  @override
  String get inventory_noConversions => 'No conversions defined yet';

  @override
  String get inventory_noMovements => 'No movements recorded yet';

  @override
  String get inventory_noProducts => 'No products found';

  @override
  String get inventory_noProductsHint =>
      'Add your first product to start tracking stock.';

  @override
  String get inventory_openingStock => 'Opening stock';

  @override
  String get inventory_openingStockReason => 'Opening stock';

  @override
  String get inventory_out => 'Out';

  @override
  String get inventory_productSaved => 'Product saved';

  @override
  String get inventory_qty => 'Quantity';

  @override
  String get inventory_reason => 'Reason';

  @override
  String get inventory_reasonRequired => 'Please enter a reason';

  @override
  String get inventory_reorderLevel => 'Reorder level';

  @override
  String get inventory_salePrice => 'Default sale price (optional)';

  @override
  String get inventory_searchHint => 'Search products';

  @override
  String get inventory_sku => 'SKU (optional)';

  @override
  String get inventory_stock => 'Stock';

  @override
  String get inventory_stockIn => 'Stock in';

  @override
  String get inventory_stockInReason => 'Stock receipt';

  @override
  String get inventory_stockOut => 'Stock out';

  @override
  String get inventory_stockOutReason => 'Stock dispatch';

  @override
  String get inventory_stockUpdated => 'Stock updated';

  @override
  String get inventory_stockValue => 'Stock value';

  @override
  String get inventory_title => 'Inventory';

  @override
  String get inventory_to => 'To';

  @override
  String get inventory_typeAdjustment => 'Adjustment';

  @override
  String get inventory_typeProduction => 'Production';

  @override
  String get inventory_typePurchase => 'Purchase';

  @override
  String get inventory_typeReturn => 'Return';

  @override
  String get inventory_typeSale => 'Sale';

  @override
  String get inventory_unit => 'Unit';

  @override
  String get inventory_units => 'Units & conversions';

  @override
  String get inventory_unitsTitle => 'Units';

  @override
  String get khata_customers => 'گراهڪ';

  @override
  String get khata_errorAccountInactive => 'This account is inactive.';

  @override
  String get khata_errorAccountNotFound => 'Account not found.';

  @override
  String get khata_errorAlreadyReversed =>
      'This entry has already been reversed.';

  @override
  String get khata_errorCategoryInactive => 'This category is inactive.';

  @override
  String get khata_errorCategoryNotFound => 'Category not found.';

  @override
  String get khata_errorCustomerArchived => 'This customer is archived.';

  @override
  String get khata_errorCustomerNotFound => 'Customer not found.';

  @override
  String get khata_errorDatabase => 'Database error. Please try again.';

  @override
  String get khata_errorEmptyBatchInputs => 'A batch needs at least one input.';

  @override
  String get khata_errorEmptyBatchOutputs =>
      'A batch needs at least one output.';

  @override
  String get khata_errorEmptyInvoice => 'The invoice has no items.';

  @override
  String get khata_errorEmptyJournal => 'The journal has no entries.';

  @override
  String get khata_errorEmptyReturn => 'The return has no items.';

  @override
  String get khata_errorEntryNotFound => 'Ledger entry not found.';

  @override
  String khata_errorInsufficientStock(String product) {
    return 'Not enough stock of $product.';
  }

  @override
  String get khata_errorInvalidAmount => 'Invalid amount.';

  @override
  String get khata_errorInvalidJournalLine => 'Invalid journal entry.';

  @override
  String get khata_errorInvalidQty => 'Invalid quantity.';

  @override
  String get khata_errorInvoiceNotFound => 'Invoice not found.';

  @override
  String get khata_errorMethodAccountMismatch =>
      'The payment method does not match the account.';

  @override
  String get khata_errorNegativeCost => 'Cost cannot be negative.';

  @override
  String get khata_errorNegativePrice => 'Price cannot be negative.';

  @override
  String get khata_errorNegativeTax => 'Tax cannot be negative.';

  @override
  String get khata_errorNegativeTotal => 'The total cannot be negative.';

  @override
  String get khata_errorNoConversion => 'Unit conversion is not available.';

  @override
  String get khata_errorNotADraft => 'Only drafts can be changed like this.';

  @override
  String get khata_errorOilCostAllocation => 'Could not allocate the oil cost.';

  @override
  String get khata_errorOverAllocated =>
      'The payment is more than the outstanding amount.';

  @override
  String get khata_errorOverAllocatedInvoice =>
      'The payment is more than the invoice balance.';

  @override
  String get khata_errorProductArchived => 'This product is archived.';

  @override
  String get khata_errorProductNotFound => 'Product not found.';

  @override
  String get khata_errorReasonRequired => 'A reason is required.';

  @override
  String get khata_errorReturnExceedsBought =>
      'The return is more than what was bought.';

  @override
  String get khata_errorReturnExceedsSold =>
      'The return is more than what was sold.';

  @override
  String get khata_errorSupplierArchived => 'This supplier is archived.';

  @override
  String get khata_errorSupplierNotFound => 'Supplier not found.';

  @override
  String get khata_errorTransferSameAccount =>
      'Cannot transfer to the same account.';

  @override
  String get khata_errorUnbalancedJournal => 'The journal is not balanced.';

  @override
  String get khata_errorUnitNotFound => 'Unit not found.';

  @override
  String get khata_noDues => 'All settled up';

  @override
  String get khata_noDuesHint => 'No outstanding balances';

  @override
  String get khata_suppliers => 'سپلائرز';

  @override
  String get khata_title => 'کاتو';

  @override
  String get khata_toPay => 'To pay';

  @override
  String get khata_toReceive => 'To receive';

  @override
  String get khata_viewAllCustomers => 'View customers';

  @override
  String get khata_viewAllSuppliers => 'View suppliers';

  @override
  String get production_addInput => 'Add input';

  @override
  String get production_addOutput => 'Add output';

  @override
  String production_available(String qty, String unit) {
    return 'Available: $qty $unit';
  }

  @override
  String get production_batchAuto => 'Auto-generated when the batch is posted';

  @override
  String get production_batchNo => 'Batch no.';

  @override
  String get production_costBreakdown => 'Cost breakdown';

  @override
  String get production_costsCashHint =>
      'When selected, labour, electricity and other costs are posted as expenses from this account.';

  @override
  String get production_date => 'Date';

  @override
  String get production_electricityCost => 'Electricity cost';

  @override
  String get production_emptyInputs => 'Add at least one input';

  @override
  String get production_emptyOutputs => 'Add at least one output';

  @override
  String get production_errNegativeCost => 'Costs cannot be negative';

  @override
  String get production_expectedYield => 'Expected yield % (optional)';

  @override
  String get production_inputs => 'Inputs (raw material)';

  @override
  String production_inputsCount(String count) {
    return '$count inputs';
  }

  @override
  String get production_labourCost => 'Labour cost';

  @override
  String get production_materialCost => 'Material cost';

  @override
  String get production_newBatch => 'New batch';

  @override
  String get production_noBatches => 'No batches yet';

  @override
  String get production_noBatchesHint => 'Start your first production batch.';

  @override
  String get production_notes => 'Notes';

  @override
  String get production_otherCost => 'Other cost';

  @override
  String get production_outOfStock => 'No raw-material products yet';

  @override
  String get production_outputType => 'Output type';

  @override
  String get production_outputs => 'Outputs';

  @override
  String get production_payCostsFrom => 'Pay costs from';

  @override
  String get production_payCostsNone => 'None (record separately)';

  @override
  String get production_postBatch => 'Post batch';

  @override
  String get production_qtyGtZero => 'Quantity must be greater than zero';

  @override
  String get production_rawOnly => 'Only raw-material products can be inputs';

  @override
  String get production_removeLine => 'Remove line';

  @override
  String get production_resultNoYield =>
      'Yield could not be computed — add a kg conversion for the units used.';

  @override
  String get production_resultTitle => 'Batch posted';

  @override
  String production_resultYield(String pct) {
    return 'Yield: $pct%';
  }

  @override
  String get production_selectProduct => 'Select product';

  @override
  String get production_statusCostsPosted => 'Costs in cashbook';

  @override
  String get production_statusPosted => 'Posted';

  @override
  String get production_title => 'Production';

  @override
  String get production_totalCost => 'Total cost';

  @override
  String get production_typeByProduct => 'By-product';

  @override
  String get production_typeFinishedOil => 'Finished oil';

  @override
  String get production_typeOilCake => 'Oil cake';

  @override
  String get production_wastage => 'Wastage / loss';

  @override
  String get production_yield => 'Yield';

  @override
  String get purchases_confirmPost =>
      'Post this purchase? Stock will increase.';

  @override
  String get purchases_deleteDraft => 'Delete draft';

  @override
  String get purchases_detailTitle => 'Purchase detail';

  @override
  String get purchases_draftDeleted => 'Draft deleted';

  @override
  String purchases_draftSaved(String invoiceNo) {
    return 'Draft $invoiceNo saved';
  }

  @override
  String get purchases_emptyTitle => 'No purchases yet';

  @override
  String get purchases_formTitle => 'New purchase';

  @override
  String get purchases_lineItems => 'Items';

  @override
  String get purchases_newPurchase => 'New purchase';

  @override
  String get purchases_noItems => 'Add at least one item';

  @override
  String get purchases_noSupplierSelected => 'Select a supplier first';

  @override
  String get purchases_payments => 'Payments';

  @override
  String get purchases_postDraft => 'Post draft';

  @override
  String get purchases_postPurchase => 'Post purchase';

  @override
  String purchases_purchasePosted(String invoiceNo) {
    return 'Purchase $invoiceNo posted';
  }

  @override
  String get purchases_recordPayment => 'Record payment';

  @override
  String get purchases_returnTitle => 'Purchase return';

  @override
  String get purchases_searchHint => 'Search voucher no. or supplier…';

  @override
  String get purchases_searchSupplier => 'Search suppliers…';

  @override
  String get purchases_selectSupplier => 'Select supplier';

  @override
  String get purchases_statusCancelled => 'Cancelled';

  @override
  String get purchases_statusDraft => 'Draft';

  @override
  String get purchases_statusPaid => 'Paid';

  @override
  String get purchases_statusPartial => 'Partial';

  @override
  String get purchases_statusReturned => 'Returned';

  @override
  String get purchases_statusUnpaid => 'Unpaid';

  @override
  String get purchases_supplier => 'Supplier';

  @override
  String get purchases_title => 'Purchases';

  @override
  String get purchases_voucherPdf => 'Purchase voucher PDF';

  @override
  String get reports_title => 'Reports';

  @override
  String get reports_dailySummary => 'Daily Summary';

  @override
  String get reports_monthlySummary => 'Monthly Summary';

  @override
  String get reports_customerLedger => 'Customer Ledger';

  @override
  String get reports_supplierLedger => 'Supplier Ledger';

  @override
  String get reports_receivables => 'Receivables';

  @override
  String get reports_payables => 'Payables';

  @override
  String get reports_sales => 'Sales';

  @override
  String get reports_purchase => 'Purchases';

  @override
  String get reports_paymentsReceived => 'Payments Received';

  @override
  String get reports_paymentsMade => 'Payments Made';

  @override
  String get reports_expense => 'Expenses';

  @override
  String get reports_income => 'Income';

  @override
  String get reports_cashbook => 'Cashbook';

  @override
  String get reports_cashBankBalances => 'Cash & Bank Balances';

  @override
  String get reports_inventoryValuation => 'Inventory Valuation';

  @override
  String get reports_stockMovement => 'Stock Movement';

  @override
  String get reports_lowStock => 'Low Stock';

  @override
  String get reports_production => 'Production';

  @override
  String get reports_yield => 'Yield';

  @override
  String get reports_salesReturns => 'Sales Returns';

  @override
  String get reports_purchaseReturns => 'Purchase Returns';

  @override
  String get reports_outstandingInvoices => 'Outstanding Invoices';

  @override
  String get reports_profitLoss => 'Profit & Loss';

  @override
  String get reports_trialBalance => 'Trial Balance';

  @override
  String get reports_daybook => 'Daybook';

  @override
  String get reports_selectCustomer => 'Select customer';

  @override
  String get reports_selectSupplier => 'Select supplier';

  @override
  String get reports_selectProduct => 'Select product';

  @override
  String get reports_selectAccount => 'Select account';

  @override
  String get reports_change => 'Change';

  @override
  String get reports_customRange => 'Custom range';

  @override
  String get reports_pickDate => 'Pick date';

  @override
  String get reports_pickMonth => 'Pick month';

  @override
  String get reports_all => 'All';

  @override
  String get reports_totalSales => 'Total sales';

  @override
  String get reports_totalPurchases => 'Total purchases';

  @override
  String get reports_totalReceived => 'Total received';

  @override
  String get reports_totalPaid => 'Total paid';

  @override
  String get reports_totalExpenses => 'Total expenses';

  @override
  String get reports_totalIncome => 'Total income';

  @override
  String get reports_netProfit => 'Net profit';

  @override
  String get reports_netLoss => 'Net loss';

  @override
  String get reports_estimatedNote =>
      'Estimated — cost data is incomplete for this period.';

  @override
  String get reports_openingBalance => 'Opening balance';

  @override
  String get reports_closingBalance => 'Closing balance';

  @override
  String reports_recordsCount(String count) {
    return '$count records';
  }

  @override
  String get reports_due => 'Due';

  @override
  String get reports_paid => 'Paid';

  @override
  String get reports_unpaid => 'Unpaid';

  @override
  String get reports_partial => 'Partially paid';

  @override
  String get reports_invoices => 'Invoices';

  @override
  String get reports_stockValue => 'Stock value';

  @override
  String get reports_avgYield => 'Average yield';

  @override
  String get reports_batches => 'Batches';

  @override
  String get reports_quantity => 'Quantity';

  @override
  String get reports_avgCost => 'Avg. cost';

  @override
  String get reports_reorderLevel => 'Reorder level';

  @override
  String get reports_onHand => 'On hand';

  @override
  String get reports_copyReminder => 'Copy reminder';

  @override
  String get reports_copied => 'Copied to clipboard';

  @override
  String get reports_noData => 'No data for this period.';

  @override
  String get reports_saleInvoices => 'Sale invoices';

  @override
  String get reports_purchaseInvoices => 'Purchase invoices';

  @override
  String get reports_value => 'Value';

  @override
  String get reports_expensesByCategory => 'Expenses by category';

  @override
  String get reports_customers => 'Customers';

  @override
  String get reports_suppliers => 'Suppliers';

  @override
  String get reports_accounts => 'Accounts';

  @override
  String get reports_grandTotal => 'Grand total';

  @override
  String get reports_doc_saleInvoice => 'Sale Invoice';

  @override
  String get reports_doc_purchaseVoucher => 'Purchase Voucher';

  @override
  String get reports_doc_paymentReceipt => 'Payment Receipt';

  @override
  String get reports_doc_supplierPaymentVoucher => 'Supplier Payment Voucher';

  @override
  String get reports_doc_customerStatement => 'Customer Statement';

  @override
  String get reports_doc_supplierStatement => 'Supplier Statement';

  @override
  String get reports_doc_cashReceipt => 'Cash Receipt';

  @override
  String get reports_doc_expenseVoucher => 'Expense Voucher';

  @override
  String get reports_doc_productionReport => 'Production Report';

  @override
  String get reports_doc_savePdf => 'Save PDF';

  @override
  String get reports_doc_share => 'Share';

  @override
  String get reports_doc_print => 'Print';

  @override
  String get reports_doc_pdfSaved => 'PDF saved.';

  @override
  String get reports_doc_billTo => 'Bill to';

  @override
  String get reports_doc_supplier => 'Supplier';

  @override
  String get reports_doc_customer => 'Customer';

  @override
  String get reports_doc_invoiceNo => 'Invoice no.';

  @override
  String get reports_doc_date => 'Date';

  @override
  String get reports_doc_status => 'Status';

  @override
  String get reports_doc_items => 'Items';

  @override
  String get reports_doc_item => 'Item';

  @override
  String get reports_doc_qty => 'Qty';

  @override
  String get reports_doc_price => 'Price';

  @override
  String get reports_doc_amount => 'Amount';

  @override
  String get reports_doc_subtotal => 'Subtotal';

  @override
  String get reports_doc_discount => 'Discount';

  @override
  String get reports_doc_tax => 'Tax';

  @override
  String get reports_doc_total => 'Total';

  @override
  String get reports_doc_paid => 'Paid';

  @override
  String get reports_doc_due => 'Balance due';

  @override
  String get reports_doc_notes => 'Notes';

  @override
  String get reports_doc_receivedFrom => 'Received from';

  @override
  String get reports_doc_paidTo => 'Paid to';

  @override
  String get reports_doc_account => 'Account';

  @override
  String get reports_doc_method => 'Method';

  @override
  String get reports_doc_reference => 'Reference';

  @override
  String get reports_doc_category => 'Category';

  @override
  String get reports_doc_description => 'Description';

  @override
  String get reports_doc_openingBalance => 'Opening balance';

  @override
  String get reports_doc_closingBalance => 'Closing balance';

  @override
  String get reports_doc_debit => 'Debit';

  @override
  String get reports_doc_credit => 'Credit';

  @override
  String get reports_doc_balance => 'Balance';

  @override
  String get reports_doc_inputs => 'Inputs (raw material)';

  @override
  String get reports_doc_outputs => 'Outputs';

  @override
  String get reports_doc_yield => 'Yield';

  @override
  String get reports_doc_batchNo => 'Batch no.';

  @override
  String reports_doc_generatedOn(String date) {
    return 'Generated on $date';
  }

  @override
  String get reports_doc_cash => 'Cash';

  @override
  String get reports_doc_bank => 'Bank';

  @override
  String get reports_doc_from => 'From';

  @override
  String get reports_doc_to => 'To';

  @override
  String get reports_doc_period => 'Period';

  @override
  String get reports_doc_oilCake => 'Oil cake';

  @override
  String get reports_doc_byProduct => 'By-product';

  @override
  String get reports_doc_labour => 'Labour';

  @override
  String get reports_doc_electricity => 'Electricity';

  @override
  String get reports_doc_other => 'Other';

  @override
  String get sales_confirmPost => 'Post this sale? Stock will be reduced.';

  @override
  String get sales_customer => 'گراهڪ';

  @override
  String get sales_deleteDraft => 'Delete draft';

  @override
  String get sales_detailTitle => 'Sale detail';

  @override
  String get sales_draftDeleted => 'Draft deleted';

  @override
  String sales_draftSaved(String invoiceNo) {
    return 'Draft $invoiceNo saved';
  }

  @override
  String get sales_emptyTitle => 'No sales yet';

  @override
  String get sales_formTitle => 'New sale';

  @override
  String get sales_invoicePdf => 'Invoice PDF';

  @override
  String get sales_lineItems => 'Items';

  @override
  String get sales_newSale => 'نئون وڪرو';

  @override
  String get sales_noCustomerSelected => 'Select a customer first';

  @override
  String get sales_noItems => 'Add at least one item';

  @override
  String get sales_payments => 'Payments';

  @override
  String get sales_postDraft => 'Post draft';

  @override
  String get sales_postSale => 'Post sale';

  @override
  String get sales_recordPayment => 'Record payment';

  @override
  String get sales_returnTitle => 'Sales return';

  @override
  String sales_salePosted(String invoiceNo) {
    return 'Sale $invoiceNo posted';
  }

  @override
  String get sales_searchCustomer => 'Search customers…';

  @override
  String get sales_searchHint => 'Search invoice no. or customer…';

  @override
  String get sales_selectCustomer => 'Select customer';

  @override
  String get sales_share => 'Share';

  @override
  String get sales_statusCancelled => 'Cancelled';

  @override
  String get sales_statusDraft => 'Draft';

  @override
  String get sales_statusPaid => 'Paid';

  @override
  String get sales_statusPartial => 'Partial';

  @override
  String get sales_statusReturned => 'Returned';

  @override
  String get sales_statusUnpaid => 'Unpaid';

  @override
  String get sales_title => 'وڪرو';

  @override
  String get transactions_account => 'Account';

  @override
  String get transactions_addItem => 'Add item';

  @override
  String get transactions_adjustment => 'Adjustment';

  @override
  String get transactions_bank => 'Bank';

  @override
  String get transactions_cash => 'Cash';

  @override
  String get transactions_category => 'Category';

  @override
  String get transactions_credit => 'Credit';

  @override
  String get transactions_customRange => 'Custom range';

  @override
  String transactions_customRangeHint(String from, String to) {
    return '$from – $to';
  }

  @override
  String get transactions_customRangeTitle => 'Select date range';

  @override
  String get transactions_date => 'Date';

  @override
  String get transactions_debit => 'Debit';

  @override
  String get transactions_description => 'Description';

  @override
  String get transactions_detailTitle => 'Transaction detail';

  @override
  String get transactions_discount => 'Discount';

  @override
  String get transactions_discountPct => 'Discount %';

  @override
  String get transactions_due => 'Due';

  @override
  String get transactions_emptyTitle => 'No transactions';

  @override
  String transactions_entriesCount(int count) {
    return '$count entries';
  }

  @override
  String get transactions_entryNo => 'Entry no.';

  @override
  String get transactions_expense => 'Expense';

  @override
  String get transactions_filterAll => 'All';

  @override
  String get transactions_filterPaymentPaid => 'Payment paid';

  @override
  String get transactions_filterPaymentReceived => 'Payment received';

  @override
  String get transactions_income => 'Income';

  @override
  String get transactions_invalidPrice => 'Enter a valid price';

  @override
  String get transactions_invalidQty => 'Enter a valid quantity';

  @override
  String get transactions_invoiceDiscount => 'Invoice discount %';

  @override
  String get transactions_lineTotal => 'Line total';

  @override
  String transactions_maxQty(String qty) {
    return 'Max $qty';
  }

  @override
  String get transactions_noDescription => '—';

  @override
  String get transactions_notes => 'Notes';

  @override
  String get transactions_paidAmount => 'Paid now';

  @override
  String get transactions_paymentAccount => 'Account';

  @override
  String get transactions_paymentAmount => 'Amount';

  @override
  String get transactions_paymentMethod => 'Method';

  @override
  String get transactions_paymentReference => 'Reference';

  @override
  String get transactions_paymentSaved => 'Payment saved';

  @override
  String get transactions_paymentTitle => 'Record payment';

  @override
  String get transactions_production => 'Production';

  @override
  String get transactions_purchase => 'Purchase';

  @override
  String get transactions_qty => 'Qty';

  @override
  String get transactions_reference => 'Reference';

  @override
  String get transactions_removeLine => 'Remove line';

  @override
  String get transactions_return => 'Return';

  @override
  String get transactions_returnPosted => 'Return posted';

  @override
  String get transactions_returnReason => 'Reason (optional)';

  @override
  String get transactions_returnTitle => 'Return items';

  @override
  String get transactions_reversal => 'Reversal';

  @override
  String transactions_reversalOf(String entryNo) {
    return 'Reversal of $entryNo';
  }

  @override
  String get transactions_reversed => 'Reversed';

  @override
  String get transactions_sale => 'Sale';

  @override
  String get transactions_saveDraft => 'Save as draft';

  @override
  String get transactions_searchHint => 'Search description, entry no…';

  @override
  String get transactions_searchProduct => 'Search products…';

  @override
  String get transactions_selectProduct => 'Select product';

  @override
  String get transactions_sortNewest => 'Newest';

  @override
  String get transactions_sortOldest => 'Oldest';

  @override
  String get transactions_submitPayment => 'Save payment';

  @override
  String get transactions_submitReturn => 'Post return';

  @override
  String get transactions_subtotal => 'Subtotal';

  @override
  String get transactions_tax => 'Tax';

  @override
  String get transactions_taxPct => 'Tax %';

  @override
  String get transactions_title => 'ليڻ ڏيڻ';

  @override
  String get transactions_total => 'Journal total';

  @override
  String get transactions_transfer => 'Transfer';

  @override
  String get transactions_unit => 'Unit';

  @override
  String get transactions_unitPrice => 'Unit price';

  @override
  String get udhaar_saved => 'اوڌار درج ڪيو ويو';

  @override
  String get udhaar_title => 'اوڌار ڏيو';

  @override
  String get security_title => 'سيڪيورٽي ۽ ايپ لاڪ';

  @override
  String get security_pinLock => 'پن لاڪ';

  @override
  String get security_pinLockDesc => 'ايپ کولڻ تي 4 انگن جو پن گهرجي';

  @override
  String get security_biometric => 'فنگر پرنٽ / فيس لاڪ';

  @override
  String get security_biometricDesc => 'ايپ کولڻ تي بايوميٽرڪ تصديق';

  @override
  String get security_changePin => 'پن تبديل ڪريو';

  @override
  String get security_setupPin => 'پن سيٽ ڪريو';

  @override
  String get security_enterPin => 'پنهنجو 4 انگن جو پن داخل ڪريو';

  @override
  String get security_confirmPin => 'پن جي تصديق ڪريو';

  @override
  String get security_pinMismatch => 'پن نه مليو. ٻيهر ڪوشش ڪريو.';

  @override
  String get security_pinSet => 'پن سيٽ ٿي ويو';

  @override
  String get security_pinRemoved => 'پن لاڪ بند ڪيو ويو';

  @override
  String get security_wrongPin => 'غلط پن. ٻيهر ڪوشش ڪريو.';

  @override
  String get security_forgotPin => 'پن وسري ويو؟';

  @override
  String get security_forgotPinMsg =>
      'پن ري سيٽ ڪرڻ سان ايپ جو لاڪ ختم ٿي ويندو. جاري رکو؟';

  @override
  String get security_autoLock => 'آٽو لاڪ وقفو';

  @override
  String get security_autoLockImmediate => 'فوري';

  @override
  String get security_autoLock1min => '1 منٽ بعد';

  @override
  String get security_autoLock5min => '5 منٽ بعد';

  @override
  String get security_biometricNotAvailable =>
      'هن ڊوائيس تي بايوميٽرڪ موجود ناهي';

  @override
  String get security_unlockWithBiometric => 'بايوميٽرڪ سان کوليو';

  @override
  String get security_usePinInstead => 'پن استعمال ڪريو';

  @override
  String get langSindhi => 'سنڌي';

  @override
  String get settings_hisaabMode => 'حساب جو موڊ';

  @override
  String get settings_hisaabBusiness => 'ڪاروبار';

  @override
  String get settings_hisaabPersonal => 'ذاتي';

  @override
  String get backup_driveTitle => 'Google Drive Backup';

  @override
  String backup_driveConnected(String email) {
    return 'Connected to Google: $email';
  }

  @override
  String get backup_driveDisconnectTitle => 'Disconnect Google?';

  @override
  String get backup_driveDisconnectMessage =>
      'Auto-backup will be turned off. Backups already saved on Drive will stay there.';

  @override
  String get backup_driveDisconnect => 'Disconnect';

  @override
  String get backup_driveConnectIntro =>
      'Connect with Google so your data is automatically backed up to Drive.';

  @override
  String get backup_driveConnect => 'Connect with Google';

  @override
  String get backup_driveNoBackupYet => 'No backup yet';

  @override
  String backup_driveLastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backup_driveAutoBackup => '24-hour auto-backup';

  @override
  String get backup_driveAutoBackupHint =>
      'Every 24 hours, the full day\'s data is automatically uploaded to Drive.';

  @override
  String get backup_driveBackupNow => 'Backup now';

  @override
  String get backup_driveExportRange => 'Export — custom date range';

  @override
  String get customers_whatsappNumber => 'WhatsApp number';

  @override
  String get customers_waAddTitle => 'Add WhatsApp number';

  @override
  String customers_waAddMessage(String name) {
    return 'Save $name\'s WhatsApp number so their account statement can be sent straight to their chat.';
  }

  @override
  String get customers_waAdd => 'Add';

  @override
  String get customers_waOpenChat => 'Open chat';

  @override
  String get customers_waSendStatement => 'Send statement PDF';

  @override
  String get customers_waSendStatementHint =>
      'The account statement PDF will be created and shared.';

  @override
  String get customers_waOpenFailed =>
      'WhatsApp could not be opened. Check the number or install WhatsApp.';

  @override
  String customers_waStatementText(String name) {
    return '$name — account statement';
  }

  @override
  String backup_driveBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String backup_driveBackupSaved(String name) {
    return 'Backup saved to Drive: $name';
  }

  @override
  String get backup_driveConnectFailed =>
      'Could not connect to Google. Please connect from Settings first.';

  @override
  String backup_driveExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String backup_driveExportSaved(String name) {
    return 'Export saved to Drive: $name';
  }

  @override
  String get khata_errorDriveConnectFailed =>
      'Could not connect to Google. Check your internet and try again.';

  @override
  String get khata_errorDriveSignInCanceled => 'Google sign-in was canceled.';

  @override
  String get khata_errorDriveSignInInterrupted =>
      'Sign-in was interrupted — please try again.';

  @override
  String get khata_errorSmsChannelMissing =>
      'SMS channel is not available — open the SMS app to send.';

  @override
  String get khata_errorSmsEmptyMessage => 'Message is empty.';

  @override
  String get khata_errorSmsGeneric =>
      'Something went wrong while sending the SMS.';

  @override
  String get khata_errorSmsNoNumber => 'Phone number is missing.';

  @override
  String get khata_errorSmsNotAvailable => 'SMS cannot be sent on this device.';

  @override
  String get khata_errorSmsPermissionDenied =>
      'SMS permission was not granted. Allow SMS permission in Settings.';

  @override
  String khata_errorSmsSendFailed(String details) {
    return 'SMS could not be sent. $details';
  }
}
