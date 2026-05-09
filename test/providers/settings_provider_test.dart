// Tests for SettingsNotifier (previously SettingsProvider).
// Migrated from Provider/ChangeNotifier to Riverpod Notifier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';
import 'package:plutus_fe_prototype/providers/settings_notifier.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier — returns a fixed state without GetIt dependencies
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

User _makeUser({int userId = 1}) {
  final now = DateTime(2024, 1, 1);
  return User(
    id: userId,
    username: 'testuser',
    displayName: 'Test User',
    email: 'test@example.com',
    isGuest: false,
    createdAt: now,
    lastLogin: now,
    isActive: true,
  );
}

ProviderContainer _makeContainer({AuthState? authState}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => FakeAuthNotifier(authState ?? const AuthUnauthenticated()),
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier', () {
    test('has correct defaults', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.language, AppLanguage.english);
      expect(state.currency, AppCurrency.vnd);
      expect(state.dateFormat, DateFormatType.ddMMyyyy);
      expect(state.timeFormat, TimeFormatType.format24h);
    });

    test('isDarkMode returns false by default', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsNotifierProvider).isDarkMode, false);
    });

    test('locale returns english locale by default', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsNotifierProvider).locale, const Locale('en'));
    });

    test('setThemeMode persists and notifies', () async {
      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      // Wait for the build() microtask (_loadSettings) to complete first
      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      container.listen(settingsNotifierProvider, (_, _) {
        notified = true;
      });

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);
      expect(notified, true);

      // Verify persisted with user-scoped key
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_theme_mode'), 'dark');
    });

    test('toggleTheme flips between dark and light', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(settingsNotifierProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(settingsNotifierProvider).isDarkMode, false);

      await notifier.toggleTheme();
      expect(container.read(settingsNotifierProvider).themeMode, ThemeMode.dark);

      await notifier.toggleTheme();
      expect(container.read(settingsNotifierProvider).themeMode, ThemeMode.light);
    });

    test('setLanguage persists and updates locale', () async {
      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setLanguage(AppLanguage.vietnamese);

      final state = container.read(settingsNotifierProvider);
      expect(state.language, AppLanguage.vietnamese);
      expect(state.locale, const Locale('vi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_language'), 'vi');
    });

    test('setCurrency persists', () async {
      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setCurrency(AppCurrency.usd);

      expect(container.read(settingsNotifierProvider).currency, AppCurrency.usd);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_currency'), 'USD');
    });

    test('setDateFormat persists', () async {
      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setDateFormat(DateFormatType.yyyyMMdd);

      expect(container.read(settingsNotifierProvider).dateFormat,
          DateFormatType.yyyyMMdd);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_date_format'), 'yyyyMMdd');
    });

    test('setTimeFormat persists', () async {
      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setTimeFormat(TimeFormatType.format12h);

      expect(container.read(settingsNotifierProvider).timeFormat,
          TimeFormatType.format12h);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_time_format'), 'format12h');
    });

    test('loads saved settings when authenticated', () async {
      // Pre-populate SharedPreferences with user-scoped keys
      SharedPreferences.setMockInitialValues({
        'user_1_theme_mode': 'dark',
        'user_1_language': 'vi',
        'user_1_currency': 'USD',
        'user_1_date_format': 'yyyyMMdd',
        'user_1_time_format': 'format12h',
      });

      final container =
          _makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      // Trigger build and wait for microtask to load
      container.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.language, AppLanguage.vietnamese);
      expect(state.currency, AppCurrency.usd);
      expect(state.dateFormat, DateFormatType.yyyyMMdd);
      expect(state.timeFormat, TimeFormatType.format12h);
      expect(state.isInitialized, true);
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
