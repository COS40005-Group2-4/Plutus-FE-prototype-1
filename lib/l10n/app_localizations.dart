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
