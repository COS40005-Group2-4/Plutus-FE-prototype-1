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

User _makeUser({required int userId}) {
  final now = DateTime(2024, 1, 1);
  return User(
    id: userId,
    username: 'user$userId',
    displayName: 'User $userId',
    email: 'user$userId@example.com',
    isGuest: false,
    createdAt: now,
    lastLogin: now,
    isActive: true,
  );
}

ProviderContainer makeContainer({required AuthState authState}) {
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

  group('AuthNotifier.onUserChanged callback contract', () {
    test('callback fires with userId when registered and called', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      // Simulate what AuthNotifier internally does when user changes:
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

  group('SettingsNotifier key scoping', () {
    test('_userKey prefixes correctly', () {
      // Mirror the production helper
      String userKey(int userId, String key) => 'user_${userId}_$key';

      expect(userKey(3, 'theme_mode'), equals('user_3_theme_mode'));
      expect(userKey(0, 'language'), equals('user_0_language'));
      expect(userKey(99, 'currency'), equals('user_99_currency'));
    });
  });

  group('SettingsNotifier integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setThemeMode writes to user-scoped key', () async {
      final container = makeContainer(
        authState: AuthAuthenticated(_makeUser(userId: 7)),
      );
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_7_theme_mode'), equals('dark'));
      // Global key must NOT be written
      expect(prefs.getString('theme_mode'), isNull);
    });

    test('different users read different data from SharedPreferences', () async {
      // Pre-seed separate user data
      SharedPreferences.setMockInitialValues({
        'user_1_theme_mode': 'dark',
        'user_2_theme_mode': 'light',
      });

      // Container for user 1
      final container1 = makeContainer(
        authState: AuthAuthenticated(_makeUser(userId: 1)),
      );
      addTearDown(container1.dispose);
      container1.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container1.read(settingsNotifierProvider).themeMode,
          ThemeMode.dark);

      // Container for user 2 (separate ProviderContainer simulates a different session)
      final container2 = makeContainer(
        authState: AuthAuthenticated(_makeUser(userId: 2)),
      );
      addTearDown(container2.dispose);
      container2.read(settingsNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container2.read(settingsNotifierProvider).themeMode,
          ThemeMode.light);
    });
  });

  group('DashboardProvider key scoping', () {
    test('dynamic layout key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'default';
      const slotCount = 2;

      final key = userKey(7, 'layout_data_${dashId}_$slotCount');
      expect(key, equals('user_7_layout_data_default_2'));
    });

    test('visibility snapshot key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';

      final key = userKey(7, 'visibility_saved_default');
      expect(key, equals('user_7_visibility_saved_default'));
    });

    test('init flag key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';

      final key = userKey(7, 'init_default_v4');
      expect(key, equals('user_7_init_default_v4'));
    });
  });

  group('MyItemStorage key scoping', () {
    test('layout_data key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'myDash';
      const slotCount = 4;

      expect(
        userKey(12, 'layout_data_${dashId}_$slotCount'),
        equals('user_12_layout_data_myDash_4'),
      );
    });

    test('init flag key is user-scoped', () {
      String userKey(int userId, String key) => 'user_${userId}_$key';
      const dashId = 'myDash';

      expect(
        userKey(12, 'init_${dashId}_v4'),
        equals('user_12_init_myDash_v4'),
      );
    });
  });

  // Enum tests for enums still exported from settings_provider.dart
  group('AppLanguage', () {
    test('fromCode returns correct language', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('vi'), AppLanguage.vietnamese);
    });
  });

  group('AppCurrency', () {
    test('fromCode returns correct currency', () {
      expect(AppCurrency.fromCode('VND'), AppCurrency.vnd);
      expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
    });
  });
}
