import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/providers/settings_notifier.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier that returns a fixed state — no GetIt dependencies
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}

// ---------------------------------------------------------------------------
// Test helpers
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

ProviderContainer makeContainer({
  AuthState authState = const AuthUnauthenticated(),
}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier — default state', () {
    test('has correct defaults when unauthenticated', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);

      expect(state.themeMode, ThemeMode.system);
      expect(state.language, AppLanguage.english);
      expect(state.currency, AppCurrency.vnd);
      expect(state.dateFormat, DateFormatType.ddMMyyyy);
      expect(state.timeFormat, TimeFormatType.format24h);
    });

    test('isDarkMode returns false by default', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);
      expect(state.isDarkMode, false);
    });

    test('locale returns english locale by default', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsNotifierProvider);
      expect(state.locale, const Locale('en'));
    });
  });

  group('SettingsNotifier — setThemeMode', () {
    test('setThemeMode updates state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.isDarkMode, true);
    });

    test('setThemeMode to light updates isDarkMode', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);
      await notifier.setThemeMode(ThemeMode.light);

      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, ThemeMode.light);
      expect(state.isDarkMode, false);
    });

    test('toggleTheme flips between dark and light', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);
      await notifier.toggleTheme();
      expect(container.read(settingsNotifierProvider).themeMode, ThemeMode.dark);

      await notifier.toggleTheme();
      expect(container.read(settingsNotifierProvider).themeMode, ThemeMode.light);
    });
  });

  group('SettingsNotifier — setLanguage', () {
    test('setLanguage updates state and locale', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setLanguage(AppLanguage.vietnamese);

      final state = container.read(settingsNotifierProvider);
      expect(state.language, AppLanguage.vietnamese);
      expect(state.locale, const Locale('vi'));
    });
  });

  group('SettingsNotifier — setCurrency', () {
    test('setCurrency updates state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setCurrency(AppCurrency.usd);

      final state = container.read(settingsNotifierProvider);
      expect(state.currency, AppCurrency.usd);
    });
  });

  group('SettingsNotifier — persistence when authenticated', () {
    test('setThemeMode persists to SharedPreferences with user-scoped key', () async {
      final container = makeContainer(authState: AuthAuthenticated(_makeUser(userId: 1)));
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_1_theme_mode'), 'dark');
    });

    test('setLanguage persists to SharedPreferences with user-scoped key', () async {
      final container = makeContainer(authState: AuthAuthenticated(_makeUser(userId: 3)));
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setLanguage(AppLanguage.vietnamese);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_3_language'), 'vi');
    });

    test('no persistence when unauthenticated', () async {
      final container = makeContainer(authState: const AuthUnauthenticated());
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_0_theme_mode'), isNull);
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
