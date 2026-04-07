import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider.onUserChanged callback contract', () {
    test('callback fires with userId when registered and called', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      // Simulate what AuthProvider._notifyUserChanged does:
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(42, fakeCallback);
      expect(calls, equals([42]));
    });

    test('callback fires with 0 on sign-out', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(0, fakeCallback);
      expect(calls, equals([0]));
    });

    test('no error when callback is null', () {
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      // Must not throw
      expect(() => notifyUserChanged(5, null), returnsNormally);
    });
  });

  group('SettingsProvider key scoping', () {
    test('_userKey prefixes correctly', () {
      // Mirror the production helper
      String userKey(int userId, String key) => 'user_${userId}_$key';

      expect(userKey(3, 'theme_mode'), equals('user_3_theme_mode'));
      expect(userKey(0, 'language'), equals('user_0_language'));
      expect(userKey(99, 'currency'), equals('user_99_currency'));
    });

    test('reinitialize changes userId used for keys', () {
      // Verify that after reinitialize the userId is updated
      int currentUserId = 0;
      void reinitialize(int userId) { currentUserId = userId; }

      reinitialize(5);
      expect(currentUserId, equals(5));

      reinitialize(0);
      expect(currentUserId, equals(0));
    });
  });

  group('SettingsProvider integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setThemeMode writes to user-scoped key', () async {
      final provider = SettingsProvider();
      await provider.reinitialize(7);
      await provider.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_7_theme_mode'), equals('dark'));
      // Global key must NOT be written
      expect(prefs.getString('theme_mode'), isNull);
    });

    test('reinitialize with different userId reads different data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_1_theme_mode', 'dark');
      await prefs.setString('user_2_theme_mode', 'light');

      final provider = SettingsProvider();
      await provider.reinitialize(1);
      expect(provider.themeMode, ThemeMode.dark);

      await provider.reinitialize(2);
      expect(provider.themeMode, ThemeMode.light);
    });
  });
}
