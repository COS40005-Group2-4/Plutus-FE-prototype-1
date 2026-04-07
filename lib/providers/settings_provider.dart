import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai/insight.dart';
import '../services/ocr_service.dart';

enum AppLanguage {
  english('en', 'English'),
  vietnamese('vi', 'Tiếng Việt');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

enum AppCurrency {
  original('ORIGINAL', '', 'Original Currency'),
  vnd('VND', '₫', 'Vietnamese Dong'),
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro');

  final String code;
  final String symbol;
  final String displayName;
  const AppCurrency(this.code, this.symbol, this.displayName);

  bool get isOriginal => this == AppCurrency.original;

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => AppCurrency.vnd,
    );
  }
}

enum DateFormatType {
  yyyyMMdd('YYYY/MM/DD'),
  ddMMyyyy('DD/MM/YYYY'),
  ddMonthYyyy('DD Month YYYY'),
  mmDDyyyy('MM/DD/YYYY'),
  monthDDyyyy('Month DD, YYYY');

  final String displayName;
  const DateFormatType(this.displayName);

  static DateFormatType fromString(String value) {
    return DateFormatType.values.firstWhere(
      (format) => format.name == value,
      orElse: () => DateFormatType.ddMMyyyy,
    );
  }
}

enum TimeFormatType {
  format24h('24-hour'),
  format12h('12-hour (AM/PM)');

  final String displayName;
  const TimeFormatType(this.displayName);

  static TimeFormatType fromString(String value) {
    return TimeFormatType.values.firstWhere(
      (format) => format.name == value,
      orElse: () => TimeFormatType.format24h,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'date_format';
  static const String _timeFormatKey = 'time_format';
  static const String _ocrModeKey = 'ocr_mode';
  static const String _privacyLevelKey = 'ai_privacy_level';

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  AppCurrency _currency = AppCurrency.vnd;
  DateFormatType _dateFormat = DateFormatType.ddMMyyyy;
  TimeFormatType _timeFormat = TimeFormatType.format24h;
  OCRMode _ocrMode = OCRMode.auto;
  PrivacyLevel _privacyLevel = PrivacyLevel.standard;

  bool _isInitialized = false;
  int _userId = 0;
  String _userKey(String key) => 'user_${_userId}_$key';

  SettingsProvider();

  Future<void> reinitialize(int userId) async {
    _userId = userId;
    _isInitialized = false;
    _themeMode = ThemeMode.system;
    _language = AppLanguage.english;
    _currency = AppCurrency.vnd;
    _dateFormat = DateFormatType.ddMMyyyy;
    _timeFormat = TimeFormatType.format24h;
    _ocrMode = OCRMode.auto;
    _privacyLevel = PrivacyLevel.standard;
    await _loadSettings();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  DateFormatType get dateFormat => _dateFormat;
  TimeFormatType get timeFormat => _timeFormat;
  OCRMode get ocrMode => _ocrMode;
  PrivacyLevel get privacyLevel => _privacyLevel;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  Locale get locale => Locale(_language.code);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_userKey(_themeModeKey));
    if (storedTheme == ThemeMode.dark.name) {
      _themeMode = ThemeMode.dark;
    } else if (storedTheme == ThemeMode.light.name) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    final storedLanguage = prefs.getString(_userKey(_languageKey));
    if (storedLanguage != null) {
      _language = AppLanguage.fromCode(storedLanguage);
    }

    final storedCurrency = prefs.getString(_userKey(_currencyKey));
    if (storedCurrency != null) {
      _currency = AppCurrency.fromCode(storedCurrency);
    }

    final storedDateFormat = prefs.getString(_userKey(_dateFormatKey));
    if (storedDateFormat != null) {
      _dateFormat = DateFormatType.fromString(storedDateFormat);
    }

    final storedTimeFormat = prefs.getString(_userKey(_timeFormatKey));
    if (storedTimeFormat != null) {
      _timeFormat = TimeFormatType.fromString(storedTimeFormat);
    }

    final storedOcrMode = prefs.getString(_userKey(_ocrModeKey));
    if (storedOcrMode != null) {
      _ocrMode = OCRMode.values.firstWhere(
        (mode) => mode.name == storedOcrMode,
        orElse: () => OCRMode.auto,
      );
    }

    final storedPrivacyLevel = prefs.getString(_userKey(_privacyLevelKey));
    if (storedPrivacyLevel != null) {
      _privacyLevel = PrivacyLevel.values.firstWhere(
        (level) => level.name == storedPrivacyLevel,
        orElse: () => PrivacyLevel.standard,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_themeModeKey), mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_languageKey), language.code);
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_currencyKey), currency.code);
    notifyListeners();
  }

  Future<void> setDateFormat(DateFormatType format) async {
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_dateFormatKey), format.name);
    notifyListeners();
  }

  Future<void> setTimeFormat(TimeFormatType format) async {
    _timeFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_timeFormatKey), format.name);
    notifyListeners();
  }

  Future<void> setOcrMode(OCRMode mode) async {
    _ocrMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_ocrModeKey), mode.name);
    notifyListeners();
  }

  Future<void> setPrivacyLevel(PrivacyLevel level) async {
    _privacyLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_privacyLevelKey), level.name);
    notifyListeners();
  }
}
