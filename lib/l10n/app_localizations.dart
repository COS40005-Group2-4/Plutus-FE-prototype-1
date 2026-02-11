import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Plutus',
      'settings': 'Settings',
      'account_settings': 'Account Settings',
      'appearance': 'Appearance',
      'preferences': 'Preferences',
      
      // Theme
      'theme_mode': 'Theme Mode',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'System Default',
      
      // Language
      'language': 'Language',
      'language_english': 'English',
      'language_vietnamese': 'Tiếng Việt',
      
      // Currency
      'currency': 'Currency',
      'currency_vnd': 'Vietnamese Dong (₫)',
      'currency_usd': 'US Dollar (\$)',
      'currency_eur': 'Euro (€)',
      
      // Date & Time
      'date_format': 'Date Format',
      'time_format': 'Time Format',
      'time_24h': '24-hour',
      'time_12h': '12-hour (AM/PM)',
      
      // Account
      'link_google': 'Link Google Account',
      'unlink_google': 'Unlink Google Account',
      'switch_user': 'Switch User',
      'sign_out': 'Sign Out',
      'sign_in': 'Sign In with Google',
      
      // Dialog
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      
      // Messages
      'guest_mode': 'Guest Mode',
      'local_account': 'Local Account',
      'google_linked': 'Google Linked',
      
      // Navigation
      'dashboard': 'Dashboard',
      'history': 'History',
      
      // Import Transaction Page
      'import_transaction': 'Import Transaction',
      'manual': 'Manual',
      'file': 'File',
      'scan_ocr': 'Scan (OCR)',
      'transaction_saved_successfully': 'Transaction saved successfully',
      'error_saving': 'Error saving: ',
      'vnd': 'VND',
      'usd': 'USD',
      'eur': 'EUR',
      'income': 'Income',
      'expense': 'Expense',
      'items_splits': 'Items / Splits',
      'save_transaction': 'Save Transaction',
      'file_imported_successfully': 'File imported successfully!',
      'error_importing_file': 'Error importing file: ',
      'select_file': 'Select File',
      'import_file': 'Import File',
      'error_picking_image': 'Error picking image: ',
      'ocr_error': 'OCR Error',
      'ok': 'OK',
      'offline': 'Offline',
      'online': 'Online',
      'auto': 'Auto',
      'select_invoice_image': 'Select Invoice Image',
      
      // Transaction History Page
      'transaction_history': 'Transaction History',
      'no_transactions_found': 'No transactions found',
      'generating_export': 'Generating export...',
      'export_failed': 'Export failed: ',
      
      // Sidebar Menu
      'are_you_sure_sign_out': 'Are you sure you want to sign out?',
      
      // Settings Screen
      'enable_cloud_backup_sync': 'Enable cloud backup and sync',
      'link_account': 'Link Account',
      'switch_to_local_only': 'Switch to local-only mode',
      'unlink': 'Unlink',
      'google_account_unlinked': 'Google account unlinked successfully',
      'confirm_sign_out': 'Are you sure you want to sign out?',
      
      // Export Dialog
      'clear_date_range': 'Clear Date Range',
      'error_preparing_export': 'Error preparing export: ',
      'done': 'Done',
      'could_not_open_file': 'Could not open file: ',
      'error_opening_file': 'Error opening file: ',
      'open_in_external_app': 'Open in External App',
      'pdf_not_available': 'PDF document not available for preview',
      'text_not_available': 'Text content not available for preview',
      
      // Data Widget
      'import': 'Import',
      'no_widgets_selected': 'No widgets selected',
      'open_menu_enable_widgets': 'Open the menu to enable widgets',
      'no_transaction_history': 'No transaction history',
      'click_import_transactions': 'Click to import transactions from a file',
      'click_export_transactions': 'Click to export all transactions to a file',
      'export': 'Export',
      'exporting': 'Exporting...',
      
      // User Selection
      'create_new_user': 'Create New User',
      'select_user': 'Select User',
      'please_fill_all_fields': 'Please fill in all fields',
      'failed_create_user': 'Failed to create user. Username may already exist.',
      'create': 'Create',
      'continue_as_guest': 'Continue as Guest',
      
      // Login Screen
      'login_failed': 'Login failed. Please try again.',
      
      // Widget Names (Dashboard Widgets - keep transactions intact)
      'widget_profile': 'Profile',
      'widget_budget_tracking': 'Budget Tracking',
      'widget_transaction_history': 'Transaction History',
      'widget_import_report': 'Import Report',
      'widget_export_report': 'Export Report',
      'widget_dashboard_widgets': 'Dashboard Widgets',
      'widget_budget_overview': 'Budget Overview',
      'widget_recent_transactions': 'Recent Transactions',
      'profile': 'Profile',
    },
    'vi': {
      'app_title': 'Plutus',
      'settings': 'Cài đặt',
      'account_settings': 'Cài đặt tài khoản',
      'appearance': 'Giao diện',
      'preferences': 'Tùy chọn',
      
      // Theme
      'theme_mode': 'Chế độ giao diện',
      'theme_light': 'Sáng',
      'theme_dark': 'Tối',
      'theme_system': 'Theo hệ thống',
      
      // Language
      'language': 'Ngôn ngữ',
      'language_english': 'English',
      'language_vietnamese': 'Tiếng Việt',
      
      // Currency
      'currency': 'Tiền tệ',
      'currency_vnd': 'Đồng Việt Nam (₫)',
      'currency_usd': 'Đô la Mỹ (\$)',
      'currency_eur': 'Euro (€)',
      
      // Date & Time
      'date_format': 'Định dạng ngày',
      'time_format': 'Định dạng giờ',
      'time_24h': '24 giờ',
      'time_12h': '12 giờ (SA/CH)',
      
      // Account
      'link_google': 'Liên kết tài khoản Google',
      'unlink_google': 'Hủy liên kết Google',
      'switch_user': 'Chuyển người dùng',
      'sign_out': 'Đăng xuất',
      'sign_in': 'Đăng nhập bằng Google',
      
      // Dialog
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'save': 'Lưu',
      
      // Messages
      'guest_mode': 'Chế độ khách',
      'local_account': 'Tài khoản cục bộ',
      'google_linked': 'Đã liên kết Google',
      
      // Navigation
      'dashboard': 'Bảng điều khiển',
      'history': 'Lịch sử',
      
      // Import Transaction Page
      'import_transaction': 'Nhập giao dịch',
      'manual': 'Thủ công',
      'file': 'Tệp',
      'scan_ocr': 'Quét (OCR)',
      'transaction_saved_successfully': 'Giao dịch đã được lưu thành công',
      'error_saving': 'Lỗi lưu: ',
      'vnd': 'VND',
      'usd': 'USD',
      'eur': 'EUR',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'items_splits': 'Mục / Chia nhỏ',
      'save_transaction': 'Lưu giao dịch',
      'file_imported_successfully': 'Tệp đã được nhập thành công!',
      'error_importing_file': 'Lỗi nhập tệp: ',
      'select_file': 'Chọn tệp',
      'import_file': 'Nhập tệp',
      'error_picking_image': 'Lỗi chọn ảnh: ',
      'ocr_error': 'Lỗi OCR',
      'ok': 'OK',
      'offline': 'Ngoại tuyến',
      'online': 'Trực tuyến',
      'auto': 'Tự động',
      'select_invoice_image': 'Chọn ảnh hóa đơn',
      
      // Transaction History Page
      'transaction_history': 'Lịch sử giao dịch',
      'no_transactions_found': 'Không tìm thấy giao dịch',
      'generating_export': 'Đang tạo xuất...',
      'export_failed': 'Xuất thất bại: ',
      
      // Sidebar Menu
      'are_you_sure_sign_out': 'Bạn có chắc chắn muốn đăng xuất?',
      
      // Settings Screen
      'enable_cloud_backup_sync': 'Bật sao lưu và đồng bộ hóa đám mây',
      'link_account': 'Liên kết tài khoản',
      'switch_to_local_only': 'Chuyển sang chế độ chỉ cục bộ',
      'unlink': 'Hủy liên kết',
      'google_account_unlinked': 'Tài khoản Google đã được hủy liên kết thành công',
      'confirm_sign_out': 'Bạn có chắc chắn muốn đăng xuất?',
      
      // Export Dialog
      'clear_date_range': 'Xóa phạm vi ngày',
      'error_preparing_export': 'Lỗi chuẩn bị xuất: ',
      'done': 'Xong',
      'could_not_open_file': 'Không thể mở tệp: ',
      'error_opening_file': 'Lỗi mở tệp: ',
      'open_in_external_app': 'Mở trong ứng dụng bên ngoài',
      'pdf_not_available': 'Tài liệu PDF không có sẵn để xem trước',
      'text_not_available': 'Nội dung văn bản không có sẵn để xem trước',
      
      // Data Widget
      'import': 'Nhập',
      'no_widgets_selected': 'Chưa chọn tiện ích',
      'open_menu_enable_widgets': 'Mở menu để bật tiện ích',
      'no_transaction_history': 'Không có lịch sử giao dịch',
      'click_import_transactions': 'Bấm để nhập giao dịch từ tệp',
      'click_export_transactions': 'Bấm để xuất tất cả giao dịch vào tệp',
      'export': 'Xuất',
      'exporting': 'Đang xuất...',
      
      // User Selection
      'create_new_user': 'Tạo người dùng mới',
      'select_user': 'Chọn người dùng',
      'please_fill_all_fields': 'Vui lòng điền vào tất cả các trường',
      'failed_create_user': 'Không thể tạo người dùng. Tên người dùng có thể đã tồn tại.',
      'create': 'Tạo',
      'continue_as_guest': 'Tiếp tục dưới dạng khách',
      
      // Login Screen
      'login_failed': 'Đăng nhập không thành công. Vui lòng thử lại.',
      
      // Widget Names (Dashboard Widgets - keep transactions intact)
      'widget_profile': 'Hồ sơ',
      'widget_budget_tracking': 'Theo dõi ngân sách',
      'widget_transaction_history': 'Lịch sử giao dịch',
      'widget_import_report': 'Báo cáo nhập',
      'widget_export_report': 'Báo cáo xuất',
      'widget_dashboard_widgets': 'Tiện ích bảng điều khiển',
      'widget_budget_overview': 'Tổng quan ngân sách',
      'widget_recent_transactions': 'Giao dịch gần đây',
      'profile': 'Hồ sơ',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get appTitle => translate('app_title');
  String get settings => translate('settings');
  String get accountSettings => translate('account_settings');
  String get appearance => translate('appearance');
  String get preferences => translate('preferences');
  
  String get themeMode => translate('theme_mode');
  String get themeLight => translate('theme_light');
  String get themeDark => translate('theme_dark');
  String get themeSystem => translate('theme_system');
  
  String get language => translate('language');
  String get languageEnglish => translate('language_english');
  String get languageVietnamese => translate('language_vietnamese');
  
  String get currency => translate('currency');
  String get currencyVnd => translate('currency_vnd');
  String get currencyUsd => translate('currency_usd');
  String get currencyEur => translate('currency_eur');
  
  String get dateFormat => translate('date_format');
  String get timeFormat => translate('time_format');
  String get time24h => translate('time_24h');
  String get time12h => translate('time_12h');
  
  String get linkGoogle => translate('link_google');
  String get unlinkGoogle => translate('unlink_google');
  String get switchUser => translate('switch_user');
  String get signOut => translate('sign_out');
  String get signIn => translate('sign_in');
  
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  
  String get guestMode => translate('guest_mode');
  String get localAccount => translate('local_account');
  String get googleLinked => translate('google_linked');

  // Navigation
  String get dashboard => translate('dashboard');
  String get history => translate('history');

  // Import Transaction Page
  String get importTransaction => translate('import_transaction');
  String get manual => translate('manual');
  String get file => translate('file');
  String get scanOcr => translate('scan_ocr');
  String get transactionSavedSuccessfully => translate('transaction_saved_successfully');
  String get errorSaving => translate('error_saving');
  String get vnd => translate('vnd');
  String get usd => translate('usd');
  String get eur => translate('eur');
  String get income => translate('income');
  String get expense => translate('expense');
  String get itemsSplits => translate('items_splits');
  String get saveTransaction => translate('save_transaction');
  String get fileImportedSuccessfully => translate('file_imported_successfully');
  String get errorImportingFile => translate('error_importing_file');
  String get selectFile => translate('select_file');
  String get importFile => translate('import_file');
  String get errorPickingImage => translate('error_picking_image');
  String get ocrError => translate('ocr_error');
  String get ok => translate('ok');
  String get offline => translate('offline');
  String get online => translate('online');
  String get auto => translate('auto');
  String get selectInvoiceImage => translate('select_invoice_image');

  // Transaction History Page
  String get transactionHistory => translate('transaction_history');
  String get noTransactionsFound => translate('no_transactions_found');
  String get generatingExport => translate('generating_export');
  String get exportFailed => translate('export_failed');

  // Sidebar Menu
  String get areYouSureSignOut => translate('are_you_sure_sign_out');

  // Settings Screen
  String get enableCloudBackupSync => translate('enable_cloud_backup_sync');
  String get linkAccount => translate('link_account');
  String get switchToLocalOnly => translate('switch_to_local_only');
  String get unlink => translate('unlink');
  String get googleAccountUnlinked => translate('google_account_unlinked');
  String get confirmSignOut => translate('confirm_sign_out');

  // Export Dialog
  String get clearDateRange => translate('clear_date_range');
  String get errorPreparingExport => translate('error_preparing_export');
  String get done => translate('done');
  String get couldNotOpenFile => translate('could_not_open_file');
  String get errorOpeningFile => translate('error_opening_file');
  String get openInExternalApp => translate('open_in_external_app');
  String get pdfNotAvailable => translate('pdf_not_available');
  String get textNotAvailable => translate('text_not_available');

  // Data Widget
  String get import => translate('import');
  String get noWidgetsSelected => translate('no_widgets_selected');
  String get openMenuEnableWidgets => translate('open_menu_enable_widgets');
  String get noTransactionHistory => translate('no_transaction_history');
  String get clickImportTransactions => translate('click_import_transactions');
  String get clickExportTransactions => translate('click_export_transactions');
  String get export => translate('export');
  String get exporting => translate('exporting');

  // User Selection
  String get createNewUser => translate('create_new_user');
  String get selectUser => translate('select_user');
  String get pleaseFillAllFields => translate('please_fill_all_fields');
  String get failedCreateUser => translate('failed_create_user');
  String get create => translate('create');
  String get continueAsGuest => translate('continue_as_guest');

  // Login Screen
  String get loginFailed => translate('login_failed');

  // Widget Names (Dashboard Widgets - keep transactions intact)
  String get widgetProfile => translate('widget_profile');
  String get widgetBudgetTracking => translate('widget_budget_tracking');
  String get widgetTransactionHistory => translate('widget_transaction_history');
  String get widgetImportReport => translate('widget_import_report');
  String get widgetExportReport => translate('widget_export_report');
  String get widgetDashboardWidgets => translate('widget_dashboard_widgets');
  String get widgetBudgetOverview => translate('widget_budget_overview');
  String get widgetRecentTransactions => translate('widget_recent_transactions');
  String get profile => translate('profile');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
