// Tests for the auth-aware redirect decision in app_router.dart.
//
// The '/' splash route only exists to host a spinner while AuthLoading
// resolves. Once auth resolves — to ANY state — the user must be moved off
// the splash, otherwise they are stuck on a bare CircularProgressIndicator
// forever (the "website loads infinitely" bug).

import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';
import 'package:plutus_fe_prototype/router/app_router.dart';

User _makeUser({int userId = 1}) {
  final DateTime now = DateTime(2024, 1, 1);
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
  group('authRedirect — AuthLoading', () {
    test('stays on splash while auth is resolving', () {
      expect(authRedirect(const AuthLoading(), AppRoutes.splash), isNull);
    });

    test('stays on any route while auth is resolving', () {
      expect(authRedirect(const AuthLoading(), AppRoutes.dashboard), isNull);
    });
  });

  group('authRedirect — AuthUnauthenticated', () {
    test('leaves the splash for user selection once auth resolves', () {
      expect(
        authRedirect(const AuthUnauthenticated(), AppRoutes.splash),
        AppRoutes.userSelection,
      );
    });

    test('stays on user selection', () {
      expect(
        authRedirect(const AuthUnauthenticated(), AppRoutes.userSelection),
        isNull,
      );
    });

    test('stays on login', () {
      expect(
        authRedirect(const AuthUnauthenticated(), AppRoutes.login),
        isNull,
      );
    });

    test('is sent from protected routes to user selection', () {
      expect(
        authRedirect(const AuthUnauthenticated(), AppRoutes.dashboard),
        AppRoutes.userSelection,
      );
      expect(
        authRedirect(const AuthUnauthenticated(), AppRoutes.settings),
        AppRoutes.userSelection,
      );
    });
  });

  group('authRedirect — AuthError', () {
    test('leaves the splash for user selection once auth errors', () {
      expect(
        authRedirect(const AuthError('boom'), AppRoutes.splash),
        AppRoutes.userSelection,
      );
    });

    test('is sent from protected routes to user selection', () {
      expect(
        authRedirect(const AuthError('boom'), AppRoutes.dashboard),
        AppRoutes.userSelection,
      );
    });
  });

  group('authRedirect — AuthAuthenticated', () {
    test('leaves the splash for the dashboard', () {
      expect(
        authRedirect(AuthAuthenticated(_makeUser()), AppRoutes.splash),
        AppRoutes.dashboard,
      );
    });

    test('is sent from auth pages to the dashboard', () {
      expect(
        authRedirect(AuthAuthenticated(_makeUser()), AppRoutes.userSelection),
        AppRoutes.dashboard,
      );
      expect(
        authRedirect(AuthAuthenticated(_makeUser()), AppRoutes.login),
        AppRoutes.dashboard,
      );
    });

    test('stays on protected routes', () {
      expect(
        authRedirect(AuthAuthenticated(_makeUser()), AppRoutes.dashboard),
        isNull,
      );
      expect(
        authRedirect(AuthAuthenticated(_makeUser()), AppRoutes.settings),
        isNull,
      );
    });
  });
}
