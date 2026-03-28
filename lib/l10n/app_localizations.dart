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
      'currency_original': 'Original (No Conversion)',
      
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
      'local_account': 'Personal Account',
      'google_linked': 'Google Linked',

      // Data Consent
      'data_consent_title': 'Data Collection Consent',
      'data_consent_message': 'To provide you with online backup and sync features, we need your permission to collect and store your financial data securely.',
      'data_consent_backup': 'Cloud Backup',
      'data_consent_backup_desc': 'Securely store your data in the cloud',
      'data_consent_sync': 'Multi-Device Sync',
      'data_consent_sync_desc': 'Access your data across multiple devices',
      'data_consent_decline': 'If you decline, you will continue to use the app in offline (guest) mode.',
      'data_consent_agree_btn': 'Agree',
      'data_consent_decline_btn': 'Decline',
      
      // Navigation
      'dashboard': 'Dashboard',
      'history': 'History',
      
      // Import Transaction Page
      'import_transaction': 'Import Transaction',
      'manual': 'Manual',
      'file': 'File',
      'scan_ocr': 'Scan Receipt',
      'transaction_saved_successfully': 'Transaction saved successfully',
      'error_saving': 'Error saving: ',
      'vnd': 'VND',
      'usd': 'USD',
      'eur': 'EUR',
      'income': 'Income',
      'expense': 'Expense',
      'items_splits': 'Split Between Accounts',
      'save_transaction': 'Save Transaction',
      'file_imported_successfully': 'File imported successfully!',
      'error_importing_file': 'Error importing file: ',
      'select_file': 'Select File',
      'import_file': 'Import File',
      'error_picking_image': 'Error picking image: ',
      'ocr_error': "Couldn't Read Receipt",
      'ok': 'OK',
      'offline': 'Offline',
      'online': 'Online',
      'auto': 'Auto',
      'select_invoice_image': 'Choose a Receipt Photo',
      
      // Transaction History Page
      'transaction_history': 'Transaction History',
      'no_transactions_found': 'No transactions found',
      'generating_export': 'Preparing your file...',
      'export_failed': "Couldn't export your data: ",
      
      // Sidebar Menu
      'are_you_sure_sign_out': 'Are you sure you want to sign out?',
      
      // Settings Screen
      'enable_cloud_backup_sync': 'Sync & back up to the cloud',
      'link_account': 'Link Account',
      'switch_to_local_only': 'Save data on this device only',
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
      'no_widgets_selected': 'Your dashboard is empty',
      'open_menu_enable_widgets': 'Tap the menu to add cards to your dashboard',
      'no_transaction_history': 'No transactions yet',
      'click_import_transactions': 'Tap to load transactions from a file',
      'click_export_transactions': 'Tap to download all your transactions',
      'export': 'Export',
      'exporting': 'Exporting...',
      
      // User Selection
      'create_new_user': 'Create New User',
      'select_user': 'Select User',
      'please_fill_all_fields': 'Please fill in all fields',
      'failed_create_user': "Couldn't create your account. That username may already be taken.",
      'create': 'Create',
      'continue_as_guest': 'Continue as Guest',
      
      // Login Screen
      'login_failed': 'Sign-in failed. Please try again.',
      
      // Widget Names (Dashboard Widgets - keep transactions intact)
      'widget_profile': 'Profile',
      'widget_budget_tracking': 'Budget Tracking',
      'widget_transaction_history': 'Transaction History',
      'widget_import_report': 'Import Report',
      'widget_export_report': 'Export Report',
      'widget_dashboard_widgets': 'My Widgets',
      'widget_budget_overview': 'Budget Overview',
      'widget_recent_transactions': 'Recent Transactions',
      'profile': 'Profile',
      
      // Additional Widgets
      'cashflow': 'Cash Flow',
      'roi': 'ROI',
      'irr': 'IRR',
      'tax_estimation': 'Tax Estimation',
      'upcoming_bills': 'Upcoming Bills',
      'expense_breakdown': 'Expense Breakdown',
      'portfolio_allocation': 'Portfolio Allocation',
      'net_worth_trend': 'Net Worth Trend',
      'spending_by_day': 'Spending by Day',
      'income_trend': 'Income Trend',
      'savings_rate': 'Savings Rate',
      'my_profile': 'My Profile',
      'net_cashflow': 'Net Cash Flow',
      'total_income': 'Total Income',
      'total_expenses': 'Total Expenses',
      'return_on_investment': 'Return on Investment (ROI)',
      'internal_rate_of_return': 'Annualised Growth Rate (IRR)',
      'estimated_tax': 'Estimated Tax',
      'no_bills_upcoming': 'No bills upcoming',
      'due_date': 'Due Date',
      'amount': 'Amount',
      'paid': 'Paid',
      'unpaid': 'Unpaid',
      'total_due': 'Total Due',
      'month': 'Month',
      'year': 'Year',
      'vietnamese_personal_income_tax': 'Vietnamese Personal Income Tax',
      'tax_breakdown': 'Tax Breakdown',
      'financial_year': 'Financial Year',
      'vietnamese_tax_brackets': 'Vietnamese Tax Brackets',
      'monthly_income_range': 'Monthly Income',
      'rate': 'Rate',
      'deduction': 'Deduction',
      'income_section': 'Income',
      'annual_income': 'Annual Income',
      'monthly_income': 'Monthly Income',
      'deductions_section': 'Deductions',
      'personal_deduction': 'Personal Deduction',
      'total_deductions': 'Total Deductions',
      'taxable_income_section': 'Taxable Income',
      'annual_taxable': 'Annual Taxable',
      'monthly_taxable': 'Monthly Taxable',
      'tax_bracket': 'Tax Bracket',
      'range': 'Range',
      'tax_calculation': 'Tax Calculation',
      'monthly_tax': 'Monthly Tax',
      'annual_tax': 'Annual Tax',
      'effective_rate': 'Effective Rate',
      'net_income_section': 'Net Income',
      'after_tax': 'After Tax',
      'based_on_vietnamese_tax_law': 'Based on Vietnamese progressive tax law (Circular 111/2013/TT-BTC)',
      'estimated_tax_label': 'Estimated Tax',
      'current_roi': 'ROI — Your Investment Returns',
      'current_irr': 'IRR — Annualised Growth Rate',
      'click_for_details': 'Click for Details & Tax Table',
      
      // Investment Tracking Widget
      'investments': 'Investments',
      'portfolio': 'Portfolio',
      'add_investment': 'Add Investment',
      'edit_investment': 'Edit Investment',
      'delete_investment': 'Delete Investment',
      'value_history': 'Price History',
      'api_tracked': 'Live Price Updates',
      'current_value': 'Current Value',
      'cost_basis': 'Amount Invested',
      'gain_loss': 'Gain/Loss',
      'quantity': 'Quantity',
      'performance_chart': 'Growth Chart',
      'total_portfolio_value': 'Total Investment Value',
      'no_investments_yet': 'No investments yet. Tap + to start tracking one.',
      'error_loading_data': "Couldn't load your investments",
      'retry': 'Retry',
      'investment_name': 'Investment Name',
      'commodity_symbol': 'Ticker Symbol',
      'tracking_type': 'Price Tracking',
      'initial_value': 'Initial Value',
      'add_value_entry': 'Record a Price Update',
      'date': 'Date',
      'from_currency': 'From Currency',
      'to_currency': 'To Currency',
      'exchange_rate': 'Exchange Rate',
      'transactions': 'Transactions',
      'transaction_type': 'Transaction Type',
      'buy': 'Buy',
      'sell': 'Sell',
      'dividend': 'Dividend',
      'total_inflow': 'Total Money In',
      'total_outflow': 'Total Money Out',
      'net_cashflow_investment': 'Net Cash Flow',
      'unrealized_gain_loss': 'Unrealized Profit / Loss',
      'percentage_return': 'Total Return %',
      'last_updated': 'Last Updated',
      'refresh_prices': 'Refresh Prices',
      'delete_confirmation': 'Are you sure you want to delete this investment?',
      'delete': 'Delete',
      'edit': 'Edit',
      'investment_details': 'Investment Details',
      'no_transaction_history_investment': 'No transaction history',
      'no_value_history': 'No value history',
      'add_first_value': 'Add your first price update',
      'invalid_commodity_symbol': 'Ticker symbols can only contain letters, numbers, and underscores',
      'invalid_exchange_rate': 'Please enter a valid exchange rate (must be greater than 0)',
      'invalid_date': "Please choose a date that isn't in the future",
      'required_field': 'This field is required',
      'investment_added': 'Investment added successfully',
      'investment_updated': 'Investment updated successfully',
      'investment_deleted': 'Investment deleted successfully',
      'error_adding_investment': 'Error adding investment',
      'error_updating_investment': 'Error updating investment',
      'error_deleting_investment': 'Error deleting investment',
      
      // Transaction Detail Dialog
      'transaction_details': 'Transaction Details',
      'payee': 'Paid To',
      'description': 'Description',
      'type': 'Type',
      'postings': 'Account Entries',
      'account': 'Account',
      'close': 'Close',
      
      // Backup
      'backup_settings': 'Backup Settings',
      'backup_enabled': 'Backup Enabled',
      'backup_disabled': 'Backup Disabled',
      'backup_history': 'Backup History',
      'backup_restore': 'Restore Backup',
      'backup_restore_confirm': 'Are you sure you want to restore this backup? Your current data will be replaced.',
      'backup_uploading': 'Uploading backup...',
      'backup_downloading': 'Downloading backup...',
      'backup_success': 'Backup completed successfully',
      'backup_failed': 'Backup failed',
      'backup_conflict_title': 'Backup Conflict Detected',
      'backup_conflict_message': 'Your local data differs from the latest cloud backup. What would you like to do?',
      'backup_conflict_override': 'Replace my data with the cloud version',
      'backup_conflict_keep_local': 'Keep my current data and back it up',
      'backup_conflict_cancel': 'Cancel',
      'backup_no_versions': 'No backup versions available',
      'backup_version_timestamp': 'Backup Time',
      'backup_version_size': 'Size',
      'backup_error_network': "Couldn't connect to the internet. Please check your connection and try again.",
      'backup_error_credentials': "Cloud access isn't set up correctly. Please update your settings.",
      'backup_error_s3': 'Cloud storage is currently unavailable. Please try again later.',
      'backup_manual_backup': 'Manual Backup',
      'backup_last_sync': 'Last Sync',
      'backup_found_title': 'Cloud Backup Found',
      'backup_found_message': 'A cloud backup was found for your account. Would you like to restore it to this device?',
      'backup_found_restore': 'Restore my saved data',
      'backup_found_skip': 'Start fresh',

      // Multi-Dashboard
      'new_dashboard': '+ New Dashboard',
      'create_dashboard': 'Create Dashboard',
      'dashboard_name': 'Dashboard Name',
      'dashboard_name_required': 'Name is required',
      'dashboard_name_exists': 'A dashboard with this name already exists',
      'start_with_defaults': 'Use the default layout',
      'start_empty': 'Start with a blank dashboard',
      'save_layout': 'Save Layout',
      'layout_saved': 'Layout saved',
      'reset_dashboard': 'Undo Changes',
      'hard_reset_dashboard': 'Reset to Default',
      'hard_reset_warning': 'This will restore the default layout and show all cards. This cannot be undone.',
      'rename_dashboard': 'Rename Dashboard',
      'delete_dashboard': 'Delete Dashboard',
      'delete_warning': 'Are you sure you want to delete this dashboard? This cannot be undone.',
      'max_dashboards_reached': "You've reached the limit of 5 dashboards",
      'cannot_delete_last': 'You must keep at least one dashboard',

      // Sidebar categories & search
      'search_widgets': 'Search widgets...',
      'category_overview': 'Overview',
      'category_analytics': 'Analytics',
      'category_investments': 'Investments',
      'category_tools': 'Tools',
      'add_widget': 'Add',
      'remove_instance': 'Remove',
      'add_duplicate': 'Add another',
      'max_instances': 'Max reached',
      'widget_count': 'on dashboard',
      'widgets_on_dashboard': 'widgets on dashboard',

      // ── Budget Summary Widget ──
      'budget_no_budget_yet': 'No budget set up yet',
      'budget_create': 'Create Budget',
      'budget_budgeted': 'BUDGETED',
      'budget_spent': 'SPENT',
      'budget_left': 'LEFT',

      // ── Budget Settings Sheet ──
      'budget_settings': 'Budget Settings',
      'budget_please_login': 'Please log in first',
      'budget_mode': 'Budget Mode',
      'budget_spending_limits': 'Spending Limits',
      'budget_zero_based': 'Zero-Based',
      'budget_period': 'Budget Period',
      'budget_monthly': 'Monthly',
      'budget_weekly': 'Weekly',
      'budget_biweekly': 'Biweekly',
      'budget_currency_label': 'Currency',
      'budget_categories_label': 'Categories',
      'budget_add_category': 'Add Category',
      'budget_notifications': 'Notifications',
      'budget_rollover': 'Rollover',
      'budget_category_name': 'Category Name',
      'budget_account_pattern': 'Account Pattern',
      'budget_amount': 'Budget Amount',
      'budget_common_categories': 'Common Categories',
      'budget_from_transactions': 'From Your Transactions',
      'budget_other_custom': 'Other (custom)',
      'budget_no_active': 'No active budget found',
      'budget_add': 'Add',
      'budget_save': 'Save Budget',
      'budget_delete_category': 'Delete',
      'budget_no_categories': 'No categories yet. Add one below.',
      'budget_no_budget_yet_long': 'Create a budget to start tracking your spending by category.',
      'budget_my_budget': 'My Budget',
      'budget_select_category': 'Select a category',
      'budget_alert_threshold': 'Alert at spending threshold',
      'budget_alert_default': 'Default: 90%',
      'budget_suggested': 'Suggested from Transactions',
      'budget_no_suggestions': 'No suggestions available.',
      'budget_pattern_hint': 'Matches transactions starting with this prefix',

      // ── Category Budget Widget ──
      'category_budget_title': 'Category Budgets',
      'budget_over': 'over budget',
      'budget_approaching': 'approaching limit',
      'budget_unbudgeted': 'Unbudgeted Spending',
      'budget_add_quick': '+ Budget',
      'budget_rollover_badge': 'Rollover',
      'budget_pace_warning': 'Ahead of pace',
      'budget_of': 'of',
      'budget_remaining': 'remaining',
      'budget_over_label': 'over',
      'budget_left_label': 'left',
      'budget_spent_label': 'spent',
      'budget_rolled': 'rolled',
      'budget_budgeted_label': 'budgeted',
      'budget_pace': 'pace',
      'budget_edit_for': 'Edit budget for',
      'budget_for': 'Budget for',
      'budget_current_spending': 'Current spending',
      'budget_monthly_amount': 'Monthly budget amount',
      'budget_settings_title': 'Budget settings',

      // ── Savings Rate Widget ──
      'savings_no_data': 'No data available',
      'savings_this_month': 'This Month',
      'savings_on_track': 'On track',
      'savings_almost_there': 'Almost there',
      'savings_below_target': 'Below target',
      'savings_saved_this_month': 'saved this month',
      'savings_progress_label': 'Progress toward 20% target',
      'savings_rule_label': '50/30/20 rule',
      'savings_vs_last_month': 'vs last month',
      'savings_income_label': 'Income',
      'savings_expenses_label': 'Expenses',
      'savings_saved_label': 'Saved',
      'savings_no_trend_data': 'Not enough data for trend',

      // ── Add Investment Dialog ──
      'investment_type': 'Investment Type',
      'investment_stock': 'Stock',
      'investment_bond': 'Bond',
      'investment_crypto': 'Cryptocurrency',
      'investment_other': 'Other',
      'investment_total_paid': 'Total Amount Paid',
      'investment_purchase_date': 'Purchase Date',
      'investment_currency_label': 'Currency',
      'investment_how_much': 'How much did you pay in total?',
      'investment_enter_amount': 'Please enter the amount you paid',
      'investment_enter_quantity': 'Please enter a quantity',
      'investment_greater_than_zero': 'Please enter a number greater than 0',
      'investment_ticker_hint_stock': 'e.g., AAPL, GOOGL',
      'investment_ticker_hint_crypto': 'e.g., BTC, ETH',
      'investment_ticker_hint_bond': 'e.g., US10Y',
      'investment_ticker_hint_other': 'e.g., Gold, Real Estate',
      'investment_quantity_hint': 'e.g., 10, 0.5',

      // ── Avatar Editor Widget ──
      'avatar_edit': 'Edit Avatar',
      'avatar_rotate': 'Rotate',
      'avatar_zoom_in': 'Zoom In',
      'avatar_zoom_out': 'Zoom Out',
      'avatar_reset': 'Reset',
      'avatar_source_title': 'Choose Avatar Source',
      'avatar_camera': 'Camera',
      'avatar_gallery': 'Gallery',

      // ── Cash Flow Widget ──
      'cashflow_select_year': 'Select Year',

      // ── Widget Catalog Labels ──
      'widget_label_profile': 'Profile',
      'widget_label_budget': 'Budget Summary',
      'widget_label_category_budget': 'Category Budget',
      'widget_label_savings_rate': 'Savings Rate',
      'widget_label_net_worth_trend': 'Net Worth Trend',
      'widget_label_history': 'Transaction History',
      'widget_label_cashflow': 'Cash Flow',
      'widget_label_expense_breakdown': 'Expense Breakdown',
      'widget_label_income_trend': 'Income Trend',
      'widget_label_spending_heatmap': 'Spending Heatmap',
      'widget_label_tax': 'Tax Estimation',
      'widget_label_investment': 'Investments',
      'widget_label_portfolio_allocation': 'Portfolio Allocation',
      'widget_label_roi': 'ROI',
      'widget_label_irr': 'IRR',
      'widget_label_market_trending': 'Market Trending',
      'widget_label_bills': 'Upcoming Bills',
      'widget_label_import': 'Import Report',
      'widget_label_export': 'Export Report',

      // ── Widget Catalog Category Labels ──
      'widget_cat_overview': 'Overview',
      'widget_cat_analytics': 'Analytics',
      'widget_cat_investments': 'Investments',
      'widget_cat_tools': 'Tools',

      // ── Dashboard Screen ──
      'widget_preview': 'Widget Preview',
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
      'currency_original': 'Gốc (Không chuyển đổi)',
      
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
      'local_account': 'Tài khoản cá nhân',
      'google_linked': 'Đã liên kết Google',

      // Data Consent
      'data_consent_title': 'Đồng ý thu thập dữ liệu',
      'data_consent_message': 'Để cung cấp cho bạn các tính năng sao lưu và đồng bộ đám mây, chúng tôi cần sự cho phép của bạn để thu thập và lưu trữ an toàn dữ liệu tài chính của bạn.',
      'data_consent_backup': 'Sao lưu đám mây',
      'data_consent_backup_desc': 'Lưu trữ an toàn dữ liệu của bạn trên đám mây',
      'data_consent_sync': 'Đồng bộ đa thiết bị',
      'data_consent_sync_desc': 'Truy cập dữ liệu của bạn trên nhiều thiết bị',
      'data_consent_decline': 'Nếu bạn từ chối, bạn sẽ tiếp tục sử dụng ứng dụng ở chế độ ngoại tuyến (khách).',
      'data_consent_agree_btn': 'Đồng ý',
      'data_consent_decline_btn': 'Từ chối',
      
      // Navigation
      'dashboard': 'Bảng điều khiển',
      'history': 'Lịch sử',
      
      // Import Transaction Page
      'import_transaction': 'Nhập giao dịch',
      'manual': 'Thủ công',
      'file': 'Tệp',
      'scan_ocr': 'Quét hoá đơn',
      'transaction_saved_successfully': 'Giao dịch đã được lưu thành công',
      'error_saving': 'Lỗi lưu: ',
      'vnd': 'VND',
      'usd': 'USD',
      'eur': 'EUR',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'items_splits': 'Phân chia theo tài khoản',
      'save_transaction': 'Lưu giao dịch',
      'file_imported_successfully': 'Tệp đã được nhập thành công!',
      'error_importing_file': 'Lỗi nhập tệp: ',
      'select_file': 'Chọn tệp',
      'import_file': 'Nhập tệp',
      'error_picking_image': 'Lỗi chọn ảnh: ',
      'ocr_error': 'Không thể đọc biên lai',
      'ok': 'OK',
      'offline': 'Ngoại tuyến',
      'online': 'Trực tuyến',
      'auto': 'Tự động',
      'select_invoice_image': 'Chọn ảnh biên lai',
      
      // Transaction History Page
      'transaction_history': 'Lịch sử giao dịch',
      'no_transactions_found': 'Không tìm thấy giao dịch',
      'generating_export': 'Đang chuẩn bị tệp...',
      'export_failed': 'Không thể xuất dữ liệu: ',
      
      // Sidebar Menu
      'are_you_sure_sign_out': 'Bạn có chắc chắn muốn đăng xuất?',
      
      // Settings Screen
      'enable_cloud_backup_sync': 'Đồng bộ & sao lưu lên đám mây',
      'link_account': 'Liên kết tài khoản',
      'switch_to_local_only': 'Chỉ lưu dữ liệu trên thiết bị này',
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
      'no_widgets_selected': 'Bảng điều khiển của bạn trống',
      'open_menu_enable_widgets': 'Mở menu để thêm thẻ vào bảng điều khiển',
      'no_transaction_history': 'Chưa có giao dịch nào',
      'click_import_transactions': 'Nhấn để tải giao dịch từ tệp',
      'click_export_transactions': 'Nhấn để tải xuống tất cả giao dịch',
      'export': 'Xuất',
      'exporting': 'Đang xuất...',
      
      // User Selection
      'create_new_user': 'Tạo người dùng mới',
      'select_user': 'Chọn người dùng',
      'please_fill_all_fields': 'Vui lòng điền vào tất cả các trường',
      'failed_create_user': 'Không thể tạo tài khoản. Tên người dùng này có thể đã được sử dụng.',
      'create': 'Tạo',
      'continue_as_guest': 'Tiếp tục dưới dạng khách',
      
      // Login Screen
      'login_failed': 'Đăng nhập thất bại. Vui lòng thử lại.',
      
      // Widget Names (Dashboard Widgets - keep transactions intact)
      'widget_profile': 'Hồ sơ',
      'widget_budget_tracking': 'Theo dõi ngân sách',
      'widget_transaction_history': 'Lịch sử giao dịch',
      'widget_import_report': 'Báo cáo nhập',
      'widget_export_report': 'Báo cáo xuất',
      'widget_dashboard_widgets': 'Thẻ của tôi',
      'widget_budget_overview': 'Tổng quan ngân sách',
      'widget_recent_transactions': 'Giao dịch gần đây',
      'profile': 'Hồ sơ',
      
      // Additional Widgets
      'cashflow': 'Dòng Tiền',
      'roi': 'ROI',
      'irr': 'IRR',
      'tax_estimation': 'Ước tính thuế',
      'upcoming_bills': 'Hóa đơn sắp tới',
      'expense_breakdown': 'Phân tích chi tiêu',
      'portfolio_allocation': 'Phân bổ danh mục',
      'net_worth_trend': 'Xu hướng tài sản ròng',
      'spending_by_day': 'Chi tiêu theo ngày',
      'income_trend': 'Xu hướng thu nhập',
      'savings_rate': 'Tỷ lệ tiết kiệm',
      'my_profile': 'Hồ sơ của tôi',
      'net_cashflow': 'Dòng Tiền Ròng',
      'total_income': 'Tổng thu nhập',
      'total_expenses': 'Tổng chi tiêu',
      'return_on_investment': 'Lợi nhuận đầu tư (ROI)',
      'internal_rate_of_return': 'Tỷ lệ tăng trưởng hàng năm (IRR)',
      'estimated_tax': 'Thuế ước tính',
      'no_bills_upcoming': 'Không có hóa đơn sắp tới',
      'due_date': 'Ngày đến hạn',
      'amount': 'Số tiền',
      'paid': 'Đã thanh toán',
      'unpaid': 'Chưa thanh toán',
      'total_due': 'Tổng phải trả',
      'month': 'Tháng',
      'year': 'Năm',
      'vietnamese_personal_income_tax': 'Thuế thu nhập cá nhân Việt Nam',
      'tax_breakdown': 'Chi tiết thuế',
      'financial_year': 'Năm tài chính',
      'vietnamese_tax_brackets': 'Bậc thuế Việt Nam',
      'monthly_income_range': 'Thu nhập tháng',
      'rate': 'Thuế suất',
      'deduction': 'Khấu trừ',
      'income_section': 'Thu nhập',
      'annual_income': 'Thu nhập năm',
      'monthly_income': 'Thu nhập tháng',
      'deductions_section': 'Các khoản giảm trừ',
      'personal_deduction': 'Giảm trừ bản thân',
      'total_deductions': 'Tổng giảm trừ',
      'taxable_income_section': 'Thu nhập tính thuế',
      'annual_taxable': 'Thu nhập tính thuế năm',
      'monthly_taxable': 'Thu nhập tính thuế tháng',
      'tax_bracket': 'Bậc thuế',
      'range': 'Khoảng',
      'tax_calculation': 'Tính thuế',
      'monthly_tax': 'Thuế tháng',
      'annual_tax': 'Thuế năm',
      'effective_rate': 'Thuế suất thực tế',
      'net_income_section': 'Thu nhập ròng',
      'after_tax': 'Sau thuế',
      'based_on_vietnamese_tax_law': 'Dựa trên luật thuế lũy tiến Việt Nam (Thông tư 111/2013/TT-BTC)',
      'estimated_tax_label': 'Thuế ước tính',
      'current_roi': 'ROI — Lợi nhuận đầu tư',
      'current_irr': 'IRR — Tỷ lệ tăng trưởng hàng năm',
      'click_for_details': 'Bấm để xem chi tiết & bảng thuế',
      
      // Investment Tracking Widget
      'investments': 'Đầu tư',
      'portfolio': 'Danh mục đầu tư',
      'add_investment': 'Thêm đầu tư',
      'edit_investment': 'Chỉnh sửa đầu tư',
      'delete_investment': 'Xóa đầu tư',
      'value_history': 'Lịch sử giá',
      'api_tracked': 'Cập nhật giá tự động',
      'current_value': 'Giá trị hiện tại',
      'cost_basis': 'Số tiền đã đầu tư',
      'gain_loss': 'Lãi/Lỗ',
      'quantity': 'Số lượng',
      'performance_chart': 'Biểu đồ tăng trưởng',
      'total_portfolio_value': 'Tổng giá trị đầu tư',
      'no_investments_yet': 'Chưa có đầu tư. Nhấn + để bắt đầu theo dõi.',
      'error_loading_data': 'Không thể tải danh mục đầu tư',
      'retry': 'Thử lại',
      'investment_name': 'Tên đầu tư',
      'commodity_symbol': 'Mã cổ phiếu',
      'tracking_type': 'Cách theo dõi giá',
      'initial_value': 'Giá trị ban đầu',
      'add_value_entry': 'Cập nhật giá mới',
      'date': 'Ngày',
      'from_currency': 'Từ tiền tệ',
      'to_currency': 'Sang tiền tệ',
      'exchange_rate': 'Tỷ giá',
      'transactions': 'Giao dịch',
      'transaction_type': 'Loại giao dịch',
      'buy': 'Mua',
      'sell': 'Bán',
      'dividend': 'Cổ tức',
      'total_inflow': 'Tổng tiền vào',
      'total_outflow': 'Tổng tiền ra',
      'net_cashflow_investment': 'Dòng Tiền Ròng',
      'unrealized_gain_loss': 'Lãi / Lỗ chưa thực hiện',
      'percentage_return': 'Tổng lợi nhuận %',
      'last_updated': 'Cập nhật lần cuối',
      'refresh_prices': 'Làm mới giá',
      'delete_confirmation': 'Bạn có chắc chắn muốn xóa đầu tư này?',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'investment_details': 'Chi tiết đầu tư',
      'no_transaction_history_investment': 'Không có lịch sử giao dịch',
      'no_value_history': 'Không có lịch sử giá trị',
      'add_first_value': 'Thêm cập nhật giá đầu tiên',
      'invalid_commodity_symbol': 'Mã cổ phiếu chỉ được chứa chữ cái, số và dấu gạch dưới',
      'invalid_exchange_rate': 'Vui lòng nhập tỷ giá hợp lệ (phải lớn hơn 0)',
      'invalid_date': 'Vui lòng chọn ngày không phải là ngày trong tương lai',
      'required_field': 'Trường này là bắt buộc',
      'investment_added': 'Đã thêm đầu tư thành công',
      'investment_updated': 'Đã cập nhật đầu tư thành công',
      'investment_deleted': 'Đã xóa đầu tư thành công',
      'error_adding_investment': 'Lỗi thêm đầu tư',
      'error_updating_investment': 'Lỗi cập nhật đầu tư',
      'error_deleting_investment': 'Lỗi xóa đầu tư',
      
      // Transaction Detail Dialog
      'transaction_details': 'Chi tiết giao dịch',
      'payee': 'Thanh toán cho',
      'description': 'Mô tả',
      'type': 'Loại',
      'postings': 'Mục tài khoản',
      'account': 'Tài khoản',
      'close': 'Đóng',
      
      // Backup
      'backup_settings': 'Cài đặt sao lưu',
      'backup_enabled': 'Sao lưu đã bật',
      'backup_disabled': 'Sao lưu đã tắt',
      'backup_history': 'Lịch sử sao lưu',
      'backup_restore': 'Khôi phục sao lưu',
      'backup_restore_confirm': 'Bạn có chắc chắn muốn khôi phục bản sao lưu này? Dữ liệu hiện tại sẽ bị thay thế.',
      'backup_uploading': 'Đang tải lên bản sao lưu...',
      'backup_downloading': 'Đang tải xuống bản sao lưu...',
      'backup_success': 'Sao lưu hoàn tất thành công',
      'backup_failed': 'Sao lưu thất bại',
      'backup_conflict_title': 'Phát hiện xung đột sao lưu',
      'backup_conflict_message': 'Dữ liệu cục bộ khác với bản sao lưu đám mây mới nhất. Bạn muốn làm gì?',
      'backup_conflict_override': 'Thay thế dữ liệu của tôi bằng phiên bản đám mây',
      'backup_conflict_keep_local': 'Giữ dữ liệu hiện tại và sao lưu lên đám mây',
      'backup_conflict_cancel': 'Hủy',
      'backup_no_versions': 'Không có phiên bản sao lưu nào',
      'backup_version_timestamp': 'Thời gian sao lưu',
      'backup_version_size': 'Kích thước',
      'backup_error_network': 'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
      'backup_error_credentials': 'Cài đặt đám mây chưa đúng. Vui lòng cập nhật trong phần cài đặt.',
      'backup_error_s3': 'Lưu trữ đám mây hiện không khả dụng. Vui lòng thử lại sau.',
      'backup_manual_backup': 'Sao lưu thủ công',
      'backup_last_sync': 'Đồng bộ lần cuối',
      'backup_found_title': 'Tìm thấy bản sao lưu đám mây',
      'backup_found_message': 'Đã tìm thấy bản sao lưu đám mây cho tài khoản của bạn. Bạn có muốn khôi phục về thiết bị này không?',
      'backup_found_restore': 'Khôi phục dữ liệu của tôi',
      'backup_found_skip': 'Bắt đầu mới',

      // Multi-Dashboard
      'new_dashboard': '+ Bảng điều khiển mới',
      'create_dashboard': 'Tạo bảng điều khiển',
      'dashboard_name': 'Tên bảng điều khiển',
      'dashboard_name_required': 'Tên là bắt buộc',
      'dashboard_name_exists': 'Đã có bảng điều khiển với tên này',
      'start_with_defaults': 'Dùng bố cục mặc định',
      'start_empty': 'Bắt đầu với bảng điều khiển trống',
      'save_layout': 'Lưu bố cục',
      'layout_saved': 'Đã lưu bố cục',
      'reset_dashboard': 'Hoàn tác thay đổi',
      'hard_reset_dashboard': 'Khôi phục mặc định',
      'hard_reset_warning': 'Bố cục mặc định sẽ được khôi phục và tất cả thẻ sẽ hiển thị. Không thể hoàn tác.',
      'rename_dashboard': 'Đổi tên bảng điều khiển',
      'delete_dashboard': 'Xóa bảng điều khiển',
      'delete_warning': 'Bạn có chắc chắn muốn xóa bảng điều khiển này? Không thể hoàn tác.',
      'max_dashboards_reached': 'Bạn đã đạt giới hạn 5 bảng điều khiển',
      'cannot_delete_last': 'Bạn cần giữ ít nhất một bảng điều khiển',

      // Sidebar categories & search
      'search_widgets': 'Tìm kiếm widget...',
      'category_overview': 'Tổng quan',
      'category_analytics': 'Phân tích',
      'category_investments': 'Đầu tư',
      'category_tools': 'Công cụ',
      'add_widget': 'Thêm',
      'remove_instance': 'Xóa',
      'add_duplicate': 'Thêm bản sao',
      'max_instances': 'Đã đạt tối đa',
      'widget_count': 'trên bảng',
      'widgets_on_dashboard': 'widget trên bảng',

      // ── Budget Summary Widget ──
      'budget_no_budget_yet': 'Chưa thiết lập ngân sách',
      'budget_create': 'Tạo ngân sách',
      'budget_budgeted': 'NGÂN SÁCH',
      'budget_spent': 'ĐÃ CHI',
      'budget_left': 'CÒN LẠI',

      // ── Budget Settings Sheet ──
      'budget_settings': 'Cài đặt ngân sách',
      'budget_please_login': 'Vui lòng đăng nhập trước',
      'budget_mode': 'Chế độ ngân sách',
      'budget_spending_limits': 'Giới hạn chi tiêu',
      'budget_zero_based': 'Ngân sách từ 0',
      'budget_period': 'Kỳ ngân sách',
      'budget_monthly': 'Hàng tháng',
      'budget_weekly': 'Hàng tuần',
      'budget_biweekly': 'Hai tuần',
      'budget_currency_label': 'Tiền tệ',
      'budget_categories_label': 'Danh mục',
      'budget_add_category': 'Thêm danh mục',
      'budget_notifications': 'Thông báo',
      'budget_rollover': 'Chuyển tiếp',
      'budget_category_name': 'Tên danh mục',
      'budget_account_pattern': 'Mẫu tài khoản',
      'budget_amount': 'Số tiền ngân sách',
      'budget_common_categories': 'Danh mục phổ biến',
      'budget_from_transactions': 'Từ giao dịch của bạn',
      'budget_other_custom': 'Khác (tùy chỉnh)',
      'budget_no_active': 'Không tìm thấy ngân sách',
      'budget_add': 'Thêm',
      'budget_save': 'Lưu ngân sách',
      'budget_delete_category': 'Xóa',
      'budget_no_categories': 'Chưa có danh mục. Thêm danh mục bên dưới.',
      'budget_no_budget_yet_long': 'Tạo ngân sách để bắt đầu theo dõi chi tiêu theo danh mục.',
      'budget_my_budget': 'Ngân sách của tôi',
      'budget_select_category': 'Chọn danh mục',
      'budget_alert_threshold': 'Cảnh báo khi đạt ngưỡng chi tiêu',
      'budget_alert_default': 'Mặc định: 90%',
      'budget_suggested': 'Gợi ý từ giao dịch',
      'budget_no_suggestions': 'Không có gợi ý.',
      'budget_pattern_hint': 'Khớp giao dịch bắt đầu bằng tiền tố này',

      // ── Category Budget Widget ──
      'category_budget_title': 'Ngân sách theo danh mục',
      'budget_over': 'vượt ngân sách',
      'budget_approaching': 'gần đạt giới hạn',
      'budget_unbudgeted': 'Chi tiêu ngoài ngân sách',
      'budget_add_quick': '+ Ngân sách',
      'budget_rollover_badge': 'Chuyển tiếp',
      'budget_pace_warning': 'Nhanh hơn dự kiến',
      'budget_of': 'trên',
      'budget_remaining': 'còn lại',
      'budget_over_label': 'vượt',
      'budget_left_label': 'còn',
      'budget_spent_label': 'đã chi',
      'budget_rolled': 'chuyển tiếp',
      'budget_budgeted_label': 'ngân sách',
      'budget_pace': 'tốc độ',
      'budget_edit_for': 'Chỉnh sửa ngân sách cho',
      'budget_for': 'Ngân sách cho',
      'budget_current_spending': 'Chi tiêu hiện tại',
      'budget_monthly_amount': 'Số tiền ngân sách hàng tháng',
      'budget_settings_title': 'Cài đặt ngân sách',

      // ── Savings Rate Widget ──
      'savings_no_data': 'Không có dữ liệu',
      'savings_this_month': 'Tháng này',
      'savings_on_track': 'Đạt mục tiêu',
      'savings_almost_there': 'Gần đạt',
      'savings_below_target': 'Dưới mục tiêu',
      'savings_saved_this_month': 'tiết kiệm tháng này',
      'savings_progress_label': 'Tiến độ đến mục tiêu 20%',
      'savings_rule_label': 'Quy tắc 50/30/20',
      'savings_vs_last_month': 'so với tháng trước',
      'savings_income_label': 'Thu nhập',
      'savings_expenses_label': 'Chi tiêu',
      'savings_saved_label': 'Tiết kiệm',
      'savings_no_trend_data': 'Không đủ dữ liệu để phân tích xu hướng',

      // ── Add Investment Dialog ──
      'investment_type': 'Loại đầu tư',
      'investment_stock': 'Cổ phiếu',
      'investment_bond': 'Trái phiếu',
      'investment_crypto': 'Tiền điện tử',
      'investment_other': 'Khác',
      'investment_total_paid': 'Tổng số tiền đã trả',
      'investment_purchase_date': 'Ngày mua',
      'investment_currency_label': 'Tiền tệ',
      'investment_how_much': 'Bạn đã trả bao nhiêu tổng cộng?',
      'investment_enter_amount': 'Vui lòng nhập số tiền đã trả',
      'investment_enter_quantity': 'Vui lòng nhập số lượng',
      'investment_greater_than_zero': 'Vui lòng nhập số lớn hơn 0',
      'investment_ticker_hint_stock': 'vd: AAPL, GOOGL',
      'investment_ticker_hint_crypto': 'vd: BTC, ETH',
      'investment_ticker_hint_bond': 'vd: US10Y',
      'investment_ticker_hint_other': 'vd: Vàng, Bất động sản',
      'investment_quantity_hint': 'vd: 10, 0.5',

      // ── Avatar Editor Widget ──
      'avatar_edit': 'Chỉnh sửa ảnh đại diện',
      'avatar_rotate': 'Xoay',
      'avatar_zoom_in': 'Phóng to',
      'avatar_zoom_out': 'Thu nhỏ',
      'avatar_reset': 'Đặt lại',
      'avatar_source_title': 'Chọn nguồn ảnh đại diện',
      'avatar_camera': 'Máy ảnh',
      'avatar_gallery': 'Thư viện',

      // ── Cash Flow Widget ──
      'cashflow_select_year': 'Chọn năm',

      // ── Widget Catalog Labels ──
      'widget_label_profile': 'Hồ sơ',
      'widget_label_budget': 'Tổng quan ngân sách',
      'widget_label_category_budget': 'Ngân sách danh mục',
      'widget_label_savings_rate': 'Tỷ lệ tiết kiệm',
      'widget_label_net_worth_trend': 'Xu hướng tài sản ròng',
      'widget_label_history': 'Lịch sử giao dịch',
      'widget_label_cashflow': 'Dòng tiền',
      'widget_label_expense_breakdown': 'Phân tích chi tiêu',
      'widget_label_income_trend': 'Xu hướng thu nhập',
      'widget_label_spending_heatmap': 'Biểu đồ chi tiêu',
      'widget_label_tax': 'Ước tính thuế',
      'widget_label_investment': 'Đầu tư',
      'widget_label_portfolio_allocation': 'Phân bổ danh mục',
      'widget_label_roi': 'ROI',
      'widget_label_irr': 'IRR',
      'widget_label_market_trending': 'Xu hướng thị trường',
      'widget_label_bills': 'Hóa đơn sắp tới',
      'widget_label_import': 'Báo cáo nhập',
      'widget_label_export': 'Báo cáo xuất',

      // ── Widget Catalog Category Labels ──
      'widget_cat_overview': 'Tổng quan',
      'widget_cat_analytics': 'Phân tích',
      'widget_cat_investments': 'Đầu tư',
      'widget_cat_tools': 'Công cụ',

      // ── Dashboard Screen ──
      'widget_preview': 'Xem trước widget',
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
  String get currencyOriginal => translate('currency_original');
  
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

  // Data Consent
  String get dataConsentTitle => translate('data_consent_title');
  String get dataConsentMessage => translate('data_consent_message');
  String get dataConsentBackup => translate('data_consent_backup');
  String get dataConsentBackupDesc => translate('data_consent_backup_desc');
  String get dataConsentSync => translate('data_consent_sync');
  String get dataConsentSyncDesc => translate('data_consent_sync_desc');
  String get dataConsentDecline => translate('data_consent_decline');
  String get dataConsentAgreeBtn => translate('data_consent_agree_btn');
  String get dataConsentDeclineBtn => translate('data_consent_decline_btn');

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
  
  // Additional Widgets
  String get cashflow => translate('cashflow');
  String get roi => translate('roi');
  String get irr => translate('irr');
  String get taxEstimation => translate('tax_estimation');
  String get upcomingBills => translate('upcoming_bills');
  String get expenseBreakdown => translate('expense_breakdown');
  String get portfolioAllocation => translate('portfolio_allocation');
  String get netWorthTrend => translate('net_worth_trend');
  String get spendingByDay => translate('spending_by_day');
  String get incomeTrend => translate('income_trend');
  String get savingsRate => translate('savings_rate');
  String get myProfile => translate('my_profile');
  String get netCashflow => translate('net_cashflow');
  String get totalIncome => translate('total_income');
  String get totalExpenses => translate('total_expenses');
  String get returnOnInvestment => translate('return_on_investment');
  String get internalRateOfReturn => translate('internal_rate_of_return');
  String get estimatedTax => translate('estimated_tax');
  String get noBillsUpcoming => translate('no_bills_upcoming');
  String get dueDate => translate('due_date');
  String get amount => translate('amount');
  String get paid => translate('paid');
  String get unpaid => translate('unpaid');
  String get totalDue => translate('total_due');
  String get month => translate('month');
  String get year => translate('year');
  String get vietnamesePersonalIncomeTax => translate('vietnamese_personal_income_tax');
  String get taxBreakdown => translate('tax_breakdown');
  String get financialYear => translate('financial_year');
  String get vietnameseTaxBrackets => translate('vietnamese_tax_brackets');
  String get monthlyIncomeRange => translate('monthly_income_range');
  String get rate => translate('rate');
  String get deduction => translate('deduction');
  String get incomeSection => translate('income_section');
  String get annualIncome => translate('annual_income');
  String get monthlyIncome => translate('monthly_income');
  String get deductionsSection => translate('deductions_section');
  String get personalDeduction => translate('personal_deduction');
  String get totalDeductions => translate('total_deductions');
  String get taxableIncomeSection => translate('taxable_income_section');
  String get annualTaxable => translate('annual_taxable');
  String get monthlyTaxable => translate('monthly_taxable');
  String get taxBracket => translate('tax_bracket');
  String get range => translate('range');
  String get taxCalculation => translate('tax_calculation');
  String get monthlyTax => translate('monthly_tax');
  String get annualTax => translate('annual_tax');
  String get effectiveRate => translate('effective_rate');
  String get netIncomeSection => translate('net_income_section');
  String get afterTax => translate('after_tax');
  String get basedOnVietnameseTaxLaw => translate('based_on_vietnamese_tax_law');
  String get estimatedTaxLabel => translate('estimated_tax_label');
  String get currentRoi => translate('current_roi');
  String get currentIrr => translate('current_irr');
  String get clickForDetails => translate('click_for_details');
  
  // Investment Tracking Widget
  String get investments => translate('investments');
  String get portfolio => translate('portfolio');
  String get addInvestment => translate('add_investment');
  String get editInvestment => translate('edit_investment');
  String get deleteInvestment => translate('delete_investment');
  String get valueHistory => translate('value_history');
  String get apiTracked => translate('api_tracked');
  String get currentValue => translate('current_value');
  String get costBasis => translate('cost_basis');
  String get gainLoss => translate('gain_loss');
  String get quantity => translate('quantity');
  String get performanceChart => translate('performance_chart');
  String get totalPortfolioValue => translate('total_portfolio_value');
  String get noInvestmentsYet => translate('no_investments_yet');
  String get errorLoadingData => translate('error_loading_data');
  String get retry => translate('retry');
  String get investmentName => translate('investment_name');
  String get commoditySymbol => translate('commodity_symbol');
  String get trackingType => translate('tracking_type');
  String get initialValue => translate('initial_value');
  String get addValueEntry => translate('add_value_entry');
  String get date => translate('date');
  String get fromCurrency => translate('from_currency');
  String get toCurrency => translate('to_currency');
  String get exchangeRate => translate('exchange_rate');
  String get transactions => translate('transactions');
  String get transactionType => translate('transaction_type');
  String get buy => translate('buy');
  String get sell => translate('sell');
  String get dividend => translate('dividend');
  String get totalInflow => translate('total_inflow');
  String get totalOutflow => translate('total_outflow');
  String get netCashflowInvestment => translate('net_cashflow_investment');
  String get unrealizedGainLoss => translate('unrealized_gain_loss');
  String get percentageReturn => translate('percentage_return');
  String get lastUpdated => translate('last_updated');
  String get refreshPrices => translate('refresh_prices');
  String get deleteConfirmation => translate('delete_confirmation');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get investmentDetails => translate('investment_details');
  String get noTransactionHistoryInvestment => translate('no_transaction_history_investment');
  String get noValueHistory => translate('no_value_history');
  String get addFirstValue => translate('add_first_value');
  String get invalidCommoditySymbol => translate('invalid_commodity_symbol');
  String get invalidExchangeRate => translate('invalid_exchange_rate');
  String get invalidDate => translate('invalid_date');
  String get requiredField => translate('required_field');
  String get investmentAdded => translate('investment_added');
  String get investmentUpdated => translate('investment_updated');
  String get investmentDeleted => translate('investment_deleted');
  String get errorAddingInvestment => translate('error_adding_investment');
  String get errorUpdatingInvestment => translate('error_updating_investment');
  String get errorDeletingInvestment => translate('error_deleting_investment');
  
  // Transaction Detail Dialog
  String get transactionDetails => translate('transaction_details');
  String get payee => translate('payee');
  String get description => translate('description');
  String get type => translate('type');
  String get postings => translate('postings');
  String get account => translate('account');
  String get close => translate('close');

  // Backup
  String get backupSettings => translate('backup_settings');
  String get backupEnabled => translate('backup_enabled');
  String get backupDisabled => translate('backup_disabled');
  String get backupHistory => translate('backup_history');
  String get backupRestore => translate('backup_restore');
  String get backupRestoreConfirm => translate('backup_restore_confirm');
  String get backupUploading => translate('backup_uploading');
  String get backupDownloading => translate('backup_downloading');
  String get backupSuccess => translate('backup_success');
  String get backupFailed => translate('backup_failed');
  String get backupConflictTitle => translate('backup_conflict_title');
  String get backupConflictMessage => translate('backup_conflict_message');
  String get backupConflictOverride => translate('backup_conflict_override');
  String get backupConflictKeepLocal => translate('backup_conflict_keep_local');
  String get backupConflictCancel => translate('backup_conflict_cancel');
  String get backupNoVersions => translate('backup_no_versions');
  String get backupVersionTimestamp => translate('backup_version_timestamp');
  String get backupVersionSize => translate('backup_version_size');
  String get backupErrorNetwork => translate('backup_error_network');
  String get backupErrorCredentials => translate('backup_error_credentials');
  String get backupErrorS3 => translate('backup_error_s3');
  String get backupManualBackup => translate('backup_manual_backup');
  String get backupLastSync => translate('backup_last_sync');
  String get backupFoundTitle => translate('backup_found_title');
  String get backupFoundMessage => translate('backup_found_message');
  String get backupFoundRestore => translate('backup_found_restore');
  String get backupFoundSkip => translate('backup_found_skip');

  // Multi-Dashboard
  String get newDashboard => translate('new_dashboard');
  String get createDashboard => translate('create_dashboard');
  String get dashboardName => translate('dashboard_name');
  String get dashboardNameRequired => translate('dashboard_name_required');
  String get dashboardNameExists => translate('dashboard_name_exists');
  String get startWithDefaults => translate('start_with_defaults');
  String get startEmpty => translate('start_empty');
  String get saveLayout => translate('save_layout');
  String get layoutSaved => translate('layout_saved');
  String get resetDashboard => translate('reset_dashboard');
  String get hardResetDashboard => translate('hard_reset_dashboard');
  String get hardResetWarning => translate('hard_reset_warning');
  String get renameDashboard => translate('rename_dashboard');
  String get deleteDashboard => translate('delete_dashboard');
  String get deleteWarning => translate('delete_warning');
  String get maxDashboardsReached => translate('max_dashboards_reached');
  String get cannotDeleteLast => translate('cannot_delete_last');

  // Sidebar categories & search
  String get searchWidgets => translate('search_widgets');
  String get categoryOverview => translate('category_overview');
  String get categoryAnalytics => translate('category_analytics');
  String get categoryInvestments => translate('category_investments');
  String get categoryTools => translate('category_tools');
  String get addWidget => translate('add_widget');
  String get removeInstance => translate('remove_instance');
  String get addDuplicate => translate('add_duplicate');
  String get maxInstances => translate('max_instances');
  String get widgetCount => translate('widget_count');
  String get widgetsOnDashboard => translate('widgets_on_dashboard');

  // Budget Summary Widget
  String get budgetNoBudgetYet => translate('budget_no_budget_yet');
  String get budgetCreate => translate('budget_create');
  String get budgetBudgeted => translate('budget_budgeted');
  String get budgetSpent => translate('budget_spent');
  String get budgetLeft => translate('budget_left');

  // Budget Settings Sheet
  String get budgetSettings => translate('budget_settings');
  String get budgetPleaseLogin => translate('budget_please_login');
  String get budgetMode => translate('budget_mode');
  String get budgetSpendingLimits => translate('budget_spending_limits');
  String get budgetZeroBased => translate('budget_zero_based');
  String get budgetPeriod => translate('budget_period');
  String get budgetMonthly => translate('budget_monthly');
  String get budgetWeekly => translate('budget_weekly');
  String get budgetBiweekly => translate('budget_biweekly');
  String get budgetCurrencyLabel => translate('budget_currency_label');
  String get budgetCategoriesLabel => translate('budget_categories_label');
  String get budgetAddCategory => translate('budget_add_category');
  String get budgetNotifications => translate('budget_notifications');
  String get budgetRollover => translate('budget_rollover');
  String get budgetCategoryName => translate('budget_category_name');
  String get budgetAccountPattern => translate('budget_account_pattern');
  String get budgetAmount => translate('budget_amount');
  String get budgetCommonCategories => translate('budget_common_categories');
  String get budgetFromTransactions => translate('budget_from_transactions');
  String get budgetOtherCustom => translate('budget_other_custom');
  String get budgetNoActive => translate('budget_no_active');
  String get budgetAdd => translate('budget_add');
  String get budgetSave => translate('budget_save');
  String get budgetDeleteCategory => translate('budget_delete_category');
  String get budgetNoCategories => translate('budget_no_categories');
  String get budgetNoBudgetYetLong => translate('budget_no_budget_yet_long');
  String get budgetMyBudget => translate('budget_my_budget');
  String get budgetSelectCategory => translate('budget_select_category');
  String get budgetAlertThreshold => translate('budget_alert_threshold');
  String get budgetAlertDefault => translate('budget_alert_default');
  String get budgetSuggested => translate('budget_suggested');
  String get budgetNoSuggestions => translate('budget_no_suggestions');
  String get budgetPatternHint => translate('budget_pattern_hint');

  // Category Budget Widget
  String get categoryBudgetTitle => translate('category_budget_title');
  String get budgetOver => translate('budget_over');
  String get budgetApproaching => translate('budget_approaching');
  String get budgetUnbudgeted => translate('budget_unbudgeted');
  String get budgetAddQuick => translate('budget_add_quick');
  String get budgetRolloverBadge => translate('budget_rollover_badge');
  String get budgetPaceWarning => translate('budget_pace_warning');
  String get budgetOf => translate('budget_of');
  String get budgetRemaining => translate('budget_remaining');
  String get budgetOverLabel => translate('budget_over_label');
  String get budgetLeftLabel => translate('budget_left_label');
  String get budgetSpentLabel => translate('budget_spent_label');
  String get budgetRolled => translate('budget_rolled');
  String get budgetBudgetedLabel => translate('budget_budgeted_label');
  String get budgetPace => translate('budget_pace');
  String get budgetEditFor => translate('budget_edit_for');
  String get budgetFor => translate('budget_for');
  String get budgetCurrentSpending => translate('budget_current_spending');
  String get budgetMonthlyAmount => translate('budget_monthly_amount');
  String get budgetSettingsTitle => translate('budget_settings_title');

  // Savings Rate Widget
  String get savingsNoData => translate('savings_no_data');
  String get savingsThisMonth => translate('savings_this_month');
  String get savingsOnTrack => translate('savings_on_track');
  String get savingsAlmostThere => translate('savings_almost_there');
  String get savingsBelowTarget => translate('savings_below_target');
  String get savingsSavedThisMonth => translate('savings_saved_this_month');
  String get savingsProgressLabel => translate('savings_progress_label');
  String get savingsRuleLabel => translate('savings_rule_label');
  String get savingsVsLastMonth => translate('savings_vs_last_month');
  String get savingsIncomeLabel => translate('savings_income_label');
  String get savingsExpensesLabel => translate('savings_expenses_label');
  String get savingsSavedLabel => translate('savings_saved_label');
  String get savingsNoTrendData => translate('savings_no_trend_data');

  // Add Investment Dialog
  String get investmentType => translate('investment_type');
  String get investmentStock => translate('investment_stock');
  String get investmentBond => translate('investment_bond');
  String get investmentCrypto => translate('investment_crypto');
  String get investmentOther => translate('investment_other');
  String get investmentTotalPaid => translate('investment_total_paid');
  String get investmentPurchaseDate => translate('investment_purchase_date');
  String get investmentCurrencyLabel => translate('investment_currency_label');
  String get investmentHowMuch => translate('investment_how_much');
  String get investmentEnterAmount => translate('investment_enter_amount');
  String get investmentEnterQuantity => translate('investment_enter_quantity');
  String get investmentGreaterThanZero => translate('investment_greater_than_zero');
  String get investmentTickerHintStock => translate('investment_ticker_hint_stock');
  String get investmentTickerHintCrypto => translate('investment_ticker_hint_crypto');
  String get investmentTickerHintBond => translate('investment_ticker_hint_bond');
  String get investmentTickerHintOther => translate('investment_ticker_hint_other');
  String get investmentQuantityHint => translate('investment_quantity_hint');

  // Avatar Editor Widget
  String get avatarEdit => translate('avatar_edit');
  String get avatarRotate => translate('avatar_rotate');
  String get avatarZoomIn => translate('avatar_zoom_in');
  String get avatarZoomOut => translate('avatar_zoom_out');
  String get avatarReset => translate('avatar_reset');
  String get avatarSourceTitle => translate('avatar_source_title');
  String get avatarCamera => translate('avatar_camera');
  String get avatarGallery => translate('avatar_gallery');

  // Cash Flow Widget
  String get cashflowSelectYear => translate('cashflow_select_year');

  // Dashboard Screen
  String get widgetPreview => translate('widget_preview');
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
