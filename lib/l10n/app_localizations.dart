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
      'add': 'Add',

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
      'tc_title': 'Terms of Use',
      'tc_message': 'By using Plutus, you acknowledge that your financial data is stored locally on this device. You accept responsibility for keeping your device secure. You may export or delete your data at any time.',
      'tc_agree_btn': 'I Agree',
      'tc_decline_btn': 'Decline',

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
      'all': 'All',
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
      'import_from_file': 'Import from File',
      'file_prefix': 'File: ',
      'import_selected': 'Import Selected',
      'imported_count': 'Imported',
      'skipped_count': 'skipped',
      'parse_error': 'Parse error: ',
      'camera': 'Camera',
      'processing_image': 'Processing image...',
      'extracted_fields': 'Extracted Fields',
      'items': 'Items',
      'item': 'Item',
      'confirm_and_save': 'Confirm & Save',
      'could_not_read_image': 'Could not read text from image',
      'ocr_error_prefix': 'OCR error: ',
      'note': 'Note',
      'new_category': 'New Category',
      'category_name_hint': 'Category name',
      'invalid_number': 'Invalid number',

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

      // Export Preview Dialog
      'export_preview': 'Export Preview',
      'file_location': 'File Location',

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
      'net_worth': 'Net worth',
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
      'portfolio_total': 'Portfolio total',
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
      'investment_added': 'added to your portfolio',
      'investment_add_failed': "Couldn't add investment. Please try again.",
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
      'drag_to_move': 'drag to move',

      // Dashboard edit mode (banner, chrome, menu, empty slot)
      'edit_layout': 'Edit layout',
      'edit_mode_banner_title': 'Editing dashboard',
      'edit_mode_banner_subtitle': 'Drag widgets, resize edges, or use the menu.',
      'edit_mode_done': 'Done',
      'edit_mode_action_add': 'Add',
      'edit_mode_action_undo': 'Undo',
      'edit_mode_widget_drag_handle_label': 'Drag to reorder',
      'edit_mode_widget_options_label': 'Widget options',
      'edit_mode_widget_resize_label': 'Resize',
      'edit_mode_widget_semantics':
          'Editable widget. Use the drag handle to move, the corners to resize, or the menu to remove.',
      'edit_mode_menu_rename': 'Rename',
      'edit_mode_menu_duplicate': 'Duplicate',
      'edit_mode_menu_lock': 'Lock position',
      'edit_mode_menu_unlock': 'Unlock position',
      'edit_mode_menu_reset_size': 'Reset size',
      'edit_mode_menu_remove': 'Remove',
      'edit_mode_empty_slot_label': 'Add widget',
      'edit_mode_action_unavailable': 'This action is coming soon.',

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
      'error_creating_budget': 'Error creating budget: ',
      'in_three_months': 'in 3 months',

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
      'avatar_save_failed': 'Failed to save avatar: ',
      'image_pick_error': 'Error picking image: ',

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
      'widget_label_insights_feed': 'Insights Feed',
      'widget_label_health_score': 'Financial Health Score',
      'widget_label_cash_flow_forecast': 'Cash Flow Forecast',
      'widget_label_coaching_tips': 'Coaching Tips',

      // ── Widget Help Tooltips ──
      'widget_help_profile': 'Your account overview and personal details.',
      'widget_help_budget': 'Tracks how much you\'ve spent vs. your set budget.',
      'widget_help_category_budget': 'Shows spending limits for each category.',
      'widget_help_savings_rate': 'The percentage of income you\'re saving.',
      'widget_help_net_worth_trend': 'Your total assets minus debts over time.',
      'widget_help_transaction_history': 'A log of all your recent transactions.',
      'widget_help_cashflow': 'Shows money coming in vs. going out this month.',
      'widget_help_expense_breakdown': 'Where your money is going, split by category.',
      'widget_help_income_trend': 'How your income has changed over time.',
      'widget_help_spending_heatmap': 'Highlights your heaviest spending days.',
      'widget_help_tax_estimation': 'An estimate of your tax based on income and expenses.',
      'widget_help_investments': 'Overview of your investment portfolio value.',
      'widget_help_portfolio_allocation': 'How your investments are spread across assets.',
      'widget_help_roi': 'The profit or loss on your investments as a percentage.',
      'widget_help_irr': 'Your investment\'s annualised growth rate.',
      'widget_help_market_trending': 'Current market movements and trending assets.',
      'widget_help_bills': 'Bills and payments due soon.',
      'widget_help_import': 'Import transactions from a file.',
      'widget_help_export': 'Export your data to a file.',
      'widget_help_insights_feed': 'Personalised tips based on your spending habits.',
      'widget_help_health_score': 'An overall score of your financial wellbeing.',
      'widget_help_cashflow_forecast': 'Predicts your cash flow for the coming weeks.',
      'widget_help_coaching_tips': 'Actionable advice to improve your finances.',

      // ── Widget Catalog Category Labels ──
      'widget_cat_overview': 'Overview',
      'widget_cat_analytics': 'Analytics',
      'widget_cat_investments': 'Investments',
      'widget_cat_tools': 'Tools',
      'widget_cat_insights': 'Insights',

      // ── Dashboard Screen ──
      'widget_preview': 'Widget Preview',

      // ── Financial Insights & Coaching ──
      'insights_title': 'Financial Insights',
      'insights_tab_spending': 'Spending',
      'insights_tab_forecast': 'Forecast',
      'insights_tab_alerts': 'Alerts',
      'insights_tab_coaching': 'Coaching',
      'insights_generate': 'Generate Insights',
      'insights_generating': 'Generating insights...',
      'insights_analyzing_spending': 'Analyzing spending patterns...',
      'insights_generating_forecast': 'Generating forecast...',
      'insights_generating_coaching': 'Generating coaching tips...',
      'insights_last_generated': 'Last generated',
      'insights_empty': 'No insights yet',
      'insights_empty_subtitle': 'Tap Generate Insights to get started',
      'insights_error': 'Could not generate insights',
      'insights_retry': 'Retry',
      'insights_import_banner': 'New transactions imported. Generate fresh insights?',
      'insights_import_banner_action': 'Generate',
      'insights_health_score': 'Financial Health Score',
      'insights_health_score_empty': 'Generate insights to see your score',
      'insights_savings_rate': 'Savings Rate',
      'insights_budget_adherence': 'Budget Adherence',
      'insights_spending_consistency': 'Spending Consistency',
      'insights_expense_to_income': 'Expense to Income',
      'insights_forecast_title': 'Cash Flow Forecast',
      'insights_forecast_empty': 'Generate insights for forecast',
      'insights_forecast_projected': 'Projected balance',
      'insights_forecast_optimistic': 'Best case',
      'insights_forecast_likely': 'Likely',
      'insights_forecast_pessimistic': 'Worst case',
      'insights_alerts_empty': 'No alerts',
      'insights_alerts_mark_read': 'Mark all as read',
      'insights_coaching_empty': 'Generate insights for personalized tips',
      'insights_coaching_save': 'Save',
      'insights_coaching_dismiss': 'Dismiss',
      'insights_coaching_saved': 'Tip saved',
      'insights_coaching_difficulty_easy': 'Easy',
      'insights_coaching_difficulty_medium': 'Medium',
      'insights_coaching_difficulty_hard': 'Hard',
      'insights_coaching_potential_savings': 'Potential savings',
      'insights_privacy_minimal': 'Minimal',
      'insights_privacy_standard': 'Standard',
      'insights_privacy_full': 'Full',

      // Insights period selector
      'insights_period_label': 'Analysis Period',
      'insights_period_1m': '1M',
      'insights_period_3m': '3M',
      'insights_period_6m': '6M',
      'insights_period_1y': '1Y',
      'insights_period_custom': 'Custom',
      'insights_period_custom_active': 'Custom Range',
      'insights_font_size_label': 'Text Size',
      'textSizeIncrease': 'Increase text size',
      'textSizeDecrease': 'Decrease text size',

      // Report Export
      'report_config_title': 'Generate Report',
      'report_choose_template': 'Choose a Template',
      'report_date_range': 'Date Range',
      'report_sections': 'Sections',
      'report_audience': 'Audience',
      'report_ai_recommendations': 'AI Recommendations',
      'report_section_template': 'Template',
      'report_section_date_range': 'Date range',
      'report_section_sections': 'Sections',
      'report_section_audience': 'Audience',
      'report_generate': 'Generate Report',
      'report_generating': 'Generating...',
      'report_preview_title': 'Report Preview',
      'report_export_pdf': 'Export PDF',
      'report_template_quick_summary': 'Quick Summary',
      'report_template_quick_summary_desc': 'Key metrics at a glance',
      'report_template_monthly_review': 'Monthly Review',
      'report_template_monthly_review_desc': 'Comprehensive monthly analysis',
      'report_template_full_review': 'Full Financial Review',
      'report_template_full_review_desc': 'All sections included',
      'report_template_tax_prep': 'Tax Prep',
      'report_template_tax_prep_desc': 'Income and expense details for tax',
      'report_template_investment_focus': 'Investment Focus',
      'report_template_investment_focus_desc': 'Portfolio and forecast analysis',

      // Settings — Offline Access
      'settings_offline_access': 'Offline Access',
      'settings_offline_days_remaining': 'You can use Plutus offline for \$days more days',
      'settings_offline_message': "You're using Plutus offline. We'll verify your account when you reconnect.",

      // Settings — AI & OCR
      'settings_ai_ocr': 'AI & OCR',
      'settings_scanning_mode': 'Scanning Mode',
      'settings_ai_data_privacy': 'AI Data Privacy',
      'settings_ocr_auto': 'Auto (recommended)',
      'settings_ocr_online': 'Online only',
      'settings_ocr_offline': 'Offline only',
      'settings_ocr_auto_desc': 'Picks the best OCR engine automatically based on connectivity',
      'settings_ocr_online_desc': 'Uses AWS Textract (requires internet)',
      'settings_ocr_offline_desc': 'Uses Tesseract/ML Kit (no internet needed)',
      'settings_privacy_minimal': 'Minimal — category totals only',
      'settings_privacy_standard': 'Standard (recommended)',
      'settings_privacy_full': 'Full — individual transactions',
      'settings_privacy_minimal_desc': 'Only sends category totals to AI — most private, basic insights',
      'settings_privacy_standard_desc': 'Sends category totals and top merchants — good balance of privacy and insight quality',
      'settings_privacy_full_desc': 'Sends individual transactions — richest, most personalized insights',

      // Settings — Account
      'settings_backup_subtitle': 'Back up your data and sync across devices',
      'settings_link_dialog': 'Connect your Google account to back up your data and access it on any device.',
      'settings_link_account': 'Link Account',
      'settings_local_subtitle': 'Store data on this device only',
      'settings_unlink_dialog': 'This will disconnect your Google account. Your data will remain on this device.',
      'settings_unlink': 'Unlink',
      'settings_google_connected': 'Google account connected!',
      'settings_google_disconnected': 'Google account disconnected',
      'settings_google_error': "Couldn't connect your Google account",
      'settings_guest_message': 'Sign in to back up your data and access it from any device.',

      // Export Dialog
      'export_data': 'Export Data',
      'export_format': 'Export Format',
      'export_content': 'Export Content',
      'export_date_range_optional': 'Date Range (Optional)',
      'export_cancel': 'Cancel',
      'export_pdf': 'PDF',
      'export_pdf_desc': 'Professional format',
      'export_txt': 'TXT',
      'export_txt_desc': 'Plain text format',
      'export_transactions': 'Transaction History',
      'export_user_data': 'User Data',
      'export_both': 'Both',
      'export_start_date': 'Start Date',
      'export_end_date': 'End Date',
      'export_all': 'All',
      'export_clear_range': 'Clear Date Range',
      'export_error': 'Error preparing export',

      // Report Config
      'report_tpl_quick': 'Quick Summary',
      'report_tpl_monthly': 'Monthly Review',
      'report_tpl_full': 'Full Review',
      'report_tpl_tax': 'Tax Prep',
      'report_tpl_investments': 'Investments',
      'report_preset_this_month': 'This Month',
      'report_preset_last_quarter': 'Last Quarter',
      'report_preset_ytd': 'Year to Date',
      'report_preset_last_12m': 'Last 12 Months',
      'report_preset_custom': 'Custom',
      'report_audience_personal': 'Personal',
      'report_audience_professional': 'Professional',
      'report_ai_title': 'AI Recommendations',
      'report_ai_subtitle': 'Add AI-powered insights to each section',
      'report_generating_loading': 'Generating report...',
      'report_language': 'Report Language',
      'report_language_desc': 'Language used in the exported report',

      // Report Section Names
      'report_sec_cover': 'Cover Page',
      'report_sec_summary': 'Executive Summary',
      'report_sec_spending': 'Spending Breakdown',
      'report_sec_income': 'Income Analysis',
      'report_sec_cashflow': 'Cash Flow',
      'report_sec_budget': 'Budget vs Actual',
      'report_sec_merchants': 'Top Merchants',
      'report_sec_investments': 'Investments',
      'report_sec_forecast': 'Forecast',
      'report_sec_alerts': 'Alerts',
      'report_sec_coaching': 'Coaching Tips',
      'report_sec_bills': 'Bills & Recurring',
      'report_sec_transactions': 'Transaction Log',

      // Report Preview
      'report_preview': 'Report Preview',
      'report_share': 'Share',
      'report_share_soon': 'Share feature coming soon',
      'report_no_data': 'No report data',
      'report_no_data_subtitle': 'Configure and generate a report first.',
      'report_pdf_saved': 'PDF saved to',
      'report_pdf_failed': 'PDF export failed',
      'error_prefix': 'Error: ',

      // Report Content — Cover & Summary
      'report_financial_report': 'Financial Report',
      'report_personal_finance_report': 'Personal Finance Report',
      'report_key_metrics': 'KEY METRICS',
      'report_prepared_for': 'PREPARED FOR',
      'report_generated_on': 'Generated on',
      'report_generated_prefix': 'Generated ',
      'report_metric': 'Metric',
      'report_value': 'Value',
      'report_total_income': 'Total Income',
      'report_total_expenses': 'Total Expenses',
      'report_net_savings': 'Net Savings',
      'report_savings_rate': 'Savings Rate',
      'report_transactions': 'Transactions',
      'report_health_score': 'Health Score',
      'report_summary_desc': 'Here\'s a snapshot of your financial health this period. Each metric is compared against the previous period to help you track progress.',
      'report_net_savings_desc': 'The difference between your total income and expenses. A positive number means you saved money.',
      'report_savings_rate_desc': 'The percentage of income you kept as savings. Financial advisors recommend at least 20%.',
      'report_transactions_desc': 'Total number of recorded transactions this period.',
      'report_health_score_desc': 'An overall measure of your financial health from 0 to 100, based on savings, consistency, and spending patterns.',

      // Report Content — Table Headers
      'report_col_category': 'CATEGORY',
      'report_col_amount': 'AMOUNT',
      'report_col_percent': '%',
      'report_col_mom': 'MOM',
      'report_col_date': 'DATE',
      'report_col_payee': 'PAYEE',
      'report_col_account': 'ACCOUNT',
      'report_col_budget': 'Budget',
      'report_col_actual': 'Actual',
      'report_col_used': 'Used',
      'report_col_status': 'Status',
      'report_col_name': 'Name',
      'report_col_frequency': 'Frequency',
      'report_col_next_due': 'Next Due',
      'report_col_ticker': 'Ticker',
      'report_col_alloc': 'Alloc%',
      'report_col_return': 'Return%',
      'report_col_txns': 'Txns',
      'report_col_description': 'Description',
      'report_col_type': 'Type',

      // Report Content — Cash Flow
      'report_inflow': 'INFLOW',
      'report_outflow': 'OUTFLOW',
      'report_net': 'NET',
      'report_positive_cashflow': 'Positive cash flow — you saved more than you spent.',
      'report_negative_cashflow': 'Negative cash flow — expenses exceeded income.',

      // Report Content — Income
      'report_vs_prev_period': 'vs prev period',
      'report_income_sources': 'Income Sources',
      'report_previous_period': 'Previous Period',
      'report_change': 'Change',
      'report_total_inflows': 'Total Inflows',
      'report_total_outflows': 'Total Outflows',
      'report_net_cashflow': 'Net Cash Flow',

      // Report Content — Budget
      'report_budget_used': '% of budget used',
      'report_over': 'OVER',
      'report_ok': 'OK',

      // Report Content — Investments
      'report_total_value': 'TOTAL VALUE',

      // Report Content — Bills
      'report_monthly_recurring': 'Monthly recurring',
      'report_active': 'active',
      'report_total_recurring': 'Total Recurring',
      'report_active_bills': 'Active Bills',

      // Report Content — Coaching
      'report_financial_coaching': 'Financial Coaching',
      'report_difficulty_easy': 'EASY',
      'report_difficulty_medium': 'MEDIUM',
      'report_difficulty_hard': 'HARD',
      'report_potential_savings': 'Potential savings',
      'report_per_month': '/mo',
      'report_est_savings': 'Est. savings',

      // Report Content — AI
      'report_ai_insight': 'AI Insight',
      'report_show_analysis': 'Show detailed analysis',

      // Report Content — Empty States
      'report_no_spending_data': 'No spending data available',
      'report_no_income_data': 'No income source breakdown available',
      'report_no_budget_data': 'No budget data available',
      'report_no_merchant_data': 'No merchant data available',
      'report_no_investment_data': 'No portfolio data available',
      'report_no_forecast_data': 'No forecast data available',
      'report_no_alerts': 'No alerts for this period.',
      'report_no_coaching': 'No coaching tips available',
      'report_no_bills_data': 'No recurring bills data available',
      'report_no_transactions': 'No transactions available',

      // Export Service Content
      'export_user_information': 'User Information',
      'export_user_id': 'User ID',
      'export_username': 'Username',
      'export_display_name': 'Display Name',
      'export_email': 'Email',
      'export_account_type': 'Account Type',
      'export_guest': 'Guest',
      'export_registered': 'Registered',
      'export_oauth_provider': 'OAuth Provider',
      'export_account_created': 'Account Created',
      'export_last_login': 'Last Login',
      'export_status': 'Status',
      'export_active': 'Active',
      'export_inactive': 'Inactive',
      'export_transaction_summary': 'Transaction Summary',
      'export_transaction_details': 'Transaction Details',
      'export_period': 'Period',
      'export_total_transactions': 'Total Transactions',
      'export_total_expenses': 'Total Expenses',
      'export_total_income': 'Total Income',
      'export_net_amount': 'Net Amount',
      'export_expense': 'Expense',
      'export_income': 'Income',
      'export_end_of_report': 'End of Report',
      'export_page_of': 'Page \$page of \$total',
      'export_showing_first': 'showing first',

      // Investment tracking — manual price points, sales, closed positions
      'investment_tab_active': 'Active',
      'investment_tab_closed': 'Closed',
      'investment_no_closed': 'No closed positions yet.',
      'investment_update_value': 'Update value',
      'investment_update_value_subtitle': 'Record what this asset is worth right now.',
      'investment_value_date': 'Date',
      'investment_value_price': 'Price per unit',
      'investment_value_note': 'Note (optional)',
      'investment_value_saved': 'Value updated',
      'investment_sell': 'Sell',
      'investment_sell_title': 'Sell investment',
      'investment_sell_quantity': 'Quantity to sell',
      'investment_sell_price_per_unit': 'Sale price per unit',
      'investment_sell_date': 'Sale date',
      'investment_sell_destination': 'Cash account',
      'investment_sell_notes': 'Notes (optional)',
      'investment_sell_proceeds': 'Proceeds',
      'investment_sell_realized_gain': 'Realised gain',
      'investment_sell_realized_loss': 'Realised loss',
      'investment_sell_remaining': 'Remaining quantity',
      'investment_sell_oversell': 'You only hold {qty} of this asset.',
      'investment_sell_confirm': 'Confirm sale',
      'investment_sale_recorded': 'Sale recorded',
      'investment_view_transaction': 'View transaction',
      'investment_metric_roi': 'ROI',
      'investment_metric_xirr': 'XIRR',
      'investment_metric_held_under_year': 'Held under 1 year — annualised IRR not shown',
      'investment_metric_irr_unavailable': 'IRR unavailable',
      'investment_avg_unit_cost': 'Avg unit cost',
      'investment_current_value': 'Current value',
      'investment_quantity_held': 'Quantity held',
      'investment_price_history_title': 'Manual valuations',
      'investment_price_history_empty': 'No manual valuations yet. Add one to track this asset over time.',
      'investment_sales_title': 'Sales history',
      'investment_sales_empty': 'No sales yet.',
      'investment_closed_on': 'Closed on {date}',
      'investment_select_cash_account': 'Select cash account',

      // Auth surface (login + user selection)
      'tagline': 'Where wealth gathers.',
      'loginWelcome': 'Welcome to Plutus',
      'loginSubtitle': 'Track spending, budgets, and investments in one place.',
      'loginFailedGoogle': 'Sign-in failed. Please check your Google account and try again.',
      'signInWithGoogle': 'Sign in with Google',
      'createProfile': 'Create a Profile',
      'usernameLabel': 'Username',
      'usernameHint': 'Choose a username',
      'displayNameLabel': 'Display Name',
      'displayNameHint': 'Your display name',
      'fillAllFields': 'Please fill in all fields to continue',
      'usernameTaken': "Couldn't create your account. That username may already be taken.",
      'switchProfile': 'Switch Profile',
      'whosUsingPlutus': "Who's using Plutus?",
      'noProfilesFound': 'No profiles found',
      'createProfileToStart': 'Create a profile to get started',
      'googleBadge': 'Google',
      'guestBadge': 'Guest',
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
      'add': 'Thêm',

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
      'tc_title': 'Điều khoản sử dụng',
      'tc_message': 'Bằng cách sử dụng Plutus, bạn xác nhận rằng dữ liệu tài chính của bạn được lưu trữ cục bộ trên thiết bị này. Bạn chấp nhận trách nhiệm bảo mật thiết bị của mình. Bạn có thể xuất hoặc xóa dữ liệu của mình bất kỳ lúc nào.',
      'tc_agree_btn': 'Tôi đồng ý',
      'tc_decline_btn': 'Từ chối',

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
      'all': 'Tất cả',
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
      'import_from_file': 'Nhập từ tệp',
      'file_prefix': 'Tệp: ',
      'import_selected': 'Nhập mục đã chọn',
      'imported_count': 'Đã nhập',
      'skipped_count': 'bị bỏ qua',
      'parse_error': 'Lỗi phân tích: ',
      'camera': 'Máy ảnh',
      'processing_image': 'Đang xử lý ảnh...',
      'extracted_fields': 'Trường đã trích xuất',
      'items': 'Mục',
      'item': 'Mục',
      'confirm_and_save': 'Xác nhận & Lưu',
      'could_not_read_image': 'Không thể đọc chữ từ ảnh',
      'ocr_error_prefix': 'Lỗi OCR: ',
      'note': 'Ghi chú',
      'new_category': 'Danh mục mới',
      'category_name_hint': 'Tên danh mục',
      'invalid_number': 'Số không hợp lệ',

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

      // Export Preview Dialog
      'export_preview': 'Xem trước bản xuất',
      'file_location': 'Vị trí tệp',

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
      'continue_as_guest': 'Tiếp tục với tư cách Khách',
      
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
      'net_worth': 'Tài sản ròng',
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
      'portfolio_total': 'Tổng danh mục',
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
      'investment_added': 'đã thêm vào danh mục của bạn',
      'investment_add_failed': 'Không thể thêm khoản đầu tư. Vui lòng thử lại.',
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
      'drag_to_move': 'kéo để di chuyển',

      // Dashboard edit mode (banner, chrome, menu, empty slot)
      'edit_layout': 'Chỉnh sửa bố cục',
      'edit_mode_banner_title': 'Đang chỉnh sửa bảng điều khiển',
      'edit_mode_banner_subtitle': 'Kéo thẻ, chỉnh kích thước cạnh, hoặc dùng menu.',
      'edit_mode_done': 'Hoàn tất',
      'edit_mode_action_add': 'Thêm',
      'edit_mode_action_undo': 'Hoàn tác',
      'edit_mode_widget_drag_handle_label': 'Kéo để sắp xếp lại',
      'edit_mode_widget_options_label': 'Tùy chọn thẻ',
      'edit_mode_widget_resize_label': 'Đổi kích thước',
      'edit_mode_widget_semantics':
          'Thẻ có thể chỉnh sửa. Dùng tay cầm để di chuyển, các góc để đổi kích thước, hoặc menu để xóa.',
      'edit_mode_menu_rename': 'Đổi tên',
      'edit_mode_menu_duplicate': 'Nhân bản',
      'edit_mode_menu_lock': 'Khóa vị trí',
      'edit_mode_menu_unlock': 'Mở khóa vị trí',
      'edit_mode_menu_reset_size': 'Đặt lại kích thước',
      'edit_mode_menu_remove': 'Xóa',
      'edit_mode_empty_slot_label': 'Thêm thẻ',
      'edit_mode_action_unavailable': 'Tính năng này sắp ra mắt.',

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
      'error_creating_budget': 'Lỗi khi tạo ngân sách: ',
      'in_three_months': 'trong 3 tháng',

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
      'avatar_save_failed': 'Không thể lưu ảnh đại diện: ',
      'image_pick_error': 'Lỗi khi chọn ảnh: ',

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
      'widget_label_insights_feed': 'Bảng tin phân tích',
      'widget_label_health_score': 'Điểm sức khỏe tài chính',
      'widget_label_cash_flow_forecast': 'Dự báo dòng tiền',
      'widget_label_coaching_tips': 'Lời khuyên tài chính',

      // ── Widget Help Tooltips ──
      'widget_help_profile': 'Tổng quan tài khoản và thông tin cá nhân của bạn.',
      'widget_help_budget': 'Theo dõi chi tiêu so với ngân sách đã đặt.',
      'widget_help_category_budget': 'Hiển thị hạn mức chi tiêu cho từng danh mục.',
      'widget_help_savings_rate': 'Phần trăm thu nhập bạn đang tiết kiệm.',
      'widget_help_net_worth_trend': 'Tổng tài sản trừ nợ theo thời gian.',
      'widget_help_transaction_history': 'Danh sách các giao dịch gần đây.',
      'widget_help_cashflow': 'Tiền vào so với tiền ra trong tháng này.',
      'widget_help_expense_breakdown': 'Tiền của bạn đang đi đâu, chia theo danh mục.',
      'widget_help_income_trend': 'Thu nhập của bạn thay đổi theo thời gian.',
      'widget_help_spending_heatmap': 'Nổi bật những ngày chi tiêu nhiều nhất.',
      'widget_help_tax_estimation': 'Ước tính thuế dựa trên thu nhập và chi tiêu.',
      'widget_help_investments': 'Tổng quan giá trị danh mục đầu tư.',
      'widget_help_portfolio_allocation': 'Đầu tư của bạn được phân bổ ra sao.',
      'widget_help_roi': 'Lãi hoặc lỗ trên khoản đầu tư tính theo phần trăm.',
      'widget_help_irr': 'Tỷ lệ tăng trưởng hàng năm của khoản đầu tư.',
      'widget_help_market_trending': 'Biến động thị trường và tài sản đang hot.',
      'widget_help_bills': 'Các hóa đơn và khoản thanh toán sắp đến hạn.',
      'widget_help_import': 'Nhập giao dịch từ tệp.',
      'widget_help_export': 'Xuất dữ liệu ra tệp.',
      'widget_help_insights_feed': 'Mẹo cá nhân dựa trên thói quen chi tiêu.',
      'widget_help_health_score': 'Điểm tổng quan về sức khỏe tài chính.',
      'widget_help_cashflow_forecast': 'Dự đoán dòng tiền trong những tuần tới.',
      'widget_help_coaching_tips': 'Lời khuyên thiết thực để cải thiện tài chính.',

      // ── Widget Catalog Category Labels ──
      'widget_cat_overview': 'Tổng quan',
      'widget_cat_analytics': 'Phân tích',
      'widget_cat_investments': 'Đầu tư',
      'widget_cat_tools': 'Công cụ',
      'widget_cat_insights': 'Phân tích AI',

      // ── Dashboard Screen ──
      'widget_preview': 'Xem trước widget',

      // ── Financial Insights & Coaching ──
      'insights_title': 'Phân tích tài chính',
      'insights_tab_spending': 'Chi tiêu',
      'insights_tab_forecast': 'Dự báo',
      'insights_tab_alerts': 'Cảnh báo',
      'insights_tab_coaching': 'Lời khuyên',
      'insights_generate': 'Phân tích ngay',
      'insights_generating': 'Đang phân tích...',
      'insights_analyzing_spending': 'Đang phân tích chi tiêu...',
      'insights_generating_forecast': 'Đang tạo dự báo...',
      'insights_generating_coaching': 'Đang tạo lời khuyên...',
      'insights_last_generated': 'Lần phân tích gần nhất',
      'insights_empty': 'Chưa có phân tích',
      'insights_empty_subtitle': 'Nhấn Phân tích ngay để bắt đầu',
      'insights_error': 'Không thể tạo phân tích',
      'insights_retry': 'Thử lại',
      'insights_import_banner': 'Đã nhập giao dịch mới. Phân tích lại?',
      'insights_import_banner_action': 'Phân tích',
      'insights_health_score': 'Điểm sức khỏe tài chính',
      'insights_health_score_empty': 'Phân tích để xem điểm của bạn',
      'insights_savings_rate': 'Tỷ lệ tiết kiệm',
      'insights_budget_adherence': 'Tuân thủ ngân sách',
      'insights_spending_consistency': 'Chi tiêu ổn định',
      'insights_expense_to_income': 'Chi phí trên thu nhập',
      'insights_forecast_title': 'Dự báo dòng tiền',
      'insights_forecast_empty': 'Phân tích để xem dự báo',
      'insights_forecast_projected': 'Số dư dự kiến',
      'insights_forecast_optimistic': 'Khả quan nhất',
      'insights_forecast_likely': 'Có khả năng',
      'insights_forecast_pessimistic': 'Kém nhất',
      'insights_alerts_empty': 'Không có cảnh báo',
      'insights_alerts_mark_read': 'Đánh dấu đã đọc',
      'insights_coaching_empty': 'Phân tích để nhận lời khuyên cá nhân',
      'insights_coaching_save': 'Lưu',
      'insights_coaching_dismiss': 'Bỏ qua',
      'insights_coaching_saved': 'Đã lưu lời khuyên',
      'insights_coaching_difficulty_easy': 'Dễ',
      'insights_coaching_difficulty_medium': 'Trung bình',
      'insights_coaching_difficulty_hard': 'Khó',
      'insights_coaching_potential_savings': 'Tiết kiệm tiềm năng',
      'insights_privacy_minimal': 'Tối thiểu',
      'insights_privacy_standard': 'Tiêu chuẩn',
      'insights_privacy_full': 'Đầy đủ',

      // Insights period selector
      'insights_period_label': 'Kỳ phân tích',
      'insights_period_1m': '1T',
      'insights_period_3m': '3T',
      'insights_period_6m': '6T',
      'insights_period_1y': '1N',
      'insights_period_custom': 'Tùy chỉnh',
      'insights_period_custom_active': 'Khoảng tùy chỉnh',
      'insights_font_size_label': 'Cỡ chữ',
      'textSizeIncrease': 'Tăng cỡ chữ',
      'textSizeDecrease': 'Giảm cỡ chữ',

      // Report Export
      'report_config_title': 'Tạo Báo Cáo',
      'report_choose_template': 'Chọn Mẫu Báo Cáo',
      'report_date_range': 'Khoảng Thời Gian',
      'report_sections': 'Các Phần',
      'report_audience': 'Đối Tượng',
      'report_ai_recommendations': 'Đề Xuất AI',
      'report_section_template': 'Mẫu báo cáo',
      'report_section_date_range': 'Khoảng thời gian',
      'report_section_sections': 'Các mục',
      'report_section_audience': 'Đối tượng',
      'report_generate': 'Tạo Báo Cáo',
      'report_generating': 'Đang tạo...',
      'report_preview_title': 'Xem Trước Báo Cáo',
      'report_export_pdf': 'Xuất PDF',
      'report_template_quick_summary': 'Tóm Tắt Nhanh',
      'report_template_quick_summary_desc': 'Các chỉ số chính trong nháy mắt',
      'report_template_monthly_review': 'Đánh Giá Tháng',
      'report_template_monthly_review_desc': 'Phân tích hàng tháng toàn diện',
      'report_template_full_review': 'Đánh Giá Tài Chính Đầy Đủ',
      'report_template_full_review_desc': 'Bao gồm tất cả các phần',
      'report_template_tax_prep': 'Chuẩn Bị Thuế',
      'report_template_tax_prep_desc': 'Chi tiết thu nhập và chi phí cho thuế',
      'report_template_investment_focus': 'Tập Trung Đầu Tư',
      'report_template_investment_focus_desc': 'Phân tích danh mục và dự báo',

      // Settings — Offline Access
      'settings_offline_access': 'Truy cập ngoại tuyến',
      'settings_offline_days_remaining': 'Bạn có thể dùng Plutus ngoại tuyến thêm \$days ngày nữa',
      'settings_offline_message': 'Bạn đang dùng Plutus ngoại tuyến. Chúng tôi sẽ xác minh tài khoản khi bạn kết nối lại.',

      // Settings — AI & OCR
      'settings_ai_ocr': 'AI & OCR',
      'settings_scanning_mode': 'Chế độ quét',
      'settings_ai_data_privacy': 'Quyền riêng tư dữ liệu AI',
      'settings_ocr_auto': 'Tự động (khuyến nghị)',
      'settings_ocr_online': 'Chỉ trực tuyến',
      'settings_ocr_offline': 'Chỉ ngoại tuyến',
      'settings_ocr_auto_desc': 'Tự động chọn công cụ OCR tốt nhất dựa trên kết nối',
      'settings_ocr_online_desc': 'Sử dụng AWS Textract (cần internet)',
      'settings_ocr_offline_desc': 'Sử dụng Tesseract/ML Kit (không cần internet)',
      'settings_privacy_minimal': 'Tối thiểu — chỉ tổng theo danh mục',
      'settings_privacy_standard': 'Tiêu chuẩn (khuyến nghị)',
      'settings_privacy_full': 'Đầy đủ — giao dịch chi tiết',
      'settings_privacy_minimal_desc': 'Chỉ gửi tổng theo danh mục cho AI — riêng tư nhất, phân tích cơ bản',
      'settings_privacy_standard_desc': 'Gửi tổng danh mục và đối tác hàng đầu — cân bằng giữa riêng tư và chất lượng phân tích',
      'settings_privacy_full_desc': 'Gửi giao dịch chi tiết — phân tích phong phú và cá nhân hóa nhất',

      // Settings — Account
      'settings_backup_subtitle': 'Sao lưu dữ liệu và đồng bộ giữa các thiết bị',
      'settings_link_dialog': 'Kết nối tài khoản Google để sao lưu dữ liệu và truy cập trên mọi thiết bị.',
      'settings_link_account': 'Liên kết tài khoản',
      'settings_local_subtitle': 'Lưu dữ liệu chỉ trên thiết bị này',
      'settings_unlink_dialog': 'Thao tác này sẽ ngắt kết nối tài khoản Google. Dữ liệu của bạn vẫn còn trên thiết bị.',
      'settings_unlink': 'Hủy liên kết',
      'settings_google_connected': 'Đã kết nối tài khoản Google!',
      'settings_google_disconnected': 'Đã ngắt kết nối tài khoản Google',
      'settings_google_error': 'Không thể kết nối tài khoản Google',
      'settings_guest_message': 'Đăng nhập để sao lưu dữ liệu và truy cập từ mọi thiết bị.',

      // Export Dialog
      'export_data': 'Xuất dữ liệu',
      'export_format': 'Định dạng xuất',
      'export_content': 'Nội dung xuất',
      'export_date_range_optional': 'Khoảng thời gian (Tùy chọn)',
      'export_cancel': 'Hủy',
      'export_pdf': 'PDF',
      'export_pdf_desc': 'Định dạng chuyên nghiệp',
      'export_txt': 'TXT',
      'export_txt_desc': 'Văn bản thuần',
      'export_transactions': 'Lịch sử giao dịch',
      'export_user_data': 'Dữ liệu người dùng',
      'export_both': 'Cả hai',
      'export_start_date': 'Ngày bắt đầu',
      'export_end_date': 'Ngày kết thúc',
      'export_all': 'Tất cả',
      'export_clear_range': 'Xóa khoảng thời gian',
      'export_error': 'Lỗi khi xuất dữ liệu',

      // Report Config
      'report_tpl_quick': 'Tóm tắt nhanh',
      'report_tpl_monthly': 'Đánh giá hàng tháng',
      'report_tpl_full': 'Đánh giá đầy đủ',
      'report_tpl_tax': 'Chuẩn bị thuế',
      'report_tpl_investments': 'Đầu tư',
      'report_preset_this_month': 'Tháng này',
      'report_preset_last_quarter': 'Quý trước',
      'report_preset_ytd': 'Từ đầu năm',
      'report_preset_last_12m': '12 tháng qua',
      'report_preset_custom': 'Tùy chỉnh',
      'report_audience_personal': 'Cá nhân',
      'report_audience_professional': 'Chuyên nghiệp',
      'report_ai_title': 'Đề xuất AI',
      'report_ai_subtitle': 'Thêm phân tích AI vào mỗi phần',
      'report_generating_loading': 'Đang tạo báo cáo...',
      'report_language': 'Ngôn ngữ báo cáo',
      'report_language_desc': 'Ngôn ngữ sử dụng trong báo cáo xuất ra',

      // Report Section Names
      'report_sec_cover': 'Trang bìa',
      'report_sec_summary': 'Tóm tắt tổng quan',
      'report_sec_spending': 'Phân tích chi tiêu',
      'report_sec_income': 'Phân tích thu nhập',
      'report_sec_cashflow': 'Dòng tiền',
      'report_sec_budget': 'Ngân sách so với thực tế',
      'report_sec_merchants': 'Đối tác hàng đầu',
      'report_sec_investments': 'Đầu tư',
      'report_sec_forecast': 'Dự báo',
      'report_sec_alerts': 'Cảnh báo',
      'report_sec_coaching': 'Mẹo tài chính',
      'report_sec_bills': 'Hóa đơn & Định kỳ',
      'report_sec_transactions': 'Nhật ký giao dịch',

      // Report Preview
      'report_preview': 'Xem trước báo cáo',
      'report_share': 'Chia sẻ',
      'report_share_soon': 'Tính năng chia sẻ sắp ra mắt',
      'report_no_data': 'Chưa có dữ liệu báo cáo',
      'report_no_data_subtitle': 'Cấu hình và tạo báo cáo trước.',
      'report_pdf_saved': 'PDF đã lưu tại',
      'report_pdf_failed': 'Xuất PDF thất bại',
      'error_prefix': 'Lỗi: ',

      // Report Content — Cover & Summary
      'report_financial_report': 'Báo Cáo Tài Chính',
      'report_personal_finance_report': 'Báo Cáo Tài Chính Cá Nhân',
      'report_key_metrics': 'CHỈ SỐ CHÍNH',
      'report_prepared_for': 'CHUẨN BỊ CHO',
      'report_generated_on': 'Tạo ngày',
      'report_generated_prefix': 'Tạo lúc ',
      'report_metric': 'Chỉ số',
      'report_value': 'Giá trị',
      'report_total_income': 'Tổng thu nhập',
      'report_total_expenses': 'Tổng chi phí',
      'report_net_savings': 'Tiết kiệm ròng',
      'report_savings_rate': 'Tỷ lệ tiết kiệm',
      'report_transactions': 'Giao dịch',
      'report_health_score': 'Điểm sức khỏe tài chính',
      'report_summary_desc': 'Đây là tổng quan sức khỏe tài chính của bạn trong kỳ này. Mỗi chỉ số được so sánh với kỳ trước để giúp bạn theo dõi tiến trình.',
      'report_net_savings_desc': 'Chênh lệch giữa tổng thu nhập và chi phí. Số dương nghĩa là bạn đã tiết kiệm được tiền.',
      'report_savings_rate_desc': 'Phần trăm thu nhập bạn giữ lại. Các chuyên gia khuyến nghị ít nhất 20%.',
      'report_transactions_desc': 'Tổng số giao dịch được ghi nhận trong kỳ này.',
      'report_health_score_desc': 'Thước đo tổng thể sức khỏe tài chính từ 0 đến 100, dựa trên tiết kiệm, tính nhất quán và mô hình chi tiêu.',

      // Report Content — Table Headers
      'report_col_category': 'DANH MỤC',
      'report_col_amount': 'SỐ TIỀN',
      'report_col_percent': '%',
      'report_col_mom': 'SO THÁNG',
      'report_col_date': 'NGÀY',
      'report_col_payee': 'NGƯỜI NHẬN',
      'report_col_account': 'TÀI KHOẢN',
      'report_col_budget': 'Ngân sách',
      'report_col_actual': 'Thực tế',
      'report_col_used': 'Đã dùng',
      'report_col_status': 'Trạng thái',
      'report_col_name': 'Tên',
      'report_col_frequency': 'Tần suất',
      'report_col_next_due': 'Đến hạn',
      'report_col_ticker': 'Mã CK',
      'report_col_alloc': 'Phân bổ%',
      'report_col_return': 'Lợi nhuận%',
      'report_col_txns': 'Số GD',
      'report_col_description': 'Mô tả',
      'report_col_type': 'Loại',

      // Report Content — Cash Flow
      'report_inflow': 'THU VÀO',
      'report_outflow': 'CHI RA',
      'report_net': 'RÒNG',
      'report_positive_cashflow': 'Dòng tiền dương — bạn tiết kiệm được nhiều hơn chi tiêu.',
      'report_negative_cashflow': 'Dòng tiền âm — chi phí vượt quá thu nhập.',

      // Report Content — Income
      'report_vs_prev_period': 'so với kỳ trước',
      'report_income_sources': 'Nguồn thu nhập',
      'report_previous_period': 'Kỳ trước',
      'report_change': 'Thay đổi',
      'report_total_inflows': 'Tổng thu vào',
      'report_total_outflows': 'Tổng chi ra',
      'report_net_cashflow': 'Dòng tiền ròng',

      // Report Content — Budget
      'report_budget_used': '% ngân sách đã dùng',
      'report_over': 'VƯỢT',
      'report_ok': 'OK',

      // Report Content — Investments
      'report_total_value': 'TỔNG GIÁ TRỊ',

      // Report Content — Bills
      'report_monthly_recurring': 'Định kỳ hàng tháng',
      'report_active': 'hoạt động',
      'report_total_recurring': 'Tổng định kỳ',
      'report_active_bills': 'Hóa đơn đang hoạt động',

      // Report Content — Coaching
      'report_financial_coaching': 'Tư Vấn Tài Chính',
      'report_difficulty_easy': 'DỄ',
      'report_difficulty_medium': 'TRUNG BÌNH',
      'report_difficulty_hard': 'KHÓ',
      'report_potential_savings': 'Tiết kiệm tiềm năng',
      'report_per_month': '/tháng',
      'report_est_savings': 'Ước tính tiết kiệm',

      // Report Content — AI
      'report_ai_insight': 'Phân Tích AI',
      'report_show_analysis': 'Xem phân tích chi tiết',

      // Report Content — Empty States
      'report_no_spending_data': 'Không có dữ liệu chi tiêu',
      'report_no_income_data': 'Không có phân tích nguồn thu nhập',
      'report_no_budget_data': 'Không có dữ liệu ngân sách',
      'report_no_merchant_data': 'Không có dữ liệu đối tác',
      'report_no_investment_data': 'Không có dữ liệu danh mục đầu tư',
      'report_no_forecast_data': 'Không có dữ liệu dự báo',
      'report_no_alerts': 'Không có cảnh báo trong kỳ này.',
      'report_no_coaching': 'Không có mẹo tài chính',
      'report_no_bills_data': 'Không có dữ liệu hóa đơn định kỳ',
      'report_no_transactions': 'Không có giao dịch',

      // Export Service Content
      'export_user_information': 'Thông tin người dùng',
      'export_user_id': 'Mã người dùng',
      'export_username': 'Tên đăng nhập',
      'export_display_name': 'Tên hiển thị',
      'export_email': 'Email',
      'export_account_type': 'Loại tài khoản',
      'export_guest': 'Khách',
      'export_registered': 'Đã đăng ký',
      'export_oauth_provider': 'Nhà cung cấp OAuth',
      'export_account_created': 'Ngày tạo tài khoản',
      'export_last_login': 'Đăng nhập cuối',
      'export_status': 'Trạng thái',
      'export_active': 'Hoạt động',
      'export_inactive': 'Không hoạt động',
      'export_transaction_summary': 'Tóm tắt giao dịch',
      'export_transaction_details': 'Chi tiết giao dịch',
      'export_period': 'Kỳ',
      'export_total_transactions': 'Tổng giao dịch',
      'export_total_expenses': 'Tổng chi phí',
      'export_total_income': 'Tổng thu nhập',
      'export_net_amount': 'Số tiền ròng',
      'export_expense': 'Chi phí',
      'export_income': 'Thu nhập',
      'export_end_of_report': 'Kết thúc báo cáo',
      'export_page_of': 'Trang \$page / \$total',
      'export_showing_first': 'hiển thị',

      // Investment tracking — manual price points, sales, closed positions
      'investment_tab_active': 'Đang nắm giữ',
      'investment_tab_closed': 'Đã đóng',
      'investment_no_closed': 'Chưa có vị thế đã đóng nào.',
      'investment_update_value': 'Cập nhật giá trị',
      'investment_update_value_subtitle': 'Ghi nhận giá trị hiện tại của tài sản này.',
      'investment_value_date': 'Ngày',
      'investment_value_price': 'Giá mỗi đơn vị',
      'investment_value_note': 'Ghi chú (tùy chọn)',
      'investment_value_saved': 'Đã cập nhật giá trị',
      'investment_sell': 'Bán',
      'investment_sell_title': 'Bán tài sản',
      'investment_sell_quantity': 'Số lượng cần bán',
      'investment_sell_price_per_unit': 'Giá bán mỗi đơn vị',
      'investment_sell_date': 'Ngày bán',
      'investment_sell_destination': 'Tài khoản tiền',
      'investment_sell_notes': 'Ghi chú (tùy chọn)',
      'investment_sell_proceeds': 'Số tiền nhận',
      'investment_sell_realized_gain': 'Lãi đã ghi nhận',
      'investment_sell_realized_loss': 'Lỗ đã ghi nhận',
      'investment_sell_remaining': 'Số lượng còn lại',
      'investment_sell_oversell': 'Bạn chỉ nắm giữ {qty} của tài sản này.',
      'investment_sell_confirm': 'Xác nhận bán',
      'investment_sale_recorded': 'Đã ghi nhận giao dịch bán',
      'investment_view_transaction': 'Xem giao dịch',
      'investment_metric_roi': 'ROI',
      'investment_metric_xirr': 'XIRR',
      'investment_metric_held_under_year': 'Nắm giữ dưới 1 năm — chưa hiển thị IRR năm hóa',
      'investment_metric_irr_unavailable': 'Không tính được IRR',
      'investment_avg_unit_cost': 'Giá vốn TB',
      'investment_current_value': 'Giá trị hiện tại',
      'investment_quantity_held': 'Số lượng nắm giữ',
      'investment_price_history_title': 'Định giá thủ công',
      'investment_price_history_empty': 'Chưa có định giá thủ công nào. Thêm một mục để theo dõi tài sản theo thời gian.',
      'investment_sales_title': 'Lịch sử bán',
      'investment_sales_empty': 'Chưa có giao dịch bán.',
      'investment_closed_on': 'Đã đóng vào {date}',
      'investment_select_cash_account': 'Chọn tài khoản tiền',

      // Auth surface (login + user selection)
      'tagline': 'Nơi tài sản sinh sôi.',
      'loginWelcome': 'Chào mừng đến với Plutus',
      'loginSubtitle': 'Theo dõi chi tiêu, ngân sách và đầu tư ở cùng một nơi.',
      'loginFailedGoogle': 'Đăng nhập thất bại. Vui lòng kiểm tra tài khoản Google và thử lại.',
      'signInWithGoogle': 'Đăng nhập bằng Google',
      'createProfile': 'Tạo hồ sơ',
      'usernameLabel': 'Tên đăng nhập',
      'usernameHint': 'Chọn tên đăng nhập',
      'displayNameLabel': 'Tên hiển thị',
      'displayNameHint': 'Tên hiển thị của bạn',
      'fillAllFields': 'Vui lòng điền đầy đủ thông tin để tiếp tục',
      'usernameTaken': 'Không thể tạo tài khoản. Tên đăng nhập có thể đã tồn tại.',
      'switchProfile': 'Chuyển hồ sơ',
      'whosUsingPlutus': 'Ai đang dùng Plutus?',
      'noProfilesFound': 'Không tìm thấy hồ sơ nào',
      'createProfileToStart': 'Tạo hồ sơ để bắt đầu',
      'googleBadge': 'Google',
      'guestBadge': 'Khách',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  /// Translate a key for an arbitrary locale without needing BuildContext.
  /// Used by services (PDF, export) that don't have widget context.
  static String translateForLocale(String languageCode, String key) {
    return _localizedValues[languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
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
  String get add => translate('add');

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
  String get tcTitle => translate('tc_title');
  String get tcMessage => translate('tc_message');
  String get tcAgreeBtn => translate('tc_agree_btn');
  String get tcDeclineBtn => translate('tc_decline_btn');

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
  String get all => translate('all');
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
  String get importFromFile => translate('import_from_file');
  String get filePrefix => translate('file_prefix');
  String get importSelected => translate('import_selected');
  String get importedCount => translate('imported_count');
  String get skippedCount => translate('skipped_count');
  String get parseError => translate('parse_error');
  String get camera => translate('camera');
  String get processingImage => translate('processing_image');
  String get extractedFields => translate('extracted_fields');
  String get items => translate('items');
  String get item => translate('item');
  String get confirmAndSave => translate('confirm_and_save');
  String get couldNotReadImage => translate('could_not_read_image');
  String get ocrErrorPrefix => translate('ocr_error_prefix');
  String get note => translate('note');
  String get newCategory => translate('new_category');
  String get categoryNameHint => translate('category_name_hint');
  String get invalidNumber => translate('invalid_number');

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

  // Export Preview Dialog
  String get exportPreview => translate('export_preview');
  String get fileLocation => translate('file_location');

  // Report Preview
  String get errorPrefix => translate('error_prefix');

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
  String get netWorth => translate('net_worth');
  String get spendingByDay => translate('spending_by_day');
  String get incomeTrend => translate('income_trend');
  String get savingsRate => translate('savings_rate');
  String get myProfile => translate('my_profile');
  String get netCashflow => translate('net_cashflow');
  String get totalIncome => translate('total_income');
  String get totalExpenses => translate('total_expenses');
  String get returnOnInvestment => translate('return_on_investment');
  String get internalRateOfReturn => translate('internal_rate_of_return');

  // Widget Help Tooltips
  String get widgetHelpProfile => translate('widget_help_profile');
  String get widgetHelpBudget => translate('widget_help_budget');
  String get widgetHelpCategoryBudget => translate('widget_help_category_budget');
  String get widgetHelpSavingsRate => translate('widget_help_savings_rate');
  String get widgetHelpNetWorthTrend => translate('widget_help_net_worth_trend');
  String get widgetHelpTransactionHistory => translate('widget_help_transaction_history');
  String get widgetHelpCashflow => translate('widget_help_cashflow');
  String get widgetHelpExpenseBreakdown => translate('widget_help_expense_breakdown');
  String get widgetHelpIncomeTrend => translate('widget_help_income_trend');
  String get widgetHelpSpendingHeatmap => translate('widget_help_spending_heatmap');
  String get widgetHelpTaxEstimation => translate('widget_help_tax_estimation');
  String get widgetHelpInvestments => translate('widget_help_investments');
  String get widgetHelpPortfolioAllocation => translate('widget_help_portfolio_allocation');
  String get widgetHelpRoi => translate('widget_help_roi');
  String get widgetHelpIrr => translate('widget_help_irr');
  String get widgetHelpMarketTrending => translate('widget_help_market_trending');
  String get widgetHelpBills => translate('widget_help_bills');
  String get widgetHelpImport => translate('widget_help_import');
  String get widgetHelpExport => translate('widget_help_export');
  String get widgetHelpInsightsFeed => translate('widget_help_insights_feed');
  String get widgetHelpHealthScore => translate('widget_help_health_score');
  String get widgetHelpCashflowForecast => translate('widget_help_cashflow_forecast');
  String get widgetHelpCoachingTips => translate('widget_help_coaching_tips');
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
  String get portfolioTotal => translate('portfolio_total');
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
  String get investmentAddFailed => translate('investment_add_failed');
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
  String get dragToMove => translate('drag_to_move');

  // Dashboard edit mode
  String get editLayout => translate('edit_layout');
  String get editModeBannerTitle => translate('edit_mode_banner_title');
  String get editModeBannerSubtitle => translate('edit_mode_banner_subtitle');
  String get editModeDone => translate('edit_mode_done');
  String get editModeActionAdd => translate('edit_mode_action_add');
  String get editModeActionUndo => translate('edit_mode_action_undo');
  String get editModeWidgetDragHandleLabel =>
      translate('edit_mode_widget_drag_handle_label');
  String get editModeWidgetOptionsLabel =>
      translate('edit_mode_widget_options_label');
  String get editModeWidgetResizeLabel =>
      translate('edit_mode_widget_resize_label');
  String get editModeWidgetSemantics =>
      translate('edit_mode_widget_semantics');
  String get editModeMenuRename => translate('edit_mode_menu_rename');
  String get editModeMenuDuplicate => translate('edit_mode_menu_duplicate');
  String get editModeMenuLock => translate('edit_mode_menu_lock');
  String get editModeMenuUnlock => translate('edit_mode_menu_unlock');
  String get editModeMenuResetSize => translate('edit_mode_menu_reset_size');
  String get editModeMenuRemove => translate('edit_mode_menu_remove');
  String get editModeEmptySlotLabel => translate('edit_mode_empty_slot_label');
  String get editModeActionUnavailable =>
      translate('edit_mode_action_unavailable');

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
  String get errorCreatingBudget => translate('error_creating_budget');
  String get inThreeMonths => translate('in_three_months');

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
  String get avatarSaveFailed => translate('avatar_save_failed');
  String get imagePickError => translate('image_pick_error');

  // Cash Flow Widget
  String get cashflowSelectYear => translate('cashflow_select_year');

  // Dashboard Screen
  String get widgetPreview => translate('widget_preview');

  // Financial Insights & Coaching
  String get insightsTitle => translate('insights_title');
  String get insightsTabSpending => translate('insights_tab_spending');
  String get insightsTabForecast => translate('insights_tab_forecast');
  String get insightsTabAlerts => translate('insights_tab_alerts');
  String get insightsTabCoaching => translate('insights_tab_coaching');
  String get insightsGenerate => translate('insights_generate');
  String get insightsGenerating => translate('insights_generating');
  String get insightsLastGenerated => translate('insights_last_generated');
  String get insightsEmpty => translate('insights_empty');
  String get insightsEmptySubtitle => translate('insights_empty_subtitle');
  String get insightsError => translate('insights_error');
  String get insightsRetry => translate('insights_retry');
  String get insightsImportBanner => translate('insights_import_banner');
  String get insightsImportBannerAction => translate('insights_import_banner_action');
  String get insightsHealthScore => translate('insights_health_score');
  String get insightsHealthScoreEmpty => translate('insights_health_score_empty');
  String get insightsForecastTitle => translate('insights_forecast_title');
  String get insightsForecastEmpty => translate('insights_forecast_empty');
  String get insightsForecastProjected => translate('insights_forecast_projected');
  String get insightsForecastOptimistic => translate('insights_forecast_optimistic');
  String get insightsForecastLikely => translate('insights_forecast_likely');
  String get insightsForecastPessimistic => translate('insights_forecast_pessimistic');
  String get insightsAlertsEmpty => translate('insights_alerts_empty');
  String get insightsAlertsMarkRead => translate('insights_alerts_mark_read');
  String get insightsCoachingEmpty => translate('insights_coaching_empty');
  String get insightsCoachingSave => translate('insights_coaching_save');
  String get insightsCoachingDismiss => translate('insights_coaching_dismiss');
  String get insightsCoachingSaved => translate('insights_coaching_saved');
  String get insightsCoachingPotentialSavings => translate('insights_coaching_potential_savings');
  String get insightsPeriodLabel => translate('insights_period_label');
  String get insightsPeriod1m => translate('insights_period_1m');
  String get insightsPeriod3m => translate('insights_period_3m');
  String get insightsPeriod6m => translate('insights_period_6m');
  String get insightsPeriod1y => translate('insights_period_1y');
  String get insightsPeriodCustom => translate('insights_period_custom');
  String get insightsPeriodCustomActive => translate('insights_period_custom_active');
  String get insightsFontSizeLabel => translate('insights_font_size_label');
  String get textSizeIncrease => translate('textSizeIncrease');
  String get textSizeDecrease => translate('textSizeDecrease');

  // Investment tracking
  String get investmentTabActive => translate('investment_tab_active');
  String get investmentTabClosed => translate('investment_tab_closed');
  String get investmentNoClosed => translate('investment_no_closed');
  String get investmentUpdateValue => translate('investment_update_value');
  String get investmentUpdateValueSubtitle => translate('investment_update_value_subtitle');
  String get investmentValueDate => translate('investment_value_date');
  String get investmentValuePrice => translate('investment_value_price');
  String get investmentValueNote => translate('investment_value_note');
  String get investmentValueSaved => translate('investment_value_saved');
  String get investmentSell => translate('investment_sell');
  String get investmentSellTitle => translate('investment_sell_title');
  String get investmentSellQuantity => translate('investment_sell_quantity');
  String get investmentSellPricePerUnit => translate('investment_sell_price_per_unit');
  String get investmentSellDate => translate('investment_sell_date');
  String get investmentSellDestination => translate('investment_sell_destination');
  String get investmentSellNotes => translate('investment_sell_notes');
  String get investmentSellProceeds => translate('investment_sell_proceeds');
  String get investmentSellRealizedGain => translate('investment_sell_realized_gain');
  String get investmentSellRealizedLoss => translate('investment_sell_realized_loss');
  String get investmentSellRemaining => translate('investment_sell_remaining');
  String investmentSellOversell(String qty) =>
      translate('investment_sell_oversell').replaceAll('{qty}', qty);
  String get investmentSellConfirm => translate('investment_sell_confirm');
  String get investmentSaleRecorded => translate('investment_sale_recorded');
  String get investmentViewTransaction => translate('investment_view_transaction');
  String get investmentMetricRoi => translate('investment_metric_roi');
  String get investmentMetricXirr => translate('investment_metric_xirr');
  String get investmentMetricHeldUnderYear => translate('investment_metric_held_under_year');
  String get investmentMetricIrrUnavailable => translate('investment_metric_irr_unavailable');
  String get investmentAvgUnitCost => translate('investment_avg_unit_cost');
  String get investmentCurrentValue => translate('investment_current_value');
  String get investmentQuantityHeld => translate('investment_quantity_held');
  String get investmentPriceHistoryTitle => translate('investment_price_history_title');
  String get investmentPriceHistoryEmpty => translate('investment_price_history_empty');
  String get investmentSalesTitle => translate('investment_sales_title');
  String get investmentSalesEmpty => translate('investment_sales_empty');
  String investmentClosedOn(String date) =>
      translate('investment_closed_on').replaceAll('{date}', date);
  String get investmentSelectCashAccount => translate('investment_select_cash_account');

  // Auth surface (login + user selection)
  String get tagline => translate('tagline');
  String get loginWelcome => translate('loginWelcome');
  String get loginSubtitle => translate('loginSubtitle');
  String get loginFailedGoogle => translate('loginFailedGoogle');
  String get signInWithGoogle => translate('signInWithGoogle');
  String get createProfile => translate('createProfile');
  String get usernameLabel => translate('usernameLabel');
  String get usernameHint => translate('usernameHint');
  String get displayNameLabel => translate('displayNameLabel');
  String get displayNameHint => translate('displayNameHint');
  String get fillAllFields => translate('fillAllFields');
  String get usernameTaken => translate('usernameTaken');
  String get switchProfile => translate('switchProfile');
  String get whosUsingPlutus => translate('whosUsingPlutus');
  String get noProfilesFound => translate('noProfilesFound');
  String get createProfileToStart => translate('createProfileToStart');
  String get googleBadge => translate('googleBadge');
  String get guestBadge => translate('guestBadge');

  String get reportGeneratedPrefix => translate('report_generated_prefix');
  String get noRecurringBills => translate('report_no_bills_data');
  String get monthlyRecurring => translate('report_monthly_recurring');
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
