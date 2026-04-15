import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai/insight.dart';
import '../services/ocr_service.dart';
import 'auth_notifier.dart';
import 'settings_provider.dart'
    show AppLanguage, AppCurrency, DateFormatType, TimeFormatType;

export 'settings_provider.dart'
    show AppLanguage, AppCurrency, DateFormatType, TimeFormatType;

// ---------------------------------------------------------------------------
// SettingsState — immutable value type
// ---------------------------------------------------------------------------

class SettingsState {
  final ThemeMode themeMode;
  final AppLanguage language;
  final AppCurrency currency;
  final DateFormatType dateFormat;
  final TimeFormatType timeFormat;
  final OCRMode ocrMode;
  final PrivacyLevel privacyLevel;
  final bool isInitialized;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.english,
    this.currency = AppCurrency.vnd,
    this.dateFormat = DateFormatType.ddMMyyyy,
    this.timeFormat = TimeFormatType.format24h,
    this.ocrMode = OCRMode.auto,
    this.privacyLevel = PrivacyLevel.standard,
    this.isInitialized = false,
  });

  // Derived getters
  Locale get locale => Locale(language.code);
  bool get isDarkMode => themeMode == ThemeMode.dark;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    AppCurrency? currency,
    DateFormatType? dateFormat,
    TimeFormatType? timeFormat,
    OCRMode? ocrMode,
    PrivacyLevel? privacyLevel,
    bool? isInitialized,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      ocrMode: ocrMode ?? this.ocrMode,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsNotifier
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'date_format';
  static const String _timeFormatKey = 'time_format';
  static const String _ocrModeKey = 'ocr_mode';
  static const String _privacyLevelKey = 'ai_privacy_level';

  String _userKey(int userId, String key) => 'user_${userId}_$key';

  @override
  SettingsState build() {
    final authState = ref.watch(authNotifierProvider);

    if (authState is AuthAuthenticated) {
      // Fire async load without blocking build().
      Future.microtask(() => _loadSettings(authState.user.id));
    }

    return const SettingsState();
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<void> _loadSettings(int userId) async {
    final prefs = await SharedPreferences.getInstance();

    ThemeMode themeMode;
    final storedTheme = prefs.getString(_userKey(userId, _themeModeKey));
    if (storedTheme == ThemeMode.dark.name) {
      themeMode = ThemeMode.dark;
    } else if (storedTheme == ThemeMode.light.name) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.system;
    }

    AppLanguage language = AppLanguage.english;
    final storedLanguage = prefs.getString(_userKey(userId, _languageKey));
    if (storedLanguage != null) {
      language = AppLanguage.fromCode(storedLanguage);
    }

    AppCurrency currency = AppCurrency.vnd;
    final storedCurrency = prefs.getString(_userKey(userId, _currencyKey));
    if (storedCurrency != null) {
      currency = AppCurrency.fromCode(storedCurrency);
    }

    DateFormatType dateFormat = DateFormatType.ddMMyyyy;
    final storedDateFormat = prefs.getString(_userKey(userId, _dateFormatKey));
    if (storedDateFormat != null) {
      dateFormat = DateFormatType.fromString(storedDateFormat);
    }

    TimeFormatType timeFormat = TimeFormatType.format24h;
    final storedTimeFormat = prefs.getString(_userKey(userId, _timeFormatKey));
    if (storedTimeFormat != null) {
      timeFormat = TimeFormatType.fromString(storedTimeFormat);
    }

    OCRMode ocrMode = OCRMode.auto;
    final storedOcrMode = prefs.getString(_userKey(userId, _ocrModeKey));
    if (storedOcrMode != null) {
      ocrMode = OCRMode.values.firstWhere(
        (OCRMode mode) => mode.name == storedOcrMode,
        orElse: () => OCRMode.auto,
      );
    }

    PrivacyLevel privacyLevel = PrivacyLevel.standard;
    final storedPrivacyLevel =
        prefs.getString(_userKey(userId, _privacyLevelKey));
    if (storedPrivacyLevel != null) {
      privacyLevel = PrivacyLevel.values.firstWhere(
        (PrivacyLevel level) => level.name == storedPrivacyLevel,
        orElse: () => PrivacyLevel.standard,
      );
    }

    state = SettingsState(
      themeMode: themeMode,
      language: language,
      currency: currency,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      ocrMode: ocrMode,
      privacyLevel: privacyLevel,
      isInitialized: true,
    );
  }

  // -------------------------------------------------------------------------
  // Public setter methods
  // -------------------------------------------------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _themeModeKey), mode.name);
  }

  Future<void> toggleTheme() async {
    await setThemeMode(state.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _languageKey), language.code);
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = state.copyWith(currency: currency);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _currencyKey), currency.code);
  }

  Future<void> setDateFormat(DateFormatType format) async {
    state = state.copyWith(dateFormat: format);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _dateFormatKey), format.name);
  }

  Future<void> setTimeFormat(TimeFormatType format) async {
    state = state.copyWith(timeFormat: format);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _timeFormatKey), format.name);
  }

  Future<void> setOcrMode(OCRMode mode) async {
    state = state.copyWith(ocrMode: mode);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _ocrModeKey), mode.name);
  }

  Future<void> setPrivacyLevel(PrivacyLevel level) async {
    state = state.copyWith(privacyLevel: level);
    final int? userId = _currentUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(userId, _privacyLevelKey), level.name);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  int? get _currentUserId {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) return authState.user.id;
    return null;
  }
}

// ---------------------------------------------------------------------------
// Provider definition
// ---------------------------------------------------------------------------

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
