import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/interfaces/i_consent_service.dart';
import '../di/service_locator.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------------------------
// Sealed AuthState
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

class AuthNotifier extends Notifier<AuthState> {
  late GoogleAuthService _authService;
  late UserService _userService;
  late IConsentService _consentService;

  @override
  AuthState build() {
    _authService = GoogleAuthService();
    _userService = UserService();
    _consentService = sl<IConsentService>();

    // Kick off async initialization without blocking build().
    _initialize();

    return const AuthLoading();
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// The user currently held in state (null if not authenticated).
  User? get _currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getInt('last_user_id');

      if (lastUserId != null) {
        final user = await _userService.getUserById(lastUserId);
        if (user != null) {
          await _userService.updateLastLogin(user.id);
          state = AuthAuthenticated(user);
        } else {
          state = const AuthUnauthenticated();
        }
      } else {
        state = const AuthUnauthenticated();
      }

      // On web, listen to OAuth authentication state changes.
      if (kIsWeb) {
        _authService.authenticationState.listen((gsi.GoogleSignInCredentials? credentials) async {
          if (credentials != null) {
            await _handleOAuthSignIn();
          } else {
            // Don't clear a local user on OAuth sign-out.
            final current = _currentUser;
            if (current != null && current.hasOAuth) {
              state = const AuthUnauthenticated();
            }
          }
        });
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> _handleOAuthSignIn() async {
    final Map<String, String> userInfo = await _authService.getUserInfo();
    final String email = userInfo['email'] ?? '';
    final String name = userInfo['name'] ?? '';
    final String oauthId = email; // Email is used as the unique OAuth ID.

    // 1. Check if OAuth user already exists (previously linked).
    User? user = await _userService.getUserByOAuth('google', oauthId);

    if (user == null) {
      final User? current = _currentUser;
      if (current != null && !current.hasOAuth) {
        // 2. Currently signed in as local/guest user — link OAuth to them.
        await _userService.linkOAuthToUser(
          userId: current.id,
          provider: 'google',
          oauthId: oauthId,
          email: email,
        );
        user = await _userService.getUserById(current.id);
      } else {
        // 3. No current user — check for a single local/guest user in the DB.
        final List<User> allUsers = await _userService.getAllUsers();
        final List<User> localUsers = allUsers.where((User u) => !u.hasOAuth).toList();
        if (localUsers.length == 1) {
          await _userService.linkOAuthToUser(
            userId: localUsers.first.id,
            provider: 'google',
            oauthId: oauthId,
            email: email,
          );
          user = await _userService.getUserById(localUsers.first.id);
        } else {
          // 4. No linkable user found — create a new OAuth user.
          user = await _userService.createOAuthUser(
            username: email.split('@')[0],
            displayName: name,
            email: email,
            oauthProvider: 'google',
            oauthId: oauthId,
          );
        }
      }
    } else {
      await _userService.updateLastLogin(user.id);
    }

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_user_id', user.id);

    state = AuthAuthenticated(user);
  }

  // -------------------------------------------------------------------------
  // Public methods — auth actions
  // -------------------------------------------------------------------------

  /// Sign in with OAuth (Google).
  Future<bool> signIn() async {
    state = const AuthLoading();

    final bool success = await _authService.signIn();

    if (success) {
      await _handleOAuthSignIn();
    } else {
      // Restore previous unauthenticated state if sign-in was cancelled.
      state = const AuthUnauthenticated();
    }

    return success;
  }

  /// Sign in with an existing local user by username.
  Future<bool> signInWithLocalUser(String username) async {
    state = const AuthLoading();

    try {
      final User? user = await _userService.getUserByUsername(username);

      if (user == null) {
        state = const AuthUnauthenticated();
        return false;
      }

      await _userService.updateLastLogin(user.id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_user_id', user.id);

      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = const AuthUnauthenticated();
      return false;
    }
  }

  /// Create a new local user account.
  Future<bool> createLocalUser(
    String username,
    String displayName, {
    bool isGuest = false,
  }) async {
    state = const AuthLoading();

    try {
      final User user = await _userService.createLocalUser(
        username: username,
        displayName: displayName,
        isGuest: isGuest,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_user_id', user.id);

      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = const AuthUnauthenticated();
      return false;
    }
  }

  /// Link a Google OAuth account to the currently signed-in local user.
  Future<bool> linkOAuthAccount() async {
    final User? current = _currentUser;
    if (current == null || current.hasOAuth) return false;

    state = const AuthLoading();

    try {
      final bool success = await _authService.signIn();

      if (success) {
        final Map<String, String> userInfo = await _authService.getUserInfo();
        final String email = userInfo['email'] ?? '';
        final String oauthId = email;

        await _userService.linkOAuthToUser(
          userId: current.id,
          provider: 'google',
          oauthId: oauthId,
          email: email,
        );

        final User? updated = await _userService.getUserById(current.id);
        if (updated != null) {
          state = AuthAuthenticated(updated);
          return true;
        }
      }

      state = AuthAuthenticated(current);
      return false;
    } catch (e) {
      state = AuthAuthenticated(current);
      return false;
    }
  }

  /// Unlink the Google OAuth account from the currently signed-in user.
  Future<void> unlinkOAuthAccount() async {
    final User? current = _currentUser;
    if (current == null || !current.hasOAuth) return;

    try {
      await _userService.unlinkOAuthFromUser(current.id);
      await _authService.signOut();

      final User? updated = await _userService.getUserById(current.id);
      if (updated != null) {
        state = AuthAuthenticated(updated);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthNotifier: Error unlinking OAuth: $e');
      }
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    final User? current = _currentUser;
    if (current?.hasOAuth == true) {
      await _authService.signOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');

    state = const AuthUnauthenticated();
  }

  /// Manually refresh authentication status (e.g. when coming back online).
  Future<bool> refreshAuthentication() async {
    final User? current = _currentUser;

    try {
      state = const AuthLoading();

      final bool wasAuthenticated = await _authService.isAuthenticated();

      if (wasAuthenticated && current != null) {
        // Reload user from DB to pick up any remote changes.
        final User? refreshed = await _userService.getUserById(current.id);
        state = AuthAuthenticated(refreshed ?? current);
        return true;
      } else {
        state = const AuthUnauthenticated();
        return false;
      }
    } catch (e) {
      // Restore previous state on failure.
      if (current != null) {
        state = AuthAuthenticated(current);
      } else {
        state = const AuthUnauthenticated();
      }
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Data consent helpers
  // -------------------------------------------------------------------------

  /// Whether the current user has given data consent.
  ///
  /// Returns true if:
  ///   - No user is logged in (no consent required).
  ///   - User has no OAuth (offline/guest mode — no consent required).
  ///   - User has OAuth and has previously consented.
  bool get hasDataConsent {
    final User? current = _currentUser;
    if (current == null) return true;
    if (!current.hasOAuth) return true;
    return current.dataConsent;
  }

  /// Persist the user's data consent decision to local SQLite and reload state.
  ///
  /// Callers are responsible for showing the consent dialog (e.g. via
  /// [showDataConsentDialog]) and passing the result here. If [consented] is
  /// false the OAuth account is also unlinked (converting the user to guest
  /// mode).
  Future<void> setDataConsent(bool consented) async {
    final User? current = _currentUser;
    if (current == null) return;

    if (consented) {
      await _userService.setDataConsent(current.id, true);
      final User? updated = await _userService.getUserById(current.id);
      if (updated != null) {
        state = AuthAuthenticated(updated);
      }
    } else {
      await _userService.setDataConsent(current.id, false);
      await unlinkOAuthAccount();
    }
  }

  /// Check data consent against DynamoDB (authoritative), falling back to
  /// local SQLite if offline.
  ///
  /// Returns true if consent is already granted (no dialog needed).
  /// Returns false if the user needs to be prompted.
  ///
  /// This method does NOT show any UI — callers should check the return value
  /// and display the consent dialog themselves, then call [setDataConsent].
  Future<bool> checkDataConsent() async {
    final User? current = _currentUser;
    if (current == null) return true;
    if (!current.hasOAuth) return true;

    final String? email = current.email;
    if (email == null || email.isEmpty) return true;

    // 1. Check DynamoDB first (authoritative source).
    try {
      final bool acceptedRemotely = await _consentService.hasAcceptedTerms(email);
      if (acceptedRemotely) {
        // Sync to local if not already set.
        if (!current.dataConsent) {
          await _userService.setDataConsent(current.id, true);
          final User? updated = await _userService.getUserById(current.id);
          if (updated != null) {
            state = AuthAuthenticated(updated);
          }
        }
        return true;
      }
    } catch (e) {
      // DynamoDB unreachable — fall back to local.
      if (kDebugMode) {
        debugPrint('AuthNotifier: DynamoDB check failed, using local: $e');
      }
      if (current.dataConsent) return true;
    }

    // 2. If local says consented (offline scenario), trust it.
    if (current.dataConsent) return true;

    // 3. Neither remote nor local consent — caller must show dialog.
    return false;
  }

  // -------------------------------------------------------------------------
  // Local T&C helpers
  // -------------------------------------------------------------------------

  /// Returns true if the local T&C dialog has already been shown to this user.
  Future<bool> isLocalTcShown() async {
    final int? userId = _currentUser?.id;
    if (userId == null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_${userId}_tc_shown') ?? false;
  }

  /// Marks the local T&C dialog as shown for the current user.
  Future<void> setLocalTcShown() async {
    final int? userId = _currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_${userId}_tc_shown', true);
  }

  /// Called after the local T&C dialog is dismissed.
  ///
  /// If [agreed] is true, persists data consent to SQLite.
  /// Always marks the dialog as shown so it does not appear again.
  Future<void> handleLocalTcResult(bool agreed) async {
    final User? current = _currentUser;
    if (agreed && current != null) {
      try {
        await _userService.setDataConsent(current.id, true);
        final User? updated = await _userService.getUserById(current.id);
        if (updated != null) {
          state = AuthAuthenticated(updated);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AuthNotifier: Error persisting local T&C consent: $e');
        }
      }
    }
    await setLocalTcShown();
  }

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  /// Get all users stored in the local database.
  Future<List<User>> getAllUsers() async {
    return _userService.getAllUsers();
  }

  /// Get session information from the auth service.
  Future<Map<String, dynamic>> getSessionInfo() async {
    return _authService.getSessionInfo();
  }

  // -------------------------------------------------------------------------
  // Convenience getters
  // -------------------------------------------------------------------------

  /// The currently authenticated [User], or null.
  User? get currentUser => _currentUser;

  /// The ID of the currently authenticated user, or null.
  int? get currentUserId => _currentUser?.id;

  /// True while an auth operation is in progress.
  bool get isLoading => state is AuthLoading;

  /// True when a user is authenticated (OAuth or local, not guest-only).
  bool get isAuthenticated {
    final User? current = _currentUser;
    if (current == null) return false;
    return !current.isGuest || current.hasOAuth;
  }

  /// True when the current user is a guest (no full account).
  bool get isGuest => _currentUser?.isGuest ?? false;

  /// The email of the current user, or an empty string.
  String get userEmail => _currentUser?.email ?? '';

  /// The display name of the current user, or an empty string.
  String get userName => _currentUser?.displayName ?? '';

  /// Direct access to the [GoogleAuthService] (e.g. for web sign-in button).
  GoogleAuthService get authService => _authService;

  /// The OAuth authentication state stream (for web platform).
  Stream<gsi.GoogleSignInCredentials?> get authenticationState =>
      _authService.authenticationState;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
