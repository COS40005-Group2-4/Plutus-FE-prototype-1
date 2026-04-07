import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/providers/settings_provider.dart';

void main() {
  group('SettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('has correct defaults', () {
      final provider = SettingsProvider();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.language, AppLanguage.english);
      expect(provider.currency, AppCurrency.vnd);
      expect(provider.dateFormat, DateFormatType.ddMMyyyy);
      expect(provider.timeFormat, TimeFormatType.format24h);
    });

    test('isDarkMode returns false by default', () {
      final provider = SettingsProvider();
      expect(provider.isDarkMode, false);
    });

    test('locale returns english locale by default', () {
      final provider = SettingsProvider();
      expect(provider.locale, const Locale('en'));
    });

    test('setThemeMode persists and notifies', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);
      expect(notified, true);

      // Verify persisted with user-scoped key
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_theme_mode'), 'dark');
    });

    test('toggleTheme flips between dark and light', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.isDarkMode, false);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('setLanguage persists and updates locale', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);

      await provider.setLanguage(AppLanguage.vietnamese);

      expect(provider.language, AppLanguage.vietnamese);
      expect(provider.locale, const Locale('vi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_language'), 'vi');
    });

    test('setCurrency persists', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);

      await provider.setCurrency(AppCurrency.usd);

      expect(provider.currency, AppCurrency.usd);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_currency'), 'USD');
    });

    test('setDateFormat persists', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);

      await provider.setDateFormat(DateFormatType.yyyyMMdd);

      expect(provider.dateFormat, DateFormatType.yyyyMMdd);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_date_format'), 'yyyyMMdd');
    });

    test('setTimeFormat persists', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(1);

      await provider.setTimeFormat(TimeFormatType.format12h);

      expect(provider.timeFormat, TimeFormatType.format12h);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_time_format'), 'format12h');
    });

    test('loads saved settings after reinitialize', () async {
      // Pre-populate SharedPreferences with user-scoped keys
      SharedPreferences.setMockInitialValues({
        'user_1_theme_mode': 'dark',
        'user_1_language': 'vi',
        'user_1_currency': 'USD',
        'user_1_date_format': 'yyyyMMdd',
        'user_1_time_format': 'format12h',
      });

      final provider = SettingsProvider();
      await provider.reinitialize(1);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.language, AppLanguage.vietnamese);
      expect(provider.currency, AppCurrency.usd);
      expect(provider.dateFormat, DateFormatType.yyyyMMdd);
      expect(provider.timeFormat, TimeFormatType.format12h);
      expect(provider.isInitialized, true);
    });
  });

  group('AppLanguage', () {
    test('fromCode returns correct language', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('vi'), AppLanguage.vietnamese);
    });

    test('fromCode returns english for unknown code', () {
      expect(AppLanguage.fromCode('xx'), AppLanguage.english);
    });
  });

  group('AppCurrency', () {
    test('fromCode returns correct currency', () {
      expect(AppCurrency.fromCode('VND'), AppCurrency.vnd);
      expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
      expect(AppCurrency.fromCode('EUR'), AppCurrency.eur);
    });

    test('fromCode returns VND for unknown code', () {
      expect(AppCurrency.fromCode('GBP'), AppCurrency.vnd);
    });

    test('isOriginal returns true only for original', () {
      expect(AppCurrency.original.isOriginal, true);
      expect(AppCurrency.vnd.isOriginal, false);
    });
  });

  group('DateFormatType', () {
    test('fromString returns correct format', () {
      expect(DateFormatType.fromString('yyyyMMdd'), DateFormatType.yyyyMMdd);
      expect(DateFormatType.fromString('ddMMyyyy'), DateFormatType.ddMMyyyy);
    });

    test('fromString returns ddMMyyyy for unknown', () {
      expect(DateFormatType.fromString('unknown'), DateFormatType.ddMMyyyy);
    });
  });

  group('TimeFormatType', () {
    test('fromString returns correct format', () {
      expect(TimeFormatType.fromString('format24h'), TimeFormatType.format24h);
      expect(TimeFormatType.fromString('format12h'), TimeFormatType.format12h);
    });

    test('fromString returns 24h for unknown', () {
      expect(TimeFormatType.fromString('unknown'), TimeFormatType.format24h);
    });
  });
}
