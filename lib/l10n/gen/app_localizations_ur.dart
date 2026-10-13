// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get about_appName => 'نعمت آئل مل';

  @override
  String get about_offline =>
      '100% آف لائن — آپ کا تمام ڈیٹا صرف اسی ڈیوائس پر محفوظ رہتا ہے۔';

  @override
  String about_version(String version) {
    return 'ورژن $version';
  }

  @override
  String get appTagline => 'آپ کا ڈیجیٹل کھاتہ';

  @override
  String get appTitle => 'نعمت آئل مل';

  @override
  String get common_add => 'شامل کریں';

  @override
  String get common_amount => 'رقم';

  @override
  String get common_back => 'واپس';

  @override
  String get common_balance => 'بیلنس';

  @override
  String get common_cancel => 'منسوخ کریں';

  @override
  String get common_close => 'بند کریں';

  @override
  String get common_date => 'تاریخ';

  @override
  String get common_delete => 'حذف کریں';

  @override
  String get common_edit => 'ترمیم کریں';

  @override
  String get common_no => 'نہیں';

  @override
  String get common_notes => 'نوٹس';

  @override
  String get common_ok => 'ٹھیک ہے';

  @override
  String get common_retry => 'دوبارہ کوشش کریں';

  @override
  String get common_save => 'محفوظ کریں';

  @override
  String get common_search => 'تلاش کریں';

  @override
  String get common_total => 'کل';

  @override
  String get common_yes => 'جی ہاں';

  @override
  String get confirmDelete_message =>
      'کیا آپ واقعی اسے حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہو سکتا۔';

  @override
  String get confirmDelete_title => 'حذف کی تصدیق';

  @override
  String get dateFilter_all => 'تمام';

  @override
  String get dateFilter_month => 'اس ماہ';

  @override
  String get dateFilter_today => 'آج';

  @override
  String get dateFilter_week => 'اس ہفتے';

  @override
  String get empty_default => 'ابھی کوئی ریکارڈ نہیں ہے';

  @override
  String get error_generic => 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔';

  @override
  String get langEnglish => 'English';

  @override
  String get langUrdu => 'اردو';

  @override
  String get more_about => 'ایپ کے بارے میں';

  @override
  String get more_backup => 'بیک اپ و بحالی';

  @override
  String get more_cashbook => 'کیش بک';

  @override
  String get more_expensesIncome => 'اخراجات و آمدنی';

  @override
  String get more_inventory => 'اسٹاک';

  @override
  String get more_production => 'پیداوار';

  @override
  String get more_purchases => 'خریداری';

  @override
  String get more_sales => 'فروخت';

  @override
  String get more_settings => 'ترتیبات';

  @override
  String get nav_home => 'ڈیش بورڈ';

  @override
  String get nav_khata => 'کھاتہ';

  @override
  String get nav_more => 'مزید';

  @override
  String get nav_reports => 'رپورٹس';

  @override
  String get nav_transactions => 'لین دین';

  @override
  String get settings_about => 'ایپ کے بارے میں';

  @override
  String get settings_address => 'پتہ';

  @override
  String get settings_businessName => 'کاروبار کا نام';

  @override
  String get settings_businessProfile => 'کاروباری پروفائل';

  @override
  String get settings_language => 'زبان';

  @override
  String get settings_phone => 'فون نمبر';

  @override
  String get settings_saved => 'ترتیبات محفوظ ہو گئیں';

  @override
  String get settings_theme => 'تھیم';

  @override
  String get settings_title => 'ترتیبات';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeSystem => 'سسٹم کے مطابق';

  @override
  String get val_invalidAmount => 'درست رقم درج کریں';

  @override
  String get val_invalidPhone => 'درست فون نمبر درج کریں';

  @override
  String get val_required => 'یہ خانہ ضروری ہے';

  @override
  String get backup_title => 'بیک اپ و بحالی';

  @override
  String get backup_intro =>
      'اپنے تمام ڈیٹا کی محفوظ نقل رکھیں۔ بیک اپ ایک JSON فائل ہے جو صرف اس ڈیوائس پر محفوظ ہوتی ہے — کچھ بھی اپ لوڈ نہیں ہوتا۔';

  @override
  String get backup_create => 'بیک اپ بنائیں';

  @override
  String get backup_creating => 'بیک اپ بنایا جا رہا ہے…';

  @override
  String backup_created(String count, String tables) {
    return 'بیک اپ تیار — $tables ٹیبلز میں $count ریکارڈ۔';
  }

  @override
  String backup_savedTo(String path) {
    return '$path میں محفوظ ہو گیا';
  }

  @override
  String get backup_restore => 'بیک اپ بحال کریں';

  @override
  String get backup_chooseFile => 'بیک اپ فائل منتخب کریں';

  @override
  String get backup_reading => 'بیک اپ پڑھا جا رہا ہے…';

  @override
  String get backup_summaryTitle => 'بیک اپ کا خلاصہ';

  @override
  String backup_exportedAt(String date) {
    return 'برآمد شدہ: $date';
  }

  @override
  String backup_tablesCount(String count) {
    return '$count ٹیبلز';
  }

  @override
  String backup_recordsCount(String count) {
    return '$count ریکارڈ';
  }

  @override
  String get backup_confirmTitle => 'کیا یہ بیک اپ بحال کریں؟';

  @override
  String get backup_confirmMessage =>
      'موجودہ تمام ڈیٹا بیک اپ سے بدل دیا جائے گا۔ یہ عمل واپس نہیں ہو سکتا۔';

  @override
  String get backup_confirmRestore => 'بحال کریں';

  @override
  String get backup_restoring => 'بحال کیا جا رہا ہے…';

  @override
  String backup_restored(String count) {
    return 'بحالی مکمل — $count ریکارڈ بحال ہوئے۔';
  }

  @override
  String get backup_errorInvalidFile =>
      'یہ فائل نمت آئل مل کا درست بیک اپ نہیں ہے۔';

  @override
  String backup_errorUnsupportedVersion(String version) {
    return 'غیر تعاون یافتہ بیک اپ ورژن: $version۔';
  }

  @override
  String backup_errorMissingTables(String tables) {
    return 'بیک اپ میں یہ ٹیبلز غائب ہیں: $tables۔';
  }

  @override
  String backup_errorChecksum(String table) {
    return 'بیک اپ ڈیٹا خراب ہے ($table میں چیک سم مماثل نہیں)۔';
  }

  @override
  String get cashbook_accountName => 'کھاتے کا نام';

  @override
  String get cashbook_accountType => 'کھاتے کی قسم';

  @override
  String get cashbook_accounts => 'کھاتے';

  @override
  String get cashbook_addAccount => 'کھاتہ شامل کریں';

  @override
  String get cashbook_addPayment => 'ادائیگی شامل کریں';

  @override
  String get cashbook_addReceipt => 'رسید شامل کریں';

  @override
  String get cashbook_amount => 'رقم';

  @override
  String get cashbook_balance => 'بیلنس';

  @override
  String get cashbook_customer => 'گاہک';

  @override
  String get cashbook_date => 'تاریخ';

  @override
  String get cashbook_editAccount => 'کھاتے میں ترمیم کریں';

  @override
  String get cashbook_entries => 'اندراجات';

  @override
  String get cashbook_errAccountNotFound => 'کھاتہ نہیں ملا';

  @override
  String get cashbook_errInvalidAmount => 'درست رقم درج کریں';

  @override
  String get cashbook_errTransferSame => 'از اور تک کے کھاتے مختلف ہونے چاہئیں';

  @override
  String get cashbook_from => 'از';

  @override
  String get cashbook_in => 'آمد';

  @override
  String get cashbook_method => 'طریقہ';

  @override
  String get cashbook_methodBank => 'بینک';

  @override
  String get cashbook_methodCash => 'نقد';

  @override
  String get cashbook_newTransfer => 'نئی منتقلی';

  @override
  String get cashbook_noAccounts => 'ابھی کوئی کھاتہ نہیں';

  @override
  String get cashbook_noEntries => 'اس مدت میں کوئی اندراج نہیں';

  @override
  String get cashbook_notes => 'نوٹس';

  @override
  String get cashbook_openingBalance => 'ابتدائی بیلنس';

  @override
  String get cashbook_out => 'خرچ';

  @override
  String get cashbook_payment => 'ادائیگی';

  @override
  String get cashbook_pickAccount => 'کھاتہ منتخب کریں';

  @override
  String get cashbook_receipt => 'رسید';

  @override
  String get cashbook_reference => 'حوالہ';

  @override
  String get cashbook_selectCustomer => 'گاہک منتخب کریں';

  @override
  String get cashbook_selectSupplier => 'سپلائر منتخب کریں';

  @override
  String get cashbook_supplier => 'سپلائر';

  @override
  String get cashbook_title => 'کیش بک';

  @override
  String get cashbook_to => 'تک';

  @override
  String get cashbook_totalIn => 'کل آمد';

  @override
  String get cashbook_totalOut => 'کل خرچ';

  @override
  String get cashbook_transfer => 'منتقلی';

  @override
  String get cashbook_transferInfo =>
      'منتقلی دو کھاتوں کے درمیان رقم منتقل کرتی ہے۔ یہ کبھی آمدنی یا خرچ نہیں ہوتی۔';

  @override
  String get cashbook_typeBank => 'بینک';

  @override
  String get cashbook_typeCash => 'نقد';

  @override
  String get customers_account => 'اکاؤنٹ';

  @override
  String get customers_addCustomer => 'نیا گاہک';

  @override
  String get customers_addFirstHint =>
      'ادھار کا حساب رکھنے کے لیے پہلا گاہک شامل کریں';

  @override
  String get customers_addFirstSupplierHint =>
      'خریداری کا حساب رکھنے کے لیے پہلا سپلائر شامل کریں';

  @override
  String get customers_addSupplier => 'نیا سپلائر';

  @override
  String get customers_address => 'پتہ';

  @override
  String get customers_amount => 'رقم (روپے)';

  @override
  String get customers_archive => 'آرکائیو';

  @override
  String get customers_archiveMessage =>
      'وہ فہرستوں سے چھپ جائیں گے، لیکن ان کا ریکارڈ محفوظ رہے گا۔';

  @override
  String customers_archiveTitle(String name) {
    return '$name کو آرکائیو کریں؟';
  }

  @override
  String get customers_bank => 'بینک';

  @override
  String get customers_businessName => 'کاروبار کا نام';

  @override
  String get customers_cash => 'نقد';

  @override
  String get customers_code => 'کوڈ';

  @override
  String get customers_copied => 'کلپ بورڈ میں کاپی ہو گیا';

  @override
  String get customers_copyText => 'متن کاپی کریں';

  @override
  String get customers_customRange => 'اپنی مدت';

  @override
  String get customers_customerArchived => 'گاہک آرکائیو ہو گیا';

  @override
  String get customers_customerRestored => 'گاہک بحال ہو گیا';

  @override
  String get customers_date => 'تاریخ';

  @override
  String get customers_editCustomer => 'گاہک کی تدوین';

  @override
  String get customers_editSupplier => 'سپلائر کی تدوین';

  @override
  String get customers_englishVersion => 'انگریزی';

  @override
  String get customers_filterAdvance => 'ایڈوانس';

  @override
  String get customers_filterAdvancePaid => 'ایڈوانس دیا گیا';

  @override
  String get customers_filterAll => 'سب';

  @override
  String get customers_filterPayable => 'ادا کرنا ہے';

  @override
  String get customers_filterReceivable => 'وصول کرنا ہے';

  @override
  String get customers_giveUdhaar => 'ادھار دیں';

  @override
  String get customers_ledgerTitle => 'لیجر';

  @override
  String get customers_makePayment => 'ادائیگی کریں';

  @override
  String get customers_method => 'طریقہ';

  @override
  String get customers_name => 'نام';

  @override
  String get customers_newCustomer => 'نیا گاہک';

  @override
  String get customers_newSupplier => 'نیا سپلائر';

  @override
  String get customers_noCustomers => 'ابھی کوئی گاہک نہیں';

  @override
  String get customers_noEntries => 'اس مدت میں کوئی اندراج نہیں';

  @override
  String get customers_noMatch => 'کوئی نتیجہ نہیں ملا';

  @override
  String get customers_noSuppliers => 'ابھی کوئی سپلائر نہیں';

  @override
  String get customers_notFound => 'ریکارڈ نہیں ملا';

  @override
  String get customers_note => 'نوٹ';

  @override
  String get customers_notes => 'نوٹس';

  @override
  String get customers_openingBalance => 'ابتدائی بیلنس';

  @override
  String get customers_openingBalanceHint => 'اختیاری۔ رقم روپے میں۔';

  @override
  String get customers_openingBalanceLabel => 'ابتدائی بیلنس';

  @override
  String get customers_openingHelpCustomer =>
      'مثبت: گاہک آپ کا مقروض ہے۔ منفی: آپ گاہک کے مقروض ہیں۔';

  @override
  String get customers_openingHelpSupplier =>
      'مثبت: آپ سپلائر کے مقروض ہیں۔ منفی: سپلائر آپ کا مقروض ہے۔';

  @override
  String get customers_paymentSaved => 'ادائیگی درج ہو گئی';

  @override
  String get customers_paymentTitlePay => 'ادائیگی کریں';

  @override
  String get customers_paymentTitleReceive => 'ادائیگی وصول کریں';

  @override
  String get customers_phone => 'فون';

  @override
  String get customers_receivePayment => 'ادائیگی وصول کریں';

  @override
  String get customers_recordPurchase => 'خریداری درج کریں';

  @override
  String get customers_reminder => 'یاد دہانی';

  @override
  String get customers_reminderTitle => 'ادائیگی کی یاددہانی';

  @override
  String get customers_saved => 'محفوظ ہو گیا';

  @override
  String get customers_searchHint => 'نام، فون یا کوڈ تلاش کریں';

  @override
  String get customers_searchLedgerHint => 'تفصیل تلاش کریں';

  @override
  String get customers_selectAccount => 'اکاؤنٹ منتخب کریں';

  @override
  String get customers_statement => 'اسٹیٹمنٹ';

  @override
  String get customers_supplierArchived => 'سپلائر آرکائیو ہو گیا';

  @override
  String get customers_supplierRestored => 'سپلائر بحال ہو گیا';

  @override
  String get customers_supplierTitle => 'سپلائرز';

  @override
  String get customers_title => 'گاہک';

  @override
  String get customers_totalCredit => 'کل ادھار دیا گیا';

  @override
  String get customers_totalPaid => 'کل ادا شدہ';

  @override
  String get customers_totalPurchases => 'کل خریداری';

  @override
  String get customers_totalReceived => 'کل وصول شدہ';

  @override
  String get customers_unarchive => 'بحال کریں';

  @override
  String get customers_urduVersion => 'اردو';

  @override
  String get customers_viewLedger => 'لیجر دیکھیں';

  @override
  String get dashboard_activityExpense => 'خرچ';

  @override
  String get dashboard_activityIncome => 'آمدنی';

  @override
  String get dashboard_activityPaymentIn => 'ادائیگی موصول';

  @override
  String get dashboard_activityPaymentOut => 'ادائیگی کی گئی';

  @override
  String dashboard_activityPurchase(String no) {
    return 'خریداری $no';
  }

  @override
  String dashboard_activitySale(String no) {
    return 'فروخت $no';
  }

  @override
  String get dashboard_bankBalance => 'بینک بیلنس';

  @override
  String get dashboard_cashInHand => 'نقد رقم';

  @override
  String get dashboard_lowStock => 'کم اسٹاک الرٹس';

  @override
  String get dashboard_lowStockOk => 'اسٹاک کی سطح بہتر ہے';

  @override
  String get dashboard_monthExpense => 'اس ماہ اخراجات';

  @override
  String get dashboard_monthIncome => 'اس ماہ آمدنی';

  @override
  String get dashboard_noActivity => 'کوئی حالیہ سرگرمی نہیں';

  @override
  String get dashboard_noActivityHint =>
      'فروخت، خریداری اور ادائیگیاں یہاں نظر آئیں گی';

  @override
  String get dashboard_paidToday => 'آج ادا شدہ';

  @override
  String get dashboard_pickCustomer => 'گاہک منتخب کریں';

  @override
  String get dashboard_pickSupplier => 'سپلائر منتخب کریں';

  @override
  String get dashboard_qaAddCustomer => 'گاہک شامل کریں';

  @override
  String get dashboard_qaAddExpense => 'خرچ درج کریں';

  @override
  String get dashboard_qaAddPurchase => 'خریداری درج کریں';

  @override
  String get dashboard_qaAddSale => 'فروخت درج کریں';

  @override
  String get dashboard_qaAddSupplier => 'سپلائر شامل کریں';

  @override
  String get dashboard_qaGiveUdhaar => 'ادھار دیں';

  @override
  String get dashboard_qaMakePayment => 'ادائیگی کریں';

  @override
  String get dashboard_qaReceivePayment => 'ادائیگی وصول کریں';

  @override
  String get dashboard_qaRecordProduction => 'پیداوار درج کریں';

  @override
  String get dashboard_qaViewReports => 'رپورٹس دیکھیں';

  @override
  String get dashboard_quickActions => 'فوری اقدامات';

  @override
  String get dashboard_receivedToday => 'آج وصول شدہ';

  @override
  String get dashboard_recentActivity => 'حالیہ سرگرمی';

  @override
  String dashboard_stockLeft(String qty, String unit) {
    return '$qty $unit باقی';
  }

  @override
  String get dashboard_thisMonth => 'اس ماہ';

  @override
  String get dashboard_title => 'ڈیش بورڈ';

  @override
  String get dashboard_today => 'آج';

  @override
  String get dashboard_todayPurchases => 'آج کی خریداری';

  @override
  String get dashboard_todaySales => 'آج کی فروخت';

  @override
  String get dashboard_totalBalance => 'کل بیلنس';

  @override
  String get dashboard_totalPayable => 'ادا کرنا ہے';

  @override
  String get dashboard_totalReceivable => 'وصول کرنا ہے';

  @override
  String get dashboard_viewAll => 'سب دیکھیں';

  @override
  String get expenses_account => 'کھاتہ';

  @override
  String get expenses_addCategory => 'نئی مد شامل کریں';

  @override
  String get expenses_addExpense => 'خرچ شامل کریں';

  @override
  String get expenses_addIncome => 'آمدنی شامل کریں';

  @override
  String get expenses_amount => 'رقم';

  @override
  String get expenses_category => 'مد';

  @override
  String get expenses_categoryName => 'مد کا نام';

  @override
  String get expenses_categorySaved => 'مد محفوظ ہو گئی';

  @override
  String get expenses_date => 'تاریخ';

  @override
  String get expenses_description => 'تفصیل';

  @override
  String get expenses_errAccountNotFound => 'کھاتہ نہیں ملا';

  @override
  String get expenses_errCategoryNotFound => 'مد نہیں ملی';

  @override
  String get expenses_errInvalidAmount => 'درست رقم درج کریں';

  @override
  String get expenses_expenseSaved => 'خرچ محفوظ ہو گیا';

  @override
  String get expenses_incomeCategory => 'آمدنی کی قسم (اختیاری)';

  @override
  String get expenses_incomeSaved => 'آمدنی محفوظ ہو گئی';

  @override
  String get expenses_noEntries => 'ابھی کوئی اندراج نہیں';

  @override
  String get expenses_reference => 'حوالہ';

  @override
  String get expenses_tabExpenses => 'اخراجات';

  @override
  String get expenses_tabIncome => 'آمدنی';

  @override
  String get expenses_thisMonth => 'اس ماہ';

  @override
  String get expenses_thisYear => 'اس سال';

  @override
  String get expenses_title => 'اخراجات و آمدنی';

  @override
  String get expenses_today => 'آج';

  @override
  String get expenses_totalExpenses => 'کل اخراجات';

  @override
  String get expenses_totalIncome => 'کل آمدنی';

  @override
  String get inventory_addConversion => 'تبادلہ شامل کریں';

  @override
  String get inventory_addProduct => 'مصنوعات شامل کریں';

  @override
  String get inventory_adjust => 'اسٹاک درست کریں';

  @override
  String get inventory_adjustment => 'درستگی';

  @override
  String get inventory_all => 'تمام';

  @override
  String get inventory_available => 'دستیاب';

  @override
  String get inventory_avgCost => 'اوسط لاگت';

  @override
  String get inventory_catConsumable => 'استعمال کی اشیاء';

  @override
  String get inventory_catContainer => 'ڈبے';

  @override
  String get inventory_catFinishedOil => 'تیار تیل';

  @override
  String get inventory_catOilCake => 'کھل';

  @override
  String get inventory_catPackaging => 'پیکنگ';

  @override
  String get inventory_catRawMaterial => 'خام مال';

  @override
  String get inventory_catSpare => 'اسپیئر پارٹس';

  @override
  String get inventory_category => 'قسم';

  @override
  String get inventory_conversionExists =>
      'اس جوڑے کے لیے تبادلہ پہلے سے موجود ہے';

  @override
  String get inventory_conversionsTitle => 'تبادلے';

  @override
  String get inventory_editConversion => 'تبادلے میں ترمیم کریں';

  @override
  String get inventory_editProduct => 'مصنوعات میں ترمیم کریں';

  @override
  String get inventory_errDatabase =>
      'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String inventory_errInsufficientStock(
      String available, String needed, String product) {
    return '$product کا اسٹاک ناکافی ہے (دستیاب $available، درکار $needed)';
  }

  @override
  String get inventory_errInvalidAmount => 'درست رقم درج کریں';

  @override
  String get inventory_errInvalidQty => 'صفر سے بڑی درست مقدار درج کریں';

  @override
  String get inventory_errNoConversion =>
      'ان اکائیوں کے درمیان کوئی تبادلہ مقرر نہیں';

  @override
  String get inventory_errProductNotFound => 'مصنوعات نہیں ملی';

  @override
  String get inventory_factor => 'تناسب';

  @override
  String inventory_factorHint(String from, String to) {
    return '1 $from میں کتنے $to؟';
  }

  @override
  String get inventory_factorPositive => 'تناسب صفر سے بڑا ہونا چاہیے';

  @override
  String get inventory_from => 'از';

  @override
  String get inventory_in => 'آمد';

  @override
  String get inventory_lowStock => 'کم اسٹاک';

  @override
  String get inventory_movements => 'اسٹاک کا ریکارڈ';

  @override
  String get inventory_name => 'مصنوعات کا نام';

  @override
  String get inventory_noConversions => 'ابھی کوئی تبادلہ مقرر نہیں';

  @override
  String get inventory_noMovements => 'ابھی کوئی ریکارڈ درج نہیں';

  @override
  String get inventory_noProducts => 'کوئی مصنوعات نہیں ملی';

  @override
  String get inventory_noProductsHint =>
      'اسٹاک کا ریکارڈ رکھنے کے لیے پہلی مصنوعات شامل کریں۔';

  @override
  String get inventory_openingStock => 'ابتدائی اسٹاک';

  @override
  String get inventory_openingStockReason => 'ابتدائی اسٹاک';

  @override
  String get inventory_out => 'خرچ';

  @override
  String get inventory_productSaved => 'مصنوعات محفوظ ہو گئی';

  @override
  String get inventory_qty => 'مقدار';

  @override
  String get inventory_reason => 'وجہ';

  @override
  String get inventory_reasonRequired => 'براہ کرم وجہ درج کریں';

  @override
  String get inventory_reorderLevel => 'دوبارہ آرڈر کی حد';

  @override
  String get inventory_salePrice => 'طے شدہ فروخت قیمت (اختیاری)';

  @override
  String get inventory_searchHint => 'مصنوعات تلاش کریں';

  @override
  String get inventory_sku => 'SKU (اختیاری)';

  @override
  String get inventory_stock => 'اسٹاک';

  @override
  String get inventory_stockIn => 'اسٹاک وصول کریں';

  @override
  String get inventory_stockInReason => 'اسٹاک وصولی';

  @override
  String get inventory_stockOut => 'اسٹاک جاری کریں';

  @override
  String get inventory_stockOutReason => 'اسٹاک اجراء';

  @override
  String get inventory_stockUpdated => 'اسٹاک اپ ڈیٹ ہو گیا';

  @override
  String get inventory_stockValue => 'اسٹاک کی مالیت';

  @override
  String get inventory_title => 'انوینٹری';

  @override
  String get inventory_to => 'تک';

  @override
  String get inventory_typeAdjustment => 'درستگی';

  @override
  String get inventory_typeProduction => 'پیداوار';

  @override
  String get inventory_typePurchase => 'خریداری';

  @override
  String get inventory_typeReturn => 'واپسی';

  @override
  String get inventory_typeSale => 'فروخت';

  @override
  String get inventory_unit => 'اکائی';

  @override
  String get inventory_units => 'اکائیاں اور تبادلے';

  @override
  String get inventory_unitsTitle => 'اکائیاں';

  @override
  String get khata_customers => 'گاہک';

  @override
  String get khata_errorAccountInactive => 'یہ اکاؤنٹ غیر فعال ہے۔';

  @override
  String get khata_errorAccountNotFound => 'اکاؤنٹ نہیں ملا۔';

  @override
  String get khata_errorAlreadyReversed =>
      'اس اندراج کو پہلے ہی کالعدم کیا جا چکا ہے۔';

  @override
  String get khata_errorCategoryInactive => 'یہ کیٹیگری غیر فعال ہے۔';

  @override
  String get khata_errorCategoryNotFound => 'کیٹیگری نہیں ملی۔';

  @override
  String get khata_errorCustomerArchived => 'یہ گاہک آرکائیو شدہ ہے۔';

  @override
  String get khata_errorCustomerNotFound => 'گاہک نہیں ملا۔';

  @override
  String get khata_errorDatabase => 'ڈیٹا بیس میں خرابی۔ دوبارہ کوشش کریں۔';

  @override
  String get khata_errorEmptyBatchInputs =>
      'بیچ کے لیے کم از کم ایک ان پٹ ضروری ہے۔';

  @override
  String get khata_errorEmptyBatchOutputs =>
      'بیچ کے لیے کم از کم ایک آؤٹ پٹ ضروری ہے۔';

  @override
  String get khata_errorEmptyInvoice => 'انوائس میں کوئی آئٹم نہیں۔';

  @override
  String get khata_errorEmptyJournal => 'جرنل میں کوئی اندراج نہیں۔';

  @override
  String get khata_errorEmptyReturn => 'واپسی میں کوئی آئٹم نہیں۔';

  @override
  String get khata_errorEntryNotFound => 'لیجر اندراج نہیں ملا۔';

  @override
  String khata_errorInsufficientStock(String product) {
    return '$product کا اسٹاک ناکافی ہے۔';
  }

  @override
  String get khata_errorInvalidAmount => 'غلط رقم۔';

  @override
  String get khata_errorInvalidJournalLine => 'غلط جرنل اندراج۔';

  @override
  String get khata_errorInvalidQty => 'غلط مقدار۔';

  @override
  String get khata_errorInvoiceNotFound => 'انوائس نہیں ملی۔';

  @override
  String get khata_errorMethodAccountMismatch =>
      'ادائیگی کا طریقہ اکاؤنٹ سے مطابقت نہیں رکھتا۔';

  @override
  String get khata_errorNegativeCost => 'لاگت منفی نہیں ہو سکتی۔';

  @override
  String get khata_errorNegativePrice => 'قیمت منفی نہیں ہو سکتی۔';

  @override
  String get khata_errorNegativeTax => 'ٹیکس منفی نہیں ہو سکتا۔';

  @override
  String get khata_errorNegativeTotal => 'کل رقم منفی نہیں ہو سکتی۔';

  @override
  String get khata_errorNoConversion => 'یونٹ کی تبدیلی دستیاب نہیں۔';

  @override
  String get khata_errorNotADraft => 'اس طرح صرف ڈرافٹ تبدیل ہو سکتا ہے۔';

  @override
  String get khata_errorOilCostAllocation => 'تیل کی لاگت تقسیم نہیں ہو سکی۔';

  @override
  String get khata_errorOverAllocated => 'ادائیگی بقایا رقم سے زیادہ ہے۔';

  @override
  String get khata_errorOverAllocatedInvoice =>
      'ادائیگی انوائس کے بقایا سے زیادہ ہے۔';

  @override
  String get khata_errorProductArchived => 'یہ پراڈکٹ آرکائیو شدہ ہے۔';

  @override
  String get khata_errorProductNotFound => 'پراڈکٹ نہیں ملا۔';

  @override
  String get khata_errorReasonRequired => 'وجہ بتانا ضروری ہے۔';

  @override
  String get khata_errorReturnExceedsBought => 'واپسی خریداری سے زیادہ ہے۔';

  @override
  String get khata_errorReturnExceedsSold => 'واپسی فروخت سے زیادہ ہے۔';

  @override
  String get khata_errorSupplierArchived => 'یہ سپلائر آرکائیو شدہ ہے۔';

  @override
  String get khata_errorSupplierNotFound => 'سپلائر نہیں ملا۔';

  @override
  String get khata_errorTransferSameAccount =>
      'ایک ہی اکاؤنٹ میں منتقلی نہیں ہو سکتی۔';

  @override
  String get khata_errorUnbalancedJournal => 'جرنل متوازن نہیں ہے۔';

  @override
  String get khata_errorUnitNotFound => 'یونٹ نہیں ملا۔';

  @override
  String get khata_noDues => 'سب حساب برابر ہے';

  @override
  String get khata_noDuesHint => 'کوئی بقایا رقم نہیں';

  @override
  String get khata_suppliers => 'سپلائرز';

  @override
  String get khata_title => 'کھاتہ';

  @override
  String get khata_toPay => 'ادا کرنا ہے';

  @override
  String get khata_toReceive => 'وصول کرنا ہے';

  @override
  String get khata_viewAllCustomers => 'گاہک دیکھیں';

  @override
  String get khata_viewAllSuppliers => 'سپلائرز دیکھیں';

  @override
  String get production_addInput => 'ان پٹ شامل کریں';

  @override
  String get production_addOutput => 'آؤٹ پٹ شامل کریں';

  @override
  String production_available(String qty, String unit) {
    return 'دستیاب: $qty $unit';
  }

  @override
  String get production_batchAuto => 'بیچ پوسٹ کرتے وقت خود بن جائے گا';

  @override
  String get production_batchNo => 'بیچ نمبر';

  @override
  String get production_costBreakdown => 'لاگت کی تفصیل';

  @override
  String get production_costsCashHint =>
      'منتخب کرنے کی صورت میں مزدوری، بجلی اور دیگر اخراجات اس کھاتے سے پوسٹ ہوں گے۔';

  @override
  String get production_date => 'تاریخ';

  @override
  String get production_electricityCost => 'بجلی کی لاگت';

  @override
  String get production_emptyInputs => 'کم از کم ایک ان پٹ شامل کریں';

  @override
  String get production_emptyOutputs => 'کم از کم ایک آؤٹ پٹ شامل کریں';

  @override
  String get production_errNegativeCost => 'لاگت منفی نہیں ہو سکتی';

  @override
  String get production_expectedYield => 'متوقع پیداوار ٪ (اختیاری)';

  @override
  String get production_inputs => 'خام مال (ان پٹ)';

  @override
  String production_inputsCount(String count) {
    return '$count ان پٹ';
  }

  @override
  String get production_labourCost => 'مزدوری کی لاگت';

  @override
  String get production_materialCost => 'خام مال کی لاگت';

  @override
  String get production_newBatch => 'نیا بیچ';

  @override
  String get production_noBatches => 'ابھی کوئی بیچ نہیں بنا';

  @override
  String get production_noBatchesHint => 'پہلا پیداواری بیچ شروع کریں۔';

  @override
  String get production_notes => 'نوٹس';

  @override
  String get production_otherCost => 'دیگر لاگت';

  @override
  String get production_outOfStock => 'ابھی خام مال کی کوئی مصنوعات نہیں';

  @override
  String get production_outputType => 'آؤٹ پٹ کی قسم';

  @override
  String get production_outputs => 'آؤٹ پٹ';

  @override
  String get production_payCostsFrom => 'اخراجات کی ادائیگی';

  @override
  String get production_payCostsNone => 'کوئی نہیں (الگ سے درج کریں)';

  @override
  String get production_postBatch => 'بیچ پوسٹ کریں';

  @override
  String get production_qtyGtZero => 'مقدار صفر سے بڑی ہونی چاہیے';

  @override
  String get production_rawOnly => 'ان پٹ کے لیے صرف خام مال کی مصنوعات';

  @override
  String get production_removeLine => 'لائن ہٹائیں';

  @override
  String get production_resultNoYield =>
      'پیداوار معلوم نہیں ہو سکی — استعمال شدہ اکائیوں کے لیے کلوگرام کا تبادلہ شامل کریں۔';

  @override
  String get production_resultTitle => 'بیچ پوسٹ ہو گیا';

  @override
  String production_resultYield(String pct) {
    return 'پیداوار: $pct٪';
  }

  @override
  String get production_selectProduct => 'مصنوعات منتخب کریں';

  @override
  String get production_statusCostsPosted => 'اخراجات کیش بک میں';

  @override
  String get production_statusPosted => 'پوسٹ شدہ';

  @override
  String get production_title => 'پیداوار';

  @override
  String get production_totalCost => 'کل لاگت';

  @override
  String get production_typeByProduct => 'ضمنی پیداوار';

  @override
  String get production_typeFinishedOil => 'تیار تیل';

  @override
  String get production_typeOilCake => 'کھل';

  @override
  String get production_wastage => 'ضیاع / نقصان';

  @override
  String get production_yield => 'پیداوار کی شرح';

  @override
  String get purchases_confirmPost =>
      'کیا یہ خریداری درج کریں؟ اسٹاک بڑھ جائے گا۔';

  @override
  String get purchases_deleteDraft => 'مسودہ حذف کریں';

  @override
  String get purchases_detailTitle => 'خریداری کی تفصیل';

  @override
  String get purchases_draftDeleted => 'مسودہ حذف ہو گیا';

  @override
  String purchases_draftSaved(String invoiceNo) {
    return 'مسودہ $invoiceNo محفوظ ہو گیا';
  }

  @override
  String get purchases_emptyTitle => 'ابھی کوئی خریداری نہیں';

  @override
  String get purchases_formTitle => 'نئی خریداری';

  @override
  String get purchases_lineItems => 'آئٹمز';

  @override
  String get purchases_newPurchase => 'نئی خریداری';

  @override
  String get purchases_noItems => 'کم از کم ایک آئٹم شامل کریں';

  @override
  String get purchases_noSupplierSelected => 'پہلے سپلائر منتخب کریں';

  @override
  String get purchases_payments => 'ادائیگیاں';

  @override
  String get purchases_postDraft => 'مسودہ درج کریں';

  @override
  String get purchases_postPurchase => 'خریداری درج کریں';

  @override
  String purchases_purchasePosted(String invoiceNo) {
    return 'خریداری $invoiceNo درج ہو گئی';
  }

  @override
  String get purchases_recordPayment => 'ادائیگی درج کریں';

  @override
  String get purchases_returnTitle => 'خریداری واپسی';

  @override
  String get purchases_searchHint => 'واؤچر نمبر یا سپلائر تلاش کریں…';

  @override
  String get purchases_searchSupplier => 'سپلائر تلاش کریں…';

  @override
  String get purchases_selectSupplier => 'سپلائر منتخب کریں';

  @override
  String get purchases_statusCancelled => 'منسوخ شدہ';

  @override
  String get purchases_statusDraft => 'مسودہ';

  @override
  String get purchases_statusPaid => 'ادا شدہ';

  @override
  String get purchases_statusPartial => 'جزوی ادا شدہ';

  @override
  String get purchases_statusReturned => 'واپس شدہ';

  @override
  String get purchases_statusUnpaid => 'غیر ادا شدہ';

  @override
  String get purchases_supplier => 'سپلائر';

  @override
  String get purchases_title => 'خریداری';

  @override
  String get purchases_voucherPdf => 'خریداری واؤچر PDF';

  @override
  String get reports_title => 'رپورٹس';

  @override
  String get reports_dailySummary => 'یومیہ خلاصہ';

  @override
  String get reports_monthlySummary => 'ماہانہ خلاصہ';

  @override
  String get reports_customerLedger => 'گاہک کھاتہ';

  @override
  String get reports_supplierLedger => 'سپلائر کھاتہ';

  @override
  String get reports_receivables => 'قابلِ وصول رقوم';

  @override
  String get reports_payables => 'قابلِ ادائیگی رقوم';

  @override
  String get reports_sales => 'فروخت';

  @override
  String get reports_purchase => 'خریداری';

  @override
  String get reports_paymentsReceived => 'موصولہ ادائیگیاں';

  @override
  String get reports_paymentsMade => 'ادا شدہ ادائیگیاں';

  @override
  String get reports_expense => 'اخراجات';

  @override
  String get reports_income => 'آمدنی';

  @override
  String get reports_cashbook => 'کیش بک';

  @override
  String get reports_cashBankBalances => 'نقد و بینک بیلنس';

  @override
  String get reports_inventoryValuation => 'اسٹاک کی مالیت';

  @override
  String get reports_stockMovement => 'اسٹاک کی نقل و حرکت';

  @override
  String get reports_lowStock => 'کم اسٹاک';

  @override
  String get reports_production => 'پیداوار';

  @override
  String get reports_yield => 'پیداواری شرح';

  @override
  String get reports_salesReturns => 'فروخت واپسی';

  @override
  String get reports_purchaseReturns => 'خریداری واپسی';

  @override
  String get reports_outstandingInvoices => 'بقایا انوائسز';

  @override
  String get reports_profitLoss => 'نفع و نقصان';

  @override
  String get reports_trialBalance => 'ٹرائل بیلنس';

  @override
  String get reports_daybook => 'روزنامچہ';

  @override
  String get reports_selectCustomer => 'گاہک منتخب کریں';

  @override
  String get reports_selectSupplier => 'سپلائر منتخب کریں';

  @override
  String get reports_selectProduct => 'پراڈکٹ منتخب کریں';

  @override
  String get reports_selectAccount => 'اکاؤنٹ منتخب کریں';

  @override
  String get reports_change => 'تبدیل کریں';

  @override
  String get reports_customRange => 'اپنی مدت';

  @override
  String get reports_pickDate => 'تاریخ منتخب کریں';

  @override
  String get reports_pickMonth => 'مہینہ منتخب کریں';

  @override
  String get reports_all => 'تمام';

  @override
  String get reports_totalSales => 'کل فروخت';

  @override
  String get reports_totalPurchases => 'کل خریداری';

  @override
  String get reports_totalReceived => 'کل موصول';

  @override
  String get reports_totalPaid => 'کل ادائیگی';

  @override
  String get reports_totalExpenses => 'کل اخراجات';

  @override
  String get reports_totalIncome => 'کل آمدنی';

  @override
  String get reports_netProfit => 'خالص نفع';

  @override
  String get reports_netLoss => 'خالص نقصان';

  @override
  String get reports_estimatedNote =>
      'تخمینہ — اس مدت کے لاگت کے اعداد و شمار نامکمل ہیں۔';

  @override
  String get reports_openingBalance => 'ابتدائی بیلنس';

  @override
  String get reports_closingBalance => 'اختتامی بیلنس';

  @override
  String reports_recordsCount(String count) {
    return '$count ریکارڈ';
  }

  @override
  String get reports_due => 'بقایا';

  @override
  String get reports_paid => 'ادا شدہ';

  @override
  String get reports_unpaid => 'غیر ادا شدہ';

  @override
  String get reports_partial => 'جزوی ادائیگی';

  @override
  String get reports_invoices => 'انوائسز';

  @override
  String get reports_stockValue => 'اسٹاک کی مالیت';

  @override
  String get reports_avgYield => 'اوسط پیداواری شرح';

  @override
  String get reports_batches => 'بیچز';

  @override
  String get reports_quantity => 'مقدار';

  @override
  String get reports_avgCost => 'اوسط لاگت';

  @override
  String get reports_reorderLevel => 'دوبارہ آرڈر کی حد';

  @override
  String get reports_onHand => 'موجودہ اسٹاک';

  @override
  String get reports_copyReminder => 'یاددہانی نقل کریں';

  @override
  String get reports_copied => 'کلپ بورڈ میں نقل ہو گیا';

  @override
  String get reports_noData => 'اس مدت کے لیے کوئی ڈیٹا نہیں ہے۔';

  @override
  String get reports_saleInvoices => 'فروخت کی انوائسز';

  @override
  String get reports_purchaseInvoices => 'خریداری کی انوائسز';

  @override
  String get reports_value => 'مالیت';

  @override
  String get reports_expensesByCategory => 'زمرہ کے حساب سے اخراجات';

  @override
  String get reports_customers => 'گاہک';

  @override
  String get reports_suppliers => 'سپلائرز';

  @override
  String get reports_accounts => 'اکاؤنٹس';

  @override
  String get reports_grandTotal => 'مجموعی میزان';

  @override
  String get reports_doc_saleInvoice => 'فروخت انوائس';

  @override
  String get reports_doc_purchaseVoucher => 'خریداری واؤچر';

  @override
  String get reports_doc_paymentReceipt => 'ادائیگی کی رسید';

  @override
  String get reports_doc_supplierPaymentVoucher => 'سپلائر ادائیگی واؤچر';

  @override
  String get reports_doc_customerStatement => 'گاہک کھاتہ اسٹیٹمنٹ';

  @override
  String get reports_doc_supplierStatement => 'سپلائر کھاتہ اسٹیٹمنٹ';

  @override
  String get reports_doc_cashReceipt => 'نقد رسید';

  @override
  String get reports_doc_expenseVoucher => 'اخراجات کا واؤچر';

  @override
  String get reports_doc_productionReport => 'پیداوار کی رپورٹ';

  @override
  String get reports_doc_savePdf => 'پی ڈی ایف محفوظ کریں';

  @override
  String get reports_doc_share => 'شیئر کریں';

  @override
  String get reports_doc_print => 'پرنٹ کریں';

  @override
  String get reports_doc_pdfSaved => 'پی ڈی ایف محفوظ ہو گئی۔';

  @override
  String get reports_doc_billTo => 'بل برائے';

  @override
  String get reports_doc_supplier => 'سپلائر';

  @override
  String get reports_doc_customer => 'گاہک';

  @override
  String get reports_doc_invoiceNo => 'انوائس نمبر';

  @override
  String get reports_doc_date => 'تاریخ';

  @override
  String get reports_doc_status => 'حالت';

  @override
  String get reports_doc_items => 'آئٹمز';

  @override
  String get reports_doc_item => 'آئٹم';

  @override
  String get reports_doc_qty => 'مقدار';

  @override
  String get reports_doc_price => 'قیمت';

  @override
  String get reports_doc_amount => 'رقم';

  @override
  String get reports_doc_subtotal => 'ذیلی میزان';

  @override
  String get reports_doc_discount => 'رعایت';

  @override
  String get reports_doc_tax => 'ٹیکس';

  @override
  String get reports_doc_total => 'کل میزان';

  @override
  String get reports_doc_paid => 'ادا شدہ';

  @override
  String get reports_doc_due => 'بقایا رقم';

  @override
  String get reports_doc_notes => 'نوٹس';

  @override
  String get reports_doc_receivedFrom => 'موصول از';

  @override
  String get reports_doc_paidTo => 'ادا شدہ بہ';

  @override
  String get reports_doc_account => 'اکاؤنٹ';

  @override
  String get reports_doc_method => 'طریقہ';

  @override
  String get reports_doc_reference => 'حوالہ';

  @override
  String get reports_doc_category => 'زمرہ';

  @override
  String get reports_doc_description => 'تفصیل';

  @override
  String get reports_doc_openingBalance => 'ابتدائی بیلنس';

  @override
  String get reports_doc_closingBalance => 'اختتامی بیلنس';

  @override
  String get reports_doc_debit => 'ڈیبٹ';

  @override
  String get reports_doc_credit => 'کریڈٹ';

  @override
  String get reports_doc_balance => 'بیلنس';

  @override
  String get reports_doc_inputs => 'استعمال شدہ خام مال';

  @override
  String get reports_doc_outputs => 'حاصل شدہ پیداوار';

  @override
  String get reports_doc_yield => 'پیداواری شرح';

  @override
  String get reports_doc_batchNo => 'بیچ نمبر';

  @override
  String reports_doc_generatedOn(String date) {
    return '$date کو تیار کردہ';
  }

  @override
  String get reports_doc_cash => 'نقد';

  @override
  String get reports_doc_bank => 'بینک';

  @override
  String get reports_doc_from => 'از';

  @override
  String get reports_doc_to => 'تا';

  @override
  String get reports_doc_period => 'مدت';

  @override
  String get reports_doc_oilCake => 'تیل کی کھلی';

  @override
  String get reports_doc_byProduct => 'ذیلی پیداوار';

  @override
  String get reports_doc_labour => 'مزدوری';

  @override
  String get reports_doc_electricity => 'بجلی';

  @override
  String get reports_doc_other => 'دیگر';

  @override
  String get sales_confirmPost => 'کیا یہ فروخت درج کریں؟ اسٹاک کم ہو جائے گا۔';

  @override
  String get sales_customer => 'گاہک';

  @override
  String get sales_deleteDraft => 'مسودہ حذف کریں';

  @override
  String get sales_detailTitle => 'فروخت کی تفصیل';

  @override
  String get sales_draftDeleted => 'مسودہ حذف ہو گیا';

  @override
  String sales_draftSaved(String invoiceNo) {
    return 'مسودہ $invoiceNo محفوظ ہو گیا';
  }

  @override
  String get sales_emptyTitle => 'ابھی کوئی فروخت نہیں';

  @override
  String get sales_formTitle => 'نئی فروخت';

  @override
  String get sales_invoicePdf => 'انوائس PDF';

  @override
  String get sales_lineItems => 'آئٹمز';

  @override
  String get sales_newSale => 'نئی فروخت';

  @override
  String get sales_noCustomerSelected => 'پہلے گاہک منتخب کریں';

  @override
  String get sales_noItems => 'کم از کم ایک آئٹم شامل کریں';

  @override
  String get sales_payments => 'ادائیگیاں';

  @override
  String get sales_postDraft => 'مسودہ درج کریں';

  @override
  String get sales_postSale => 'فروخت درج کریں';

  @override
  String get sales_recordPayment => 'ادائیگی درج کریں';

  @override
  String get sales_returnTitle => 'فروخت واپسی';

  @override
  String sales_salePosted(String invoiceNo) {
    return 'فروخت $invoiceNo درج ہو گئی';
  }

  @override
  String get sales_searchCustomer => 'گاہک تلاش کریں…';

  @override
  String get sales_searchHint => 'انوائس نمبر یا گاہک تلاش کریں…';

  @override
  String get sales_selectCustomer => 'گاہک منتخب کریں';

  @override
  String get sales_share => 'شیئر کریں';

  @override
  String get sales_statusCancelled => 'منسوخ شدہ';

  @override
  String get sales_statusDraft => 'مسودہ';

  @override
  String get sales_statusPaid => 'ادا شدہ';

  @override
  String get sales_statusPartial => 'جزوی ادا شدہ';

  @override
  String get sales_statusReturned => 'واپس شدہ';

  @override
  String get sales_statusUnpaid => 'غیر ادا شدہ';

  @override
  String get sales_title => 'فروخت';

  @override
  String get transactions_account => 'اکاؤنٹ';

  @override
  String get transactions_addItem => 'آئٹم شامل کریں';

  @override
  String get transactions_adjustment => 'ایڈجسٹمنٹ';

  @override
  String get transactions_bank => 'بینک';

  @override
  String get transactions_cash => 'نقد';

  @override
  String get transactions_category => 'زمرہ';

  @override
  String get transactions_credit => 'کریڈٹ';

  @override
  String get transactions_customRange => 'مرضی کی مدت';

  @override
  String transactions_customRangeHint(String from, String to) {
    return '$from – $to';
  }

  @override
  String get transactions_customRangeTitle => 'مدت منتخب کریں';

  @override
  String get transactions_date => 'تاریخ';

  @override
  String get transactions_debit => 'ڈیبٹ';

  @override
  String get transactions_description => 'تفصیل';

  @override
  String get transactions_detailTitle => 'لین دین کی تفصیل';

  @override
  String get transactions_discount => 'رعایت';

  @override
  String get transactions_discountPct => 'رعایت ٪';

  @override
  String get transactions_due => 'بقایا';

  @override
  String get transactions_emptyTitle => 'کوئی لین دین نہیں';

  @override
  String transactions_entriesCount(int count) {
    return '$count اندراجات';
  }

  @override
  String get transactions_entryNo => 'اندراج نمبر';

  @override
  String get transactions_expense => 'اخراجات';

  @override
  String get transactions_filterAll => 'تمام';

  @override
  String get transactions_filterPaymentPaid => 'ادا شدہ ادائیگی';

  @override
  String get transactions_filterPaymentReceived => 'موصولہ ادائیگی';

  @override
  String get transactions_income => 'آمدنی';

  @override
  String get transactions_invalidPrice => 'درست قیمت درج کریں';

  @override
  String get transactions_invalidQty => 'درست مقدار درج کریں';

  @override
  String get transactions_invoiceDiscount => 'انوائس رعایت ٪';

  @override
  String get transactions_lineTotal => 'لائن کل';

  @override
  String transactions_maxQty(String qty) {
    return 'زیادہ سے زیادہ $qty';
  }

  @override
  String get transactions_noDescription => '—';

  @override
  String get transactions_notes => 'نوٹس';

  @override
  String get transactions_paidAmount => 'ابھی ادائیگی';

  @override
  String get transactions_paymentAccount => 'اکاؤنٹ';

  @override
  String get transactions_paymentAmount => 'رقم';

  @override
  String get transactions_paymentMethod => 'طریقہ';

  @override
  String get transactions_paymentReference => 'حوالہ';

  @override
  String get transactions_paymentSaved => 'ادائیگی محفوظ ہو گئی';

  @override
  String get transactions_paymentTitle => 'ادائیگی درج کریں';

  @override
  String get transactions_production => 'پیداوار';

  @override
  String get transactions_purchase => 'خریداری';

  @override
  String get transactions_qty => 'مقدار';

  @override
  String get transactions_reference => 'حوالہ';

  @override
  String get transactions_removeLine => 'لائن ہٹائیں';

  @override
  String get transactions_return => 'واپسی';

  @override
  String get transactions_returnPosted => 'واپسی درج ہو گئی';

  @override
  String get transactions_returnReason => 'وجہ (اختیاری)';

  @override
  String get transactions_returnTitle => 'آئٹم واپسی';

  @override
  String get transactions_reversal => 'تنسیخی اندراج';

  @override
  String transactions_reversalOf(String entryNo) {
    return '$entryNo کی تنسیخ';
  }

  @override
  String get transactions_reversed => 'کالعدم';

  @override
  String get transactions_sale => 'فروخت';

  @override
  String get transactions_saveDraft => 'مسودہ محفوظ کریں';

  @override
  String get transactions_searchHint => 'تفصیل یا اندراج نمبر تلاش کریں…';

  @override
  String get transactions_searchProduct => 'مصنوعات تلاش کریں…';

  @override
  String get transactions_selectProduct => 'مصنوعات منتخب کریں';

  @override
  String get transactions_sortNewest => 'تازہ ترین';

  @override
  String get transactions_sortOldest => 'قدیم ترین';

  @override
  String get transactions_submitPayment => 'ادائیگی محفوظ کریں';

  @override
  String get transactions_submitReturn => 'واپسی درج کریں';

  @override
  String get transactions_subtotal => 'ذیلی کل';

  @override
  String get transactions_tax => 'ٹیکس';

  @override
  String get transactions_taxPct => 'ٹیکس ٪';

  @override
  String get transactions_title => 'لین دین';

  @override
  String get transactions_total => 'جرنل کل';

  @override
  String get transactions_transfer => 'منتقلی';

  @override
  String get transactions_unit => 'اکائی';

  @override
  String get transactions_unitPrice => 'فی اکائی قیمت';

  @override
  String get udhaar_saved => 'ادھار درج کر دیا گیا';

  @override
  String get udhaar_title => 'ادھار دیں';
}
