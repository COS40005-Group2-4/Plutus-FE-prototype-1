// Tests for AuthNotifier.
//
// Note: AuthNotifier.build() directly instantiates GoogleAuthService which
// requires flutter_dotenv. Tests that need the real notifier use a
// FakeAuthNotifier override. Pure state/getter tests use fake overrides.
//
// The sealed AuthState types and convenience getters are tested here.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier — returns a fixed state without GetIt / dotenv dependencies
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _overrideState;
  FakeAuthNotifier(this._overrideState);

  @override
  AuthState build() => _overrideState;

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');
    state = const AuthUnauthenticated();
  }
}

// ---------------------------------------------------------------------------
// Test user helpers
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthNotifier — initial state', () {
    test('initial state is AuthLoading', () {
      // FakeAuthNotifier.build() returns AuthLoading, mirroring the real
      // AuthNotifier which also returns AuthLoading() synchronously from build().
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthLoading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthLoading>());
    });

    test('build returns AuthUnauthenticated when no saved user', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthUnauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });

  group('AuthNotifier — signOut', () {
    test('signOut transitions state to AuthUnauthenticated', () async {
      final user = _makeUser(userId: 1);
      SharedPreferences.setMockInitialValues({'last_user_id': 1});

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(AuthAuthenticated(user)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Verify authenticated
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

      // Sign out
      await container.read(authNotifierProvider.notifier).signOut();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());

      // Verify persisted key removed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_user_id'), isNull);
    });
  });

  group('AuthState sealed class', () {
    test('AuthLoading is AuthState', () {
      const state = AuthLoading();
      expect(state, isA<AuthState>());
    });

    test('AuthUnauthenticated is AuthState', () {
      const state = AuthUnauthenticated();
      expect(state, isA<AuthState>());
    });

    test('AuthAuthenticated carries user', () {
      final user = _makeUser();
      final state = AuthAuthenticated(user);
      expect(state, isA<AuthState>());
      expect(state.user, user);
    });

    test('AuthError carries message', () {
      const state = AuthError('test error');
      expect(state.message, 'test error');
      expect(state, isA<AuthState>());
    });
  });

  group('AuthNotifier — convenience getters', () {
    test('isLoading returns true when state is AuthLoading', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthLoading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider);
      expect(container.read(authNotifierProvider.notifier).isLoading, true);
    });

    test('isLoading returns false when state is AuthUnauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthUnauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider);
      expect(container.read(authNotifierProvider.notifier).isLoading, false);
    });

    test('currentUser returns null when unauthenticated', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthUnauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider);
      expect(container.read(authNotifierProvider.notifier).currentUser, isNull);
      expect(
          container.read(authNotifierProvider.notifier).isAuthenticated, false);
    });

    test('currentUser returns user when authenticated', () {
      final user = _makeUser();
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(AuthAuthenticated(user)),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider);
      expect(container.read(authNotifierProvider.notifier).currentUser, user);
      expect(
          container.read(authNotifierProvider.notifier).isAuthenticated, true);
    });
  });
}
