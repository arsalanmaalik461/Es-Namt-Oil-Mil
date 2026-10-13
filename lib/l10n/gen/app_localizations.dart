import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// About screen: app name
  ///
  /// In en, this message translates to:
  /// **'Namt Oil Mil'**
  String get about_appName;

  /// About screen: offline guarantee note
  ///
  /// In en, this message translates to:
  /// **'100% offline — all your data stays on this device only.'**
  String get about_offline;

  /// About screen: version line
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String about_version(String version);

  /// Short tagline under the app name
  ///
  /// In en, this message translates to:
  /// **'Your Digital Khata'**
  String get appTagline;

  /// App name shown in app bar and OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Namt Oil Mil'**
  String get appTitle;

  /// Generic add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// Generic amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get common_amount;

  /// Generic back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// Generic balance label
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get common_balance;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Generic close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// Generic date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get common_date;

  /// Generic delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// Generic edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// Generic no button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// Generic notes label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get common_notes;

  /// Generic OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// Retry button after an error
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_retry;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// Generic search hint / button
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// Generic total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get common_total;

  /// Generic yes button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// Delete confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this? This cannot be undone.'**
  String get confirmDelete_message;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete_title;

  /// Date filter chip: all dates
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dateFilter_all;

  /// Date filter chip: this month
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dateFilter_month;

  /// Date filter chip: today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateFilter_today;

  /// Date filter chip: this week
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dateFilter_week;

  /// Default empty-state message
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get empty_default;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get error_generic;

  /// Language option: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// Language option: Urdu
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get langUrdu;

  /// More hub: about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get more_about;

  /// More hub: backup and restore
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get more_backup;

  /// More hub: cashbook
  ///
  /// In en, this message translates to:
  /// **'Cashbook'**
  String get more_cashbook;

  /// More hub: expenses and income
  ///
  /// In en, this message translates to:
  /// **'Expenses & Income'**
  String get more_expensesIncome;

  /// More hub: inventory
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get more_inventory;

  /// More hub: production
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get more_production;

  /// More hub: purchases
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get more_purchases;

  /// More hub: sales
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get more_sales;

  /// More hub: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get more_settings;

  /// Bottom nav: home tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_home;

  /// Bottom nav: khata (ledgers) tab
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get nav_khata;

  /// Bottom nav: more tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get nav_more;

  /// Bottom nav: reports tab
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get nav_reports;

  /// Bottom nav: transactions tab
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get nav_transactions;

  /// Settings: about section
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get settings_about;

  /// Business profile: address field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settings_address;

  /// Business profile: name field
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get settings_businessName;

  /// Settings: business profile section
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get settings_businessProfile;

  /// Settings: language section
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// Business profile: phone field
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get settings_phone;

  /// Snackbar after settings are saved
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settings_saved;

  /// Settings: theme section
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Theme option: dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme option: light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: follow system
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// Validation: amount not a positive number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get val_invalidAmount;

  /// Validation: phone number format
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get val_invalidPhone;

  /// Validation: empty required field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get val_required;

  /// No description provided for @backup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backup_title;

  /// No description provided for @backup_intro.
  ///
  /// In en, this message translates to:
  /// **'Keep a safe copy of all your data. Backups are a single JSON file stored on this device only — nothing is uploaded.'**
  String get backup_intro;

  /// No description provided for @backup_create.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get backup_create;

  /// No description provided for @backup_creating.
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get backup_creating;

  /// No description provided for @backup_created.
  ///
  /// In en, this message translates to:
  /// **'Backup created — {count} records in {tables} tables.'**
  String backup_created(String count, String tables);

  /// No description provided for @backup_savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String backup_savedTo(String path);

  /// No description provided for @backup_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backup_restore;

  /// No description provided for @backup_chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get backup_chooseFile;

  /// No description provided for @backup_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading backup…'**
  String get backup_reading;

  /// No description provided for @backup_summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup summary'**
  String get backup_summaryTitle;

  /// No description provided for @backup_exportedAt.
  ///
  /// In en, this message translates to:
  /// **'Exported {date}'**
  String backup_exportedAt(String date);

  /// No description provided for @backup_tablesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tables'**
  String backup_tablesCount(String count);

  /// No description provided for @backup_recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String backup_recordsCount(String count);

  /// No description provided for @backup_confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backup_confirmTitle;

  /// No description provided for @backup_confirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All current data will be REPLACED by the backup. This cannot be undone.'**
  String get backup_confirmMessage;

  /// No description provided for @backup_confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backup_confirmRestore;

  /// No description provided for @backup_restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get backup_restoring;

  /// No description provided for @backup_restored.
  ///
  /// In en, this message translates to:
  /// **'Restore complete — {count} records restored.'**
  String backup_restored(String count);

  /// No description provided for @backup_errorInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid Namt Oil Mil backup.'**
  String get backup_errorInvalidFile;

  /// No description provided for @backup_errorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported backup version: {version}.'**
  String backup_errorUnsupportedVersion(String version);

  /// No description provided for @backup_errorMissingTables.
  ///
  /// In en, this message translates to:
  /// **'Backup is missing tables: {tables}.'**
  String backup_errorMissingTables(String tables);

  /// No description provided for @backup_errorChecksum.
  ///
  /// In en, this message translates to:
  /// **'Backup data is corrupted (checksum mismatch in {table}).'**
  String backup_errorChecksum(String table);

  /// No description provided for @cashbook_accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get cashbook_accountName;

  /// No description provided for @cashbook_accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get cashbook_accountType;

  /// No description provided for @cashbook_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get cashbook_accounts;

  /// No description provided for @cashbook_addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get cashbook_addAccount;

  /// No description provided for @cashbook_addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get cashbook_addPayment;

  /// No description provided for @cashbook_addReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add receipt'**
  String get cashbook_addReceipt;

  /// No description provided for @cashbook_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get cashbook_amount;

  /// No description provided for @cashbook_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get cashbook_balance;

  /// No description provided for @cashbook_customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get cashbook_customer;

  /// No description provided for @cashbook_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get cashbook_date;

  /// No description provided for @cashbook_editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get cashbook_editAccount;

  /// No description provided for @cashbook_entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get cashbook_entries;

  /// No description provided for @cashbook_errAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get cashbook_errAccountNotFound;

  /// No description provided for @cashbook_errInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get cashbook_errInvalidAmount;

  /// No description provided for @cashbook_errTransferSame.
  ///
  /// In en, this message translates to:
  /// **'The From and To accounts must be different'**
  String get cashbook_errTransferSame;

  /// No description provided for @cashbook_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get cashbook_from;

  /// No description provided for @cashbook_in.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get cashbook_in;

  /// No description provided for @cashbook_method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get cashbook_method;

  /// No description provided for @cashbook_methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get cashbook_methodBank;

  /// No description provided for @cashbook_methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashbook_methodCash;

  /// No description provided for @cashbook_newTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get cashbook_newTransfer;

  /// No description provided for @cashbook_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get cashbook_noAccounts;

  /// No description provided for @cashbook_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries in this period'**
  String get cashbook_noEntries;

  /// No description provided for @cashbook_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get cashbook_notes;

  /// No description provided for @cashbook_openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get cashbook_openingBalance;

  /// No description provided for @cashbook_out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get cashbook_out;

  /// No description provided for @cashbook_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get cashbook_payment;

  /// No description provided for @cashbook_pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get cashbook_pickAccount;

  /// No description provided for @cashbook_receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get cashbook_receipt;

  /// No description provided for @cashbook_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get cashbook_reference;

  /// No description provided for @cashbook_selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get cashbook_selectCustomer;

  /// No description provided for @cashbook_selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select supplier'**
  String get cashbook_selectSupplier;

  /// No description provided for @cashbook_supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get cashbook_supplier;

  /// No description provided for @cashbook_title.
  ///
  /// In en, this message translates to:
  /// **'Cashbook'**
  String get cashbook_title;

  /// No description provided for @cashbook_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get cashbook_to;

  /// No description provided for @cashbook_totalIn.
  ///
  /// In en, this message translates to:
  /// **'Total in'**
  String get cashbook_totalIn;

  /// No description provided for @cashbook_totalOut.
  ///
  /// In en, this message translates to:
  /// **'Total out'**
  String get cashbook_totalOut;

  /// No description provided for @cashbook_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get cashbook_transfer;

  /// No description provided for @cashbook_transferInfo.
  ///
  /// In en, this message translates to:
  /// **'A transfer moves money between two accounts. It is never income or expense.'**
  String get cashbook_transferInfo;

  /// No description provided for @cashbook_typeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get cashbook_typeBank;

  /// No description provided for @cashbook_typeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashbook_typeCash;

  /// No description provided for @customers_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get customers_account;

  /// No description provided for @customers_addCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customers_addCustomer;

  /// No description provided for @customers_addFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to track udhaar'**
  String get customers_addFirstHint;

  /// No description provided for @customers_addFirstSupplierHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first supplier to track purchases'**
  String get customers_addFirstSupplierHint;

  /// No description provided for @customers_addSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get customers_addSupplier;

  /// No description provided for @customers_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customers_address;

  /// No description provided for @customers_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (PKR)'**
  String get customers_amount;

  /// No description provided for @customers_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get customers_archive;

  /// No description provided for @customers_archiveMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be hidden from lists, but their history is kept.'**
  String get customers_archiveMessage;

  /// No description provided for @customers_archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String customers_archiveTitle(String name);

  /// No description provided for @customers_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get customers_bank;

  /// No description provided for @customers_businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get customers_businessName;

  /// No description provided for @customers_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get customers_cash;

  /// No description provided for @customers_code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get customers_code;

  /// No description provided for @customers_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get customers_copied;

  /// No description provided for @customers_copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get customers_copyText;

  /// No description provided for @customers_customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customers_customRange;

  /// No description provided for @customers_customerArchived.
  ///
  /// In en, this message translates to:
  /// **'Customer archived'**
  String get customers_customerArchived;

  /// No description provided for @customers_customerRestored.
  ///
  /// In en, this message translates to:
  /// **'Customer restored'**
  String get customers_customerRestored;

  /// No description provided for @customers_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get customers_date;

  /// No description provided for @customers_editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customers_editCustomer;

  /// No description provided for @customers_editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get customers_editSupplier;

  /// No description provided for @customers_englishVersion.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get customers_englishVersion;

  /// No description provided for @customers_filterAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get customers_filterAdvance;

  /// No description provided for @customers_filterAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid'**
  String get customers_filterAdvancePaid;

  /// No description provided for @customers_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customers_filterAll;

  /// No description provided for @customers_filterPayable.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get customers_filterPayable;

  /// No description provided for @customers_filterReceivable.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get customers_filterReceivable;

  /// No description provided for @customers_giveUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Give udhaar'**
  String get customers_giveUdhaar;

  /// No description provided for @customers_ledgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get customers_ledgerTitle;

  /// No description provided for @customers_makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make payment'**
  String get customers_makePayment;

  /// No description provided for @customers_method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get customers_method;

  /// No description provided for @customers_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customers_name;

  /// No description provided for @customers_newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customers_newCustomer;

  /// No description provided for @customers_newSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get customers_newSupplier;

  /// No description provided for @customers_noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customers_noCustomers;

  /// No description provided for @customers_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries in this period'**
  String get customers_noEntries;

  /// No description provided for @customers_noMatch.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get customers_noMatch;

  /// No description provided for @customers_noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet'**
  String get customers_noSuppliers;

  /// No description provided for @customers_notFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get customers_notFound;

  /// No description provided for @customers_note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get customers_note;

  /// No description provided for @customers_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get customers_notes;

  /// No description provided for @customers_openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get customers_openingBalance;

  /// No description provided for @customers_openingBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Amount in PKR.'**
  String get customers_openingBalanceHint;

  /// No description provided for @customers_openingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get customers_openingBalanceLabel;

  /// No description provided for @customers_openingHelpCustomer.
  ///
  /// In en, this message translates to:
  /// **'Positive: the customer owes you. Negative: you owe the customer.'**
  String get customers_openingHelpCustomer;

  /// No description provided for @customers_openingHelpSupplier.
  ///
  /// In en, this message translates to:
  /// **'Positive: you owe the supplier. Negative: the supplier owes you.'**
  String get customers_openingHelpSupplier;

  /// No description provided for @customers_paymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get customers_paymentSaved;

  /// No description provided for @customers_paymentTitlePay.
  ///
  /// In en, this message translates to:
  /// **'Make payment'**
  String get customers_paymentTitlePay;

  /// No description provided for @customers_paymentTitleReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get customers_paymentTitleReceive;

  /// No description provided for @customers_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customers_phone;

  /// No description provided for @customers_receivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get customers_receivePayment;

  /// No description provided for @customers_recordPurchase.
  ///
  /// In en, this message translates to:
  /// **'Record purchase'**
  String get customers_recordPurchase;

  /// No description provided for @customers_reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get customers_reminder;

  /// No description provided for @customers_reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment reminder'**
  String get customers_reminderTitle;

  /// No description provided for @customers_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get customers_saved;

  /// No description provided for @customers_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone, code'**
  String get customers_searchHint;

  /// No description provided for @customers_searchLedgerHint.
  ///
  /// In en, this message translates to:
  /// **'Search description'**
  String get customers_searchLedgerHint;

  /// No description provided for @customers_selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get customers_selectAccount;

  /// No description provided for @customers_statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get customers_statement;

  /// No description provided for @customers_supplierArchived.
  ///
  /// In en, this message translates to:
  /// **'Supplier archived'**
  String get customers_supplierArchived;

  /// No description provided for @customers_supplierRestored.
  ///
  /// In en, this message translates to:
  /// **'Supplier restored'**
  String get customers_supplierRestored;

  /// No description provided for @customers_supplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get customers_supplierTitle;

  /// No description provided for @customers_title.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers_title;

  /// No description provided for @customers_totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total credit given'**
  String get customers_totalCredit;

  /// No description provided for @customers_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get customers_totalPaid;

  /// No description provided for @customers_totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total purchases'**
  String get customers_totalPurchases;

  /// No description provided for @customers_totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received'**
  String get customers_totalReceived;

  /// No description provided for @customers_unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get customers_unarchive;

  /// No description provided for @customers_urduVersion.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get customers_urduVersion;

  /// No description provided for @customers_viewLedger.
  ///
  /// In en, this message translates to:
  /// **'View ledger'**
  String get customers_viewLedger;

  /// No description provided for @dashboard_activityExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboard_activityExpense;

  /// No description provided for @dashboard_activityIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboard_activityIncome;

  /// No description provided for @dashboard_activityPaymentIn.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get dashboard_activityPaymentIn;

  /// No description provided for @dashboard_activityPaymentOut.
  ///
  /// In en, this message translates to:
  /// **'Payment made'**
  String get dashboard_activityPaymentOut;

  /// No description provided for @dashboard_activityPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase {no}'**
  String dashboard_activityPurchase(String no);

  /// No description provided for @dashboard_activitySale.
  ///
  /// In en, this message translates to:
  /// **'Sale {no}'**
  String dashboard_activitySale(String no);

  /// No description provided for @dashboard_bankBalance.
  ///
  /// In en, this message translates to:
  /// **'Bank balance'**
  String get dashboard_bankBalance;

  /// No description provided for @dashboard_cashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get dashboard_cashInHand;

  /// No description provided for @dashboard_lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock alerts'**
  String get dashboard_lowStock;

  /// No description provided for @dashboard_lowStockOk.
  ///
  /// In en, this message translates to:
  /// **'Stock levels are healthy'**
  String get dashboard_lowStockOk;

  /// No description provided for @dashboard_monthExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses this month'**
  String get dashboard_monthExpense;

  /// No description provided for @dashboard_monthIncome.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get dashboard_monthIncome;

  /// No description provided for @dashboard_noActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashboard_noActivity;

  /// No description provided for @dashboard_noActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Sales, purchases and payments will appear here'**
  String get dashboard_noActivityHint;

  /// No description provided for @dashboard_paidToday.
  ///
  /// In en, this message translates to:
  /// **'Paid today'**
  String get dashboard_paidToday;

  /// No description provided for @dashboard_pickCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose customer'**
  String get dashboard_pickCustomer;

  /// No description provided for @dashboard_pickSupplier.
  ///
  /// In en, this message translates to:
  /// **'Choose supplier'**
  String get dashboard_pickSupplier;

  /// No description provided for @dashboard_qaAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get dashboard_qaAddCustomer;

  /// No description provided for @dashboard_qaAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get dashboard_qaAddExpense;

  /// No description provided for @dashboard_qaAddPurchase.
  ///
  /// In en, this message translates to:
  /// **'Add purchase'**
  String get dashboard_qaAddPurchase;

  /// No description provided for @dashboard_qaAddSale.
  ///
  /// In en, this message translates to:
  /// **'Add sale'**
  String get dashboard_qaAddSale;

  /// No description provided for @dashboard_qaAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get dashboard_qaAddSupplier;

  /// No description provided for @dashboard_qaGiveUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Give udhaar'**
  String get dashboard_qaGiveUdhaar;

  /// No description provided for @dashboard_qaMakePayment.
  ///
  /// In en, this message translates to:
  /// **'Make payment'**
  String get dashboard_qaMakePayment;

  /// No description provided for @dashboard_qaReceivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get dashboard_qaReceivePayment;

  /// No description provided for @dashboard_qaRecordProduction.
  ///
  /// In en, this message translates to:
  /// **'Record production'**
  String get dashboard_qaRecordProduction;

  /// No description provided for @dashboard_qaViewReports.
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get dashboard_qaViewReports;

  /// No description provided for @dashboard_quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboard_quickActions;

  /// No description provided for @dashboard_receivedToday.
  ///
  /// In en, this message translates to:
  /// **'Received today'**
  String get dashboard_receivedToday;

  /// No description provided for @dashboard_recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboard_recentActivity;

  /// No description provided for @dashboard_stockLeft.
  ///
  /// In en, this message translates to:
  /// **'{qty} {unit} left'**
  String dashboard_stockLeft(String qty, String unit);

  /// No description provided for @dashboard_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboard_thisMonth;

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_title;

  /// No description provided for @dashboard_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboard_today;

  /// No description provided for @dashboard_todayPurchases.
  ///
  /// In en, this message translates to:
  /// **'Today\'s purchases'**
  String get dashboard_todayPurchases;

  /// No description provided for @dashboard_todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get dashboard_todaySales;

  /// No description provided for @dashboard_totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get dashboard_totalBalance;

  /// No description provided for @dashboard_totalPayable.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get dashboard_totalPayable;

  /// No description provided for @dashboard_totalReceivable.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get dashboard_totalReceivable;

  /// No description provided for @dashboard_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboard_viewAll;

  /// No description provided for @expenses_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get expenses_account;

  /// No description provided for @expenses_addCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get expenses_addCategory;

  /// No description provided for @expenses_addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenses_addExpense;

  /// No description provided for @expenses_addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get expenses_addIncome;

  /// No description provided for @expenses_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenses_amount;

  /// No description provided for @expenses_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenses_category;

  /// No description provided for @expenses_categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get expenses_categoryName;

  /// No description provided for @expenses_categorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get expenses_categorySaved;

  /// No description provided for @expenses_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenses_date;

  /// No description provided for @expenses_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get expenses_description;

  /// No description provided for @expenses_errAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get expenses_errAccountNotFound;

  /// No description provided for @expenses_errCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get expenses_errCategoryNotFound;

  /// No description provided for @expenses_errInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get expenses_errInvalidAmount;

  /// No description provided for @expenses_expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenses_expenseSaved;

  /// No description provided for @expenses_incomeCategory.
  ///
  /// In en, this message translates to:
  /// **'Income type (optional)'**
  String get expenses_incomeCategory;

  /// No description provided for @expenses_incomeSaved.
  ///
  /// In en, this message translates to:
  /// **'Income saved'**
  String get expenses_incomeSaved;

  /// No description provided for @expenses_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get expenses_noEntries;

  /// No description provided for @expenses_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get expenses_reference;

  /// No description provided for @expenses_tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses_tabExpenses;

  /// No description provided for @expenses_tabIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get expenses_tabIncome;

  /// No description provided for @expenses_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get expenses_thisMonth;

  /// No description provided for @expenses_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get expenses_thisYear;

  /// No description provided for @expenses_title.
  ///
  /// In en, this message translates to:
  /// **'Expenses & income'**
  String get expenses_title;

  /// No description provided for @expenses_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get expenses_today;

  /// No description provided for @expenses_totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get expenses_totalExpenses;

  /// No description provided for @expenses_totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get expenses_totalIncome;

  /// No description provided for @inventory_addConversion.
  ///
  /// In en, this message translates to:
  /// **'Add conversion'**
  String get inventory_addConversion;

  /// No description provided for @inventory_addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get inventory_addProduct;

  /// No description provided for @inventory_adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get inventory_adjust;

  /// No description provided for @inventory_adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventory_adjustment;

  /// No description provided for @inventory_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventory_all;

  /// No description provided for @inventory_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get inventory_available;

  /// No description provided for @inventory_avgCost.
  ///
  /// In en, this message translates to:
  /// **'Average cost'**
  String get inventory_avgCost;

  /// No description provided for @inventory_catConsumable.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get inventory_catConsumable;

  /// No description provided for @inventory_catContainer.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get inventory_catContainer;

  /// No description provided for @inventory_catFinishedOil.
  ///
  /// In en, this message translates to:
  /// **'Finished oil'**
  String get inventory_catFinishedOil;

  /// No description provided for @inventory_catOilCake.
  ///
  /// In en, this message translates to:
  /// **'Oil cake'**
  String get inventory_catOilCake;

  /// No description provided for @inventory_catPackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get inventory_catPackaging;

  /// No description provided for @inventory_catRawMaterial.
  ///
  /// In en, this message translates to:
  /// **'Raw material'**
  String get inventory_catRawMaterial;

  /// No description provided for @inventory_catSpare.
  ///
  /// In en, this message translates to:
  /// **'Spares'**
  String get inventory_catSpare;

  /// No description provided for @inventory_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventory_category;

  /// No description provided for @inventory_conversionExists.
  ///
  /// In en, this message translates to:
  /// **'A conversion for this pair already exists'**
  String get inventory_conversionExists;

  /// No description provided for @inventory_conversionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversions'**
  String get inventory_conversionsTitle;

  /// No description provided for @inventory_editConversion.
  ///
  /// In en, this message translates to:
  /// **'Edit conversion'**
  String get inventory_editConversion;

  /// No description provided for @inventory_editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get inventory_editProduct;

  /// No description provided for @inventory_errDatabase.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get inventory_errDatabase;

  /// No description provided for @inventory_errInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock of {product} (available {available}, needed {needed})'**
  String inventory_errInsufficientStock(
      String available, String needed, String product);

  /// No description provided for @inventory_errInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get inventory_errInvalidAmount;

  /// No description provided for @inventory_errInvalidQty.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity greater than zero'**
  String get inventory_errInvalidQty;

  /// No description provided for @inventory_errNoConversion.
  ///
  /// In en, this message translates to:
  /// **'No conversion defined between these units'**
  String get inventory_errNoConversion;

  /// No description provided for @inventory_errProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get inventory_errProductNotFound;

  /// No description provided for @inventory_factor.
  ///
  /// In en, this message translates to:
  /// **'Factor'**
  String get inventory_factor;

  /// No description provided for @inventory_factorHint.
  ///
  /// In en, this message translates to:
  /// **'How many {to} in 1 {from}?'**
  String inventory_factorHint(String from, String to);

  /// No description provided for @inventory_factorPositive.
  ///
  /// In en, this message translates to:
  /// **'Factor must be greater than zero'**
  String get inventory_factorPositive;

  /// No description provided for @inventory_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get inventory_from;

  /// No description provided for @inventory_in.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inventory_in;

  /// No description provided for @inventory_lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventory_lowStock;

  /// No description provided for @inventory_movements.
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get inventory_movements;

  /// No description provided for @inventory_name.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get inventory_name;

  /// No description provided for @inventory_noConversions.
  ///
  /// In en, this message translates to:
  /// **'No conversions defined yet'**
  String get inventory_noConversions;

  /// No description provided for @inventory_noMovements.
  ///
  /// In en, this message translates to:
  /// **'No movements recorded yet'**
  String get inventory_noMovements;

  /// No description provided for @inventory_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get inventory_noProducts;

  /// No description provided for @inventory_noProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start tracking stock.'**
  String get inventory_noProductsHint;

  /// No description provided for @inventory_openingStock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get inventory_openingStock;

  /// No description provided for @inventory_openingStockReason.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get inventory_openingStockReason;

  /// No description provided for @inventory_out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get inventory_out;

  /// No description provided for @inventory_productSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved'**
  String get inventory_productSaved;

  /// No description provided for @inventory_qty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventory_qty;

  /// No description provided for @inventory_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get inventory_reason;

  /// No description provided for @inventory_reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get inventory_reasonRequired;

  /// No description provided for @inventory_reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder level'**
  String get inventory_reorderLevel;

  /// No description provided for @inventory_salePrice.
  ///
  /// In en, this message translates to:
  /// **'Default sale price (optional)'**
  String get inventory_salePrice;

  /// No description provided for @inventory_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get inventory_searchHint;

  /// No description provided for @inventory_sku.
  ///
  /// In en, this message translates to:
  /// **'SKU (optional)'**
  String get inventory_sku;

  /// No description provided for @inventory_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get inventory_stock;

  /// No description provided for @inventory_stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get inventory_stockIn;

  /// No description provided for @inventory_stockInReason.
  ///
  /// In en, this message translates to:
  /// **'Stock receipt'**
  String get inventory_stockInReason;

  /// No description provided for @inventory_stockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock out'**
  String get inventory_stockOut;

  /// No description provided for @inventory_stockOutReason.
  ///
  /// In en, this message translates to:
  /// **'Stock dispatch'**
  String get inventory_stockOutReason;

  /// No description provided for @inventory_stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get inventory_stockUpdated;

  /// No description provided for @inventory_stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get inventory_stockValue;

  /// No description provided for @inventory_title.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory_title;

  /// No description provided for @inventory_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get inventory_to;

  /// No description provided for @inventory_typeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventory_typeAdjustment;

  /// No description provided for @inventory_typeProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get inventory_typeProduction;

  /// No description provided for @inventory_typePurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get inventory_typePurchase;

  /// No description provided for @inventory_typeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get inventory_typeReturn;

  /// No description provided for @inventory_typeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get inventory_typeSale;

  /// No description provided for @inventory_unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventory_unit;

  /// No description provided for @inventory_units.
  ///
  /// In en, this message translates to:
  /// **'Units & conversions'**
  String get inventory_units;

  /// No description provided for @inventory_unitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get inventory_unitsTitle;

  /// No description provided for @khata_customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get khata_customers;

  /// No description provided for @khata_errorAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'This account is inactive.'**
  String get khata_errorAccountInactive;

  /// No description provided for @khata_errorAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found.'**
  String get khata_errorAccountNotFound;

  /// No description provided for @khata_errorAlreadyReversed.
  ///
  /// In en, this message translates to:
  /// **'This entry has already been reversed.'**
  String get khata_errorAlreadyReversed;

  /// No description provided for @khata_errorCategoryInactive.
  ///
  /// In en, this message translates to:
  /// **'This category is inactive.'**
  String get khata_errorCategoryInactive;

  /// No description provided for @khata_errorCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found.'**
  String get khata_errorCategoryNotFound;

  /// No description provided for @khata_errorCustomerArchived.
  ///
  /// In en, this message translates to:
  /// **'This customer is archived.'**
  String get khata_errorCustomerArchived;

  /// No description provided for @khata_errorCustomerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found.'**
  String get khata_errorCustomerNotFound;

  /// No description provided for @khata_errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database error. Please try again.'**
  String get khata_errorDatabase;

  /// No description provided for @khata_errorEmptyBatchInputs.
  ///
  /// In en, this message translates to:
  /// **'A batch needs at least one input.'**
  String get khata_errorEmptyBatchInputs;

  /// No description provided for @khata_errorEmptyBatchOutputs.
  ///
  /// In en, this message translates to:
  /// **'A batch needs at least one output.'**
  String get khata_errorEmptyBatchOutputs;

  /// No description provided for @khata_errorEmptyInvoice.
  ///
  /// In en, this message translates to:
  /// **'The invoice has no items.'**
  String get khata_errorEmptyInvoice;

  /// No description provided for @khata_errorEmptyJournal.
  ///
  /// In en, this message translates to:
  /// **'The journal has no entries.'**
  String get khata_errorEmptyJournal;

  /// No description provided for @khata_errorEmptyReturn.
  ///
  /// In en, this message translates to:
  /// **'The return has no items.'**
  String get khata_errorEmptyReturn;

  /// No description provided for @khata_errorEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ledger entry not found.'**
  String get khata_errorEntryNotFound;

  /// No description provided for @khata_errorInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock of {product}.'**
  String khata_errorInsufficientStock(String product);

  /// No description provided for @khata_errorInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get khata_errorInvalidAmount;

  /// No description provided for @khata_errorInvalidJournalLine.
  ///
  /// In en, this message translates to:
  /// **'Invalid journal entry.'**
  String get khata_errorInvalidJournalLine;

  /// No description provided for @khata_errorInvalidQty.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity.'**
  String get khata_errorInvalidQty;

  /// No description provided for @khata_errorInvoiceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found.'**
  String get khata_errorInvoiceNotFound;

  /// No description provided for @khata_errorMethodAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'The payment method does not match the account.'**
  String get khata_errorMethodAccountMismatch;

  /// No description provided for @khata_errorNegativeCost.
  ///
  /// In en, this message translates to:
  /// **'Cost cannot be negative.'**
  String get khata_errorNegativeCost;

  /// No description provided for @khata_errorNegativePrice.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative.'**
  String get khata_errorNegativePrice;

  /// No description provided for @khata_errorNegativeTax.
  ///
  /// In en, this message translates to:
  /// **'Tax cannot be negative.'**
  String get khata_errorNegativeTax;

  /// No description provided for @khata_errorNegativeTotal.
  ///
  /// In en, this message translates to:
  /// **'The total cannot be negative.'**
  String get khata_errorNegativeTotal;

  /// No description provided for @khata_errorNoConversion.
  ///
  /// In en, this message translates to:
  /// **'Unit conversion is not available.'**
  String get khata_errorNoConversion;

  /// No description provided for @khata_errorNotADraft.
  ///
  /// In en, this message translates to:
  /// **'Only drafts can be changed like this.'**
  String get khata_errorNotADraft;

  /// No description provided for @khata_errorOilCostAllocation.
  ///
  /// In en, this message translates to:
  /// **'Could not allocate the oil cost.'**
  String get khata_errorOilCostAllocation;

  /// No description provided for @khata_errorOverAllocated.
  ///
  /// In en, this message translates to:
  /// **'The payment is more than the outstanding amount.'**
  String get khata_errorOverAllocated;

  /// No description provided for @khata_errorOverAllocatedInvoice.
  ///
  /// In en, this message translates to:
  /// **'The payment is more than the invoice balance.'**
  String get khata_errorOverAllocatedInvoice;

  /// No description provided for @khata_errorProductArchived.
  ///
  /// In en, this message translates to:
  /// **'This product is archived.'**
  String get khata_errorProductArchived;

  /// No description provided for @khata_errorProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get khata_errorProductNotFound;

  /// No description provided for @khata_errorReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get khata_errorReasonRequired;

  /// No description provided for @khata_errorReturnExceedsBought.
  ///
  /// In en, this message translates to:
  /// **'The return is more than what was bought.'**
  String get khata_errorReturnExceedsBought;

  /// No description provided for @khata_errorReturnExceedsSold.
  ///
  /// In en, this message translates to:
  /// **'The return is more than what was sold.'**
  String get khata_errorReturnExceedsSold;

  /// No description provided for @khata_errorSupplierArchived.
  ///
  /// In en, this message translates to:
  /// **'This supplier is archived.'**
  String get khata_errorSupplierArchived;

  /// No description provided for @khata_errorSupplierNotFound.
  ///
  /// In en, this message translates to:
  /// **'Supplier not found.'**
  String get khata_errorSupplierNotFound;

  /// No description provided for @khata_errorTransferSameAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot transfer to the same account.'**
  String get khata_errorTransferSameAccount;

  /// No description provided for @khata_errorUnbalancedJournal.
  ///
  /// In en, this message translates to:
  /// **'The journal is not balanced.'**
  String get khata_errorUnbalancedJournal;

  /// No description provided for @khata_errorUnitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Unit not found.'**
  String get khata_errorUnitNotFound;

  /// No description provided for @khata_noDues.
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get khata_noDues;

  /// No description provided for @khata_noDuesHint.
  ///
  /// In en, this message translates to:
  /// **'No outstanding balances'**
  String get khata_noDuesHint;

  /// No description provided for @khata_suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get khata_suppliers;

  /// No description provided for @khata_title.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get khata_title;

  /// No description provided for @khata_toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get khata_toPay;

  /// No description provided for @khata_toReceive.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get khata_toReceive;

  /// No description provided for @khata_viewAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'View customers'**
  String get khata_viewAllCustomers;

  /// No description provided for @khata_viewAllSuppliers.
  ///
  /// In en, this message translates to:
  /// **'View suppliers'**
  String get khata_viewAllSuppliers;

  /// No description provided for @production_addInput.
  ///
  /// In en, this message translates to:
  /// **'Add input'**
  String get production_addInput;

  /// No description provided for @production_addOutput.
  ///
  /// In en, this message translates to:
  /// **'Add output'**
  String get production_addOutput;

  /// No description provided for @production_available.
  ///
  /// In en, this message translates to:
  /// **'Available: {qty} {unit}'**
  String production_available(String qty, String unit);

  /// No description provided for @production_batchAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated when the batch is posted'**
  String get production_batchAuto;

  /// No description provided for @production_batchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch no.'**
  String get production_batchNo;

  /// No description provided for @production_costBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost breakdown'**
  String get production_costBreakdown;

  /// No description provided for @production_costsCashHint.
  ///
  /// In en, this message translates to:
  /// **'When selected, labour, electricity and other costs are posted as expenses from this account.'**
  String get production_costsCashHint;

  /// No description provided for @production_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get production_date;

  /// No description provided for @production_electricityCost.
  ///
  /// In en, this message translates to:
  /// **'Electricity cost'**
  String get production_electricityCost;

  /// No description provided for @production_emptyInputs.
  ///
  /// In en, this message translates to:
  /// **'Add at least one input'**
  String get production_emptyInputs;

  /// No description provided for @production_emptyOutputs.
  ///
  /// In en, this message translates to:
  /// **'Add at least one output'**
  String get production_emptyOutputs;

  /// No description provided for @production_errNegativeCost.
  ///
  /// In en, this message translates to:
  /// **'Costs cannot be negative'**
  String get production_errNegativeCost;

  /// No description provided for @production_expectedYield.
  ///
  /// In en, this message translates to:
  /// **'Expected yield % (optional)'**
  String get production_expectedYield;

  /// No description provided for @production_inputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs (raw material)'**
  String get production_inputs;

  /// No description provided for @production_inputsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} inputs'**
  String production_inputsCount(String count);

  /// No description provided for @production_labourCost.
  ///
  /// In en, this message translates to:
  /// **'Labour cost'**
  String get production_labourCost;

  /// No description provided for @production_materialCost.
  ///
  /// In en, this message translates to:
  /// **'Material cost'**
  String get production_materialCost;

  /// No description provided for @production_newBatch.
  ///
  /// In en, this message translates to:
  /// **'New batch'**
  String get production_newBatch;

  /// No description provided for @production_noBatches.
  ///
  /// In en, this message translates to:
  /// **'No batches yet'**
  String get production_noBatches;

  /// No description provided for @production_noBatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Start your first production batch.'**
  String get production_noBatchesHint;

  /// No description provided for @production_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get production_notes;

  /// No description provided for @production_otherCost.
  ///
  /// In en, this message translates to:
  /// **'Other cost'**
  String get production_otherCost;

  /// No description provided for @production_outOfStock.
  ///
  /// In en, this message translates to:
  /// **'No raw-material products yet'**
  String get production_outOfStock;

  /// No description provided for @production_outputType.
  ///
  /// In en, this message translates to:
  /// **'Output type'**
  String get production_outputType;

  /// No description provided for @production_outputs.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get production_outputs;

  /// No description provided for @production_payCostsFrom.
  ///
  /// In en, this message translates to:
  /// **'Pay costs from'**
  String get production_payCostsFrom;

  /// No description provided for @production_payCostsNone.
  ///
  /// In en, this message translates to:
  /// **'None (record separately)'**
  String get production_payCostsNone;

  /// No description provided for @production_postBatch.
  ///
  /// In en, this message translates to:
  /// **'Post batch'**
  String get production_postBatch;

  /// No description provided for @production_qtyGtZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero'**
  String get production_qtyGtZero;

  /// No description provided for @production_rawOnly.
  ///
  /// In en, this message translates to:
  /// **'Only raw-material products can be inputs'**
  String get production_rawOnly;

  /// No description provided for @production_removeLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get production_removeLine;

  /// No description provided for @production_resultNoYield.
  ///
  /// In en, this message translates to:
  /// **'Yield could not be computed — add a kg conversion for the units used.'**
  String get production_resultNoYield;

  /// No description provided for @production_resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch posted'**
  String get production_resultTitle;

  /// No description provided for @production_resultYield.
  ///
  /// In en, this message translates to:
  /// **'Yield: {pct}%'**
  String production_resultYield(String pct);

  /// No description provided for @production_selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get production_selectProduct;

  /// No description provided for @production_statusCostsPosted.
  ///
  /// In en, this message translates to:
  /// **'Costs in cashbook'**
  String get production_statusCostsPosted;

  /// No description provided for @production_statusPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get production_statusPosted;

  /// No description provided for @production_title.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production_title;

  /// No description provided for @production_totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get production_totalCost;

  /// No description provided for @production_typeByProduct.
  ///
  /// In en, this message translates to:
  /// **'By-product'**
  String get production_typeByProduct;

  /// No description provided for @production_typeFinishedOil.
  ///
  /// In en, this message translates to:
  /// **'Finished oil'**
  String get production_typeFinishedOil;

  /// No description provided for @production_typeOilCake.
  ///
  /// In en, this message translates to:
  /// **'Oil cake'**
  String get production_typeOilCake;

  /// No description provided for @production_wastage.
  ///
  /// In en, this message translates to:
  /// **'Wastage / loss'**
  String get production_wastage;

  /// No description provided for @production_yield.
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get production_yield;

  /// No description provided for @purchases_confirmPost.
  ///
  /// In en, this message translates to:
  /// **'Post this purchase? Stock will increase.'**
  String get purchases_confirmPost;

  /// No description provided for @purchases_deleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get purchases_deleteDraft;

  /// No description provided for @purchases_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase detail'**
  String get purchases_detailTitle;

  /// No description provided for @purchases_draftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted'**
  String get purchases_draftDeleted;

  /// No description provided for @purchases_draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft {invoiceNo} saved'**
  String purchases_draftSaved(String invoiceNo);

  /// No description provided for @purchases_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get purchases_emptyTitle;

  /// No description provided for @purchases_formTitle.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get purchases_formTitle;

  /// No description provided for @purchases_lineItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get purchases_lineItems;

  /// No description provided for @purchases_newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get purchases_newPurchase;

  /// No description provided for @purchases_noItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get purchases_noItems;

  /// No description provided for @purchases_noSupplierSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a supplier first'**
  String get purchases_noSupplierSelected;

  /// No description provided for @purchases_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get purchases_payments;

  /// No description provided for @purchases_postDraft.
  ///
  /// In en, this message translates to:
  /// **'Post draft'**
  String get purchases_postDraft;

  /// No description provided for @purchases_postPurchase.
  ///
  /// In en, this message translates to:
  /// **'Post purchase'**
  String get purchases_postPurchase;

  /// No description provided for @purchases_purchasePosted.
  ///
  /// In en, this message translates to:
  /// **'Purchase {invoiceNo} posted'**
  String purchases_purchasePosted(String invoiceNo);

  /// No description provided for @purchases_recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get purchases_recordPayment;

  /// No description provided for @purchases_returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase return'**
  String get purchases_returnTitle;

  /// No description provided for @purchases_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search voucher no. or supplier…'**
  String get purchases_searchHint;

  /// No description provided for @purchases_searchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers…'**
  String get purchases_searchSupplier;

  /// No description provided for @purchases_selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select supplier'**
  String get purchases_selectSupplier;

  /// No description provided for @purchases_statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get purchases_statusCancelled;

  /// No description provided for @purchases_statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get purchases_statusDraft;

  /// No description provided for @purchases_statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get purchases_statusPaid;

  /// No description provided for @purchases_statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get purchases_statusPartial;

  /// No description provided for @purchases_statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get purchases_statusReturned;

  /// No description provided for @purchases_statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get purchases_statusUnpaid;

  /// No description provided for @purchases_supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get purchases_supplier;

  /// No description provided for @purchases_title.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases_title;

  /// No description provided for @purchases_voucherPdf.
  ///
  /// In en, this message translates to:
  /// **'Purchase voucher PDF'**
  String get purchases_voucherPdf;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports_title;

  /// No description provided for @reports_dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get reports_dailySummary;

  /// No description provided for @reports_monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get reports_monthlySummary;

  /// No description provided for @reports_customerLedger.
  ///
  /// In en, this message translates to:
  /// **'Customer Ledger'**
  String get reports_customerLedger;

  /// No description provided for @reports_supplierLedger.
  ///
  /// In en, this message translates to:
  /// **'Supplier Ledger'**
  String get reports_supplierLedger;

  /// No description provided for @reports_receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get reports_receivables;

  /// No description provided for @reports_payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get reports_payables;

  /// No description provided for @reports_sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reports_sales;

  /// No description provided for @reports_purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get reports_purchase;

  /// No description provided for @reports_paymentsReceived.
  ///
  /// In en, this message translates to:
  /// **'Payments Received'**
  String get reports_paymentsReceived;

  /// No description provided for @reports_paymentsMade.
  ///
  /// In en, this message translates to:
  /// **'Payments Made'**
  String get reports_paymentsMade;

  /// No description provided for @reports_expense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reports_expense;

  /// No description provided for @reports_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reports_income;

  /// No description provided for @reports_cashbook.
  ///
  /// In en, this message translates to:
  /// **'Cashbook'**
  String get reports_cashbook;

  /// No description provided for @reports_cashBankBalances.
  ///
  /// In en, this message translates to:
  /// **'Cash & Bank Balances'**
  String get reports_cashBankBalances;

  /// No description provided for @reports_inventoryValuation.
  ///
  /// In en, this message translates to:
  /// **'Inventory Valuation'**
  String get reports_inventoryValuation;

  /// No description provided for @reports_stockMovement.
  ///
  /// In en, this message translates to:
  /// **'Stock Movement'**
  String get reports_stockMovement;

  /// No description provided for @reports_lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get reports_lowStock;

  /// No description provided for @reports_production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get reports_production;

  /// No description provided for @reports_yield.
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get reports_yield;

  /// No description provided for @reports_salesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get reports_salesReturns;

  /// No description provided for @reports_purchaseReturns.
  ///
  /// In en, this message translates to:
  /// **'Purchase Returns'**
  String get reports_purchaseReturns;

  /// No description provided for @reports_outstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Invoices'**
  String get reports_outstandingInvoices;

  /// No description provided for @reports_profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get reports_profitLoss;

  /// No description provided for @reports_trialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get reports_trialBalance;

  /// No description provided for @reports_daybook.
  ///
  /// In en, this message translates to:
  /// **'Daybook'**
  String get reports_daybook;

  /// No description provided for @reports_selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get reports_selectCustomer;

  /// No description provided for @reports_selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select supplier'**
  String get reports_selectSupplier;

  /// No description provided for @reports_selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get reports_selectProduct;

  /// No description provided for @reports_selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get reports_selectAccount;

  /// No description provided for @reports_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get reports_change;

  /// No description provided for @reports_customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get reports_customRange;

  /// No description provided for @reports_pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get reports_pickDate;

  /// No description provided for @reports_pickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick month'**
  String get reports_pickMonth;

  /// No description provided for @reports_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reports_all;

  /// No description provided for @reports_totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get reports_totalSales;

  /// No description provided for @reports_totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total purchases'**
  String get reports_totalPurchases;

  /// No description provided for @reports_totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received'**
  String get reports_totalReceived;

  /// No description provided for @reports_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get reports_totalPaid;

  /// No description provided for @reports_totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get reports_totalExpenses;

  /// No description provided for @reports_totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get reports_totalIncome;

  /// No description provided for @reports_netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get reports_netProfit;

  /// No description provided for @reports_netLoss.
  ///
  /// In en, this message translates to:
  /// **'Net loss'**
  String get reports_netLoss;

  /// No description provided for @reports_estimatedNote.
  ///
  /// In en, this message translates to:
  /// **'Estimated — cost data is incomplete for this period.'**
  String get reports_estimatedNote;

  /// No description provided for @reports_openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get reports_openingBalance;

  /// No description provided for @reports_closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get reports_closingBalance;

  /// No description provided for @reports_recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String reports_recordsCount(String count);

  /// No description provided for @reports_due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get reports_due;

  /// No description provided for @reports_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get reports_paid;

  /// No description provided for @reports_unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get reports_unpaid;

  /// No description provided for @reports_partial.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get reports_partial;

  /// No description provided for @reports_invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get reports_invoices;

  /// No description provided for @reports_stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get reports_stockValue;

  /// No description provided for @reports_avgYield.
  ///
  /// In en, this message translates to:
  /// **'Average yield'**
  String get reports_avgYield;

  /// No description provided for @reports_batches.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get reports_batches;

  /// No description provided for @reports_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get reports_quantity;

  /// No description provided for @reports_avgCost.
  ///
  /// In en, this message translates to:
  /// **'Avg. cost'**
  String get reports_avgCost;

  /// No description provided for @reports_reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder level'**
  String get reports_reorderLevel;

  /// No description provided for @reports_onHand.
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get reports_onHand;

  /// No description provided for @reports_copyReminder.
  ///
  /// In en, this message translates to:
  /// **'Copy reminder'**
  String get reports_copyReminder;

  /// No description provided for @reports_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get reports_copied;

  /// No description provided for @reports_noData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get reports_noData;

  /// No description provided for @reports_saleInvoices.
  ///
  /// In en, this message translates to:
  /// **'Sale invoices'**
  String get reports_saleInvoices;

  /// No description provided for @reports_purchaseInvoices.
  ///
  /// In en, this message translates to:
  /// **'Purchase invoices'**
  String get reports_purchaseInvoices;

  /// No description provided for @reports_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get reports_value;

  /// No description provided for @reports_expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get reports_expensesByCategory;

  /// No description provided for @reports_customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get reports_customers;

  /// No description provided for @reports_suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get reports_suppliers;

  /// No description provided for @reports_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get reports_accounts;

  /// No description provided for @reports_grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get reports_grandTotal;

  /// No description provided for @reports_doc_saleInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoice'**
  String get reports_doc_saleInvoice;

  /// No description provided for @reports_doc_purchaseVoucher.
  ///
  /// In en, this message translates to:
  /// **'Purchase Voucher'**
  String get reports_doc_purchaseVoucher;

  /// No description provided for @reports_doc_paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get reports_doc_paymentReceipt;

  /// No description provided for @reports_doc_supplierPaymentVoucher.
  ///
  /// In en, this message translates to:
  /// **'Supplier Payment Voucher'**
  String get reports_doc_supplierPaymentVoucher;

  /// No description provided for @reports_doc_customerStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer Statement'**
  String get reports_doc_customerStatement;

  /// No description provided for @reports_doc_supplierStatement.
  ///
  /// In en, this message translates to:
  /// **'Supplier Statement'**
  String get reports_doc_supplierStatement;

  /// No description provided for @reports_doc_cashReceipt.
  ///
  /// In en, this message translates to:
  /// **'Cash Receipt'**
  String get reports_doc_cashReceipt;

  /// No description provided for @reports_doc_expenseVoucher.
  ///
  /// In en, this message translates to:
  /// **'Expense Voucher'**
  String get reports_doc_expenseVoucher;

  /// No description provided for @reports_doc_productionReport.
  ///
  /// In en, this message translates to:
  /// **'Production Report'**
  String get reports_doc_productionReport;

  /// No description provided for @reports_doc_savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get reports_doc_savePdf;

  /// No description provided for @reports_doc_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get reports_doc_share;

  /// No description provided for @reports_doc_print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get reports_doc_print;

  /// No description provided for @reports_doc_pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved.'**
  String get reports_doc_pdfSaved;

  /// No description provided for @reports_doc_billTo.
  ///
  /// In en, this message translates to:
  /// **'Bill to'**
  String get reports_doc_billTo;

  /// No description provided for @reports_doc_supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get reports_doc_supplier;

  /// No description provided for @reports_doc_customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get reports_doc_customer;

  /// No description provided for @reports_doc_invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice no.'**
  String get reports_doc_invoiceNo;

  /// No description provided for @reports_doc_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reports_doc_date;

  /// No description provided for @reports_doc_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reports_doc_status;

  /// No description provided for @reports_doc_items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get reports_doc_items;

  /// No description provided for @reports_doc_item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get reports_doc_item;

  /// No description provided for @reports_doc_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get reports_doc_qty;

  /// No description provided for @reports_doc_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get reports_doc_price;

  /// No description provided for @reports_doc_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reports_doc_amount;

  /// No description provided for @reports_doc_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get reports_doc_subtotal;

  /// No description provided for @reports_doc_discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get reports_doc_discount;

  /// No description provided for @reports_doc_tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get reports_doc_tax;

  /// No description provided for @reports_doc_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reports_doc_total;

  /// No description provided for @reports_doc_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get reports_doc_paid;

  /// No description provided for @reports_doc_due.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get reports_doc_due;

  /// No description provided for @reports_doc_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get reports_doc_notes;

  /// No description provided for @reports_doc_receivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get reports_doc_receivedFrom;

  /// No description provided for @reports_doc_paidTo.
  ///
  /// In en, this message translates to:
  /// **'Paid to'**
  String get reports_doc_paidTo;

  /// No description provided for @reports_doc_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get reports_doc_account;

  /// No description provided for @reports_doc_method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get reports_doc_method;

  /// No description provided for @reports_doc_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reports_doc_reference;

  /// No description provided for @reports_doc_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reports_doc_category;

  /// No description provided for @reports_doc_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reports_doc_description;

  /// No description provided for @reports_doc_openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get reports_doc_openingBalance;

  /// No description provided for @reports_doc_closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get reports_doc_closingBalance;

  /// No description provided for @reports_doc_debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get reports_doc_debit;

  /// No description provided for @reports_doc_credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get reports_doc_credit;

  /// No description provided for @reports_doc_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get reports_doc_balance;

  /// No description provided for @reports_doc_inputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs (raw material)'**
  String get reports_doc_inputs;

  /// No description provided for @reports_doc_outputs.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get reports_doc_outputs;

  /// No description provided for @reports_doc_yield.
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get reports_doc_yield;

  /// No description provided for @reports_doc_batchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch no.'**
  String get reports_doc_batchNo;

  /// No description provided for @reports_doc_generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String reports_doc_generatedOn(String date);

  /// No description provided for @reports_doc_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get reports_doc_cash;

  /// No description provided for @reports_doc_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get reports_doc_bank;

  /// No description provided for @reports_doc_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reports_doc_from;

  /// No description provided for @reports_doc_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reports_doc_to;

  /// No description provided for @reports_doc_period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reports_doc_period;

  /// No description provided for @reports_doc_oilCake.
  ///
  /// In en, this message translates to:
  /// **'Oil cake'**
  String get reports_doc_oilCake;

  /// No description provided for @reports_doc_byProduct.
  ///
  /// In en, this message translates to:
  /// **'By-product'**
  String get reports_doc_byProduct;

  /// No description provided for @reports_doc_labour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get reports_doc_labour;

  /// No description provided for @reports_doc_electricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get reports_doc_electricity;

  /// No description provided for @reports_doc_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reports_doc_other;

  /// No description provided for @sales_confirmPost.
  ///
  /// In en, this message translates to:
  /// **'Post this sale? Stock will be reduced.'**
  String get sales_confirmPost;

  /// No description provided for @sales_customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get sales_customer;

  /// No description provided for @sales_deleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get sales_deleteDraft;

  /// No description provided for @sales_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale detail'**
  String get sales_detailTitle;

  /// No description provided for @sales_draftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted'**
  String get sales_draftDeleted;

  /// No description provided for @sales_draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft {invoiceNo} saved'**
  String sales_draftSaved(String invoiceNo);

  /// No description provided for @sales_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get sales_emptyTitle;

  /// No description provided for @sales_formTitle.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get sales_formTitle;

  /// No description provided for @sales_invoicePdf.
  ///
  /// In en, this message translates to:
  /// **'Invoice PDF'**
  String get sales_invoicePdf;

  /// No description provided for @sales_lineItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get sales_lineItems;

  /// No description provided for @sales_newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get sales_newSale;

  /// No description provided for @sales_noCustomerSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a customer first'**
  String get sales_noCustomerSelected;

  /// No description provided for @sales_noItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get sales_noItems;

  /// No description provided for @sales_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get sales_payments;

  /// No description provided for @sales_postDraft.
  ///
  /// In en, this message translates to:
  /// **'Post draft'**
  String get sales_postDraft;

  /// No description provided for @sales_postSale.
  ///
  /// In en, this message translates to:
  /// **'Post sale'**
  String get sales_postSale;

  /// No description provided for @sales_recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get sales_recordPayment;

  /// No description provided for @sales_returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales return'**
  String get sales_returnTitle;

  /// No description provided for @sales_salePosted.
  ///
  /// In en, this message translates to:
  /// **'Sale {invoiceNo} posted'**
  String sales_salePosted(String invoiceNo);

  /// No description provided for @sales_searchCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search customers…'**
  String get sales_searchCustomer;

  /// No description provided for @sales_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search invoice no. or customer…'**
  String get sales_searchHint;

  /// No description provided for @sales_selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get sales_selectCustomer;

  /// No description provided for @sales_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sales_share;

  /// No description provided for @sales_statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get sales_statusCancelled;

  /// No description provided for @sales_statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get sales_statusDraft;

  /// No description provided for @sales_statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get sales_statusPaid;

  /// No description provided for @sales_statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get sales_statusPartial;

  /// No description provided for @sales_statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get sales_statusReturned;

  /// No description provided for @sales_statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get sales_statusUnpaid;

  /// No description provided for @sales_title.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales_title;

  /// No description provided for @transactions_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactions_account;

  /// No description provided for @transactions_addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get transactions_addItem;

  /// No description provided for @transactions_adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get transactions_adjustment;

  /// No description provided for @transactions_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get transactions_bank;

  /// No description provided for @transactions_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get transactions_cash;

  /// No description provided for @transactions_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactions_category;

  /// No description provided for @transactions_credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get transactions_credit;

  /// No description provided for @transactions_customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get transactions_customRange;

  /// No description provided for @transactions_customRangeHint.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String transactions_customRangeHint(String from, String to);

  /// No description provided for @transactions_customRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get transactions_customRangeTitle;

  /// No description provided for @transactions_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactions_date;

  /// No description provided for @transactions_debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get transactions_debit;

  /// No description provided for @transactions_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transactions_description;

  /// No description provided for @transactions_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction detail'**
  String get transactions_detailTitle;

  /// No description provided for @transactions_discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get transactions_discount;

  /// No description provided for @transactions_discountPct.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get transactions_discountPct;

  /// No description provided for @transactions_due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get transactions_due;

  /// No description provided for @transactions_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get transactions_emptyTitle;

  /// No description provided for @transactions_entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String transactions_entriesCount(int count);

  /// No description provided for @transactions_entryNo.
  ///
  /// In en, this message translates to:
  /// **'Entry no.'**
  String get transactions_entryNo;

  /// No description provided for @transactions_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactions_expense;

  /// No description provided for @transactions_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactions_filterAll;

  /// No description provided for @transactions_filterPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment paid'**
  String get transactions_filterPaymentPaid;

  /// No description provided for @transactions_filterPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get transactions_filterPaymentReceived;

  /// No description provided for @transactions_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactions_income;

  /// No description provided for @transactions_invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get transactions_invalidPrice;

  /// No description provided for @transactions_invalidQty.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get transactions_invalidQty;

  /// No description provided for @transactions_invoiceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Invoice discount %'**
  String get transactions_invoiceDiscount;

  /// No description provided for @transactions_lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get transactions_lineTotal;

  /// No description provided for @transactions_maxQty.
  ///
  /// In en, this message translates to:
  /// **'Max {qty}'**
  String transactions_maxQty(String qty);

  /// No description provided for @transactions_noDescription.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get transactions_noDescription;

  /// No description provided for @transactions_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get transactions_notes;

  /// No description provided for @transactions_paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid now'**
  String get transactions_paidAmount;

  /// No description provided for @transactions_paymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactions_paymentAccount;

  /// No description provided for @transactions_paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactions_paymentAmount;

  /// No description provided for @transactions_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get transactions_paymentMethod;

  /// No description provided for @transactions_paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get transactions_paymentReference;

  /// No description provided for @transactions_paymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get transactions_paymentSaved;

  /// No description provided for @transactions_paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get transactions_paymentTitle;

  /// No description provided for @transactions_production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get transactions_production;

  /// No description provided for @transactions_purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get transactions_purchase;

  /// No description provided for @transactions_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get transactions_qty;

  /// No description provided for @transactions_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get transactions_reference;

  /// No description provided for @transactions_removeLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get transactions_removeLine;

  /// No description provided for @transactions_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get transactions_return;

  /// No description provided for @transactions_returnPosted.
  ///
  /// In en, this message translates to:
  /// **'Return posted'**
  String get transactions_returnPosted;

  /// No description provided for @transactions_returnReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get transactions_returnReason;

  /// No description provided for @transactions_returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get transactions_returnTitle;

  /// No description provided for @transactions_reversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get transactions_reversal;

  /// No description provided for @transactions_reversalOf.
  ///
  /// In en, this message translates to:
  /// **'Reversal of {entryNo}'**
  String transactions_reversalOf(String entryNo);

  /// No description provided for @transactions_reversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get transactions_reversed;

  /// No description provided for @transactions_sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get transactions_sale;

  /// No description provided for @transactions_saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get transactions_saveDraft;

  /// No description provided for @transactions_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description, entry no…'**
  String get transactions_searchHint;

  /// No description provided for @transactions_searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get transactions_searchProduct;

  /// No description provided for @transactions_selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get transactions_selectProduct;

  /// No description provided for @transactions_sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get transactions_sortNewest;

  /// No description provided for @transactions_sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get transactions_sortOldest;

  /// No description provided for @transactions_submitPayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get transactions_submitPayment;

  /// No description provided for @transactions_submitReturn.
  ///
  /// In en, this message translates to:
  /// **'Post return'**
  String get transactions_submitReturn;

  /// No description provided for @transactions_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get transactions_subtotal;

  /// No description provided for @transactions_tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get transactions_tax;

  /// No description provided for @transactions_taxPct.
  ///
  /// In en, this message translates to:
  /// **'Tax %'**
  String get transactions_taxPct;

  /// No description provided for @transactions_title.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions_title;

  /// No description provided for @transactions_total.
  ///
  /// In en, this message translates to:
  /// **'Journal total'**
  String get transactions_total;

  /// No description provided for @transactions_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactions_transfer;

  /// No description provided for @transactions_unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get transactions_unit;

  /// No description provided for @transactions_unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get transactions_unitPrice;

  /// No description provided for @udhaar_saved.
  ///
  /// In en, this message translates to:
  /// **'Udhaar recorded'**
  String get udhaar_saved;

  /// No description provided for @udhaar_title.
  ///
  /// In en, this message translates to:
  /// **'Give udhaar'**
  String get udhaar_title;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
