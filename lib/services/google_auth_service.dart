import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../config/google_oauth_config.dart';

// Conditional import for web/non-web helper
import 'web_helper_stub.dart'
    if (dart.library.js_util) 'web_helper_web.dart'
    if (dart.library.html) 'web_helper_web.dart';

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn;
  static const String _userInfoKey = 'google_user_info';
  static const String _accessTokenKey = 'google_access_token';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _lastVerifiedKey = 'last_verified';
  bool _isHandlingCallback = false;
  
  // Session stays valid for 30 days without online verification
  static const Duration _sessionDuration = Duration(days: 30);
  // Re-verify token every 7 days when online
  static const Duration _verificationInterval = Duration(days: 7);

  GoogleAuthService() {
    // Determine the correct Client ID and Secret based on platform.
    String clientId;
    String clientSecret;

    if (kIsWeb) {
      clientId = GoogleOAuthConfig.webClientId;
      clientSecret = GoogleOAuthConfig.clientSecret;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
               defaultTargetPlatform == TargetPlatform.linux ||
               defaultTargetPlatform == TargetPlatform.macOS) {
      clientId = GoogleOAuthConfig.desktopClientId;
      clientSecret = GoogleOAuthConfig.desktopClientSecret;
    } else {
      // Android/iOS
      clientId = GoogleOAuthConfig.androidClientId;
      clientSecret = GoogleOAuthConfig.clientSecret;
    }

    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: GoogleOAuthConfig.scopes,
      ),
    );

    // Handle OAuth callback on web
    if (kIsWeb) {
      _handleOAuthCallback();
    }
  }

  /// Get the authentication state stream
  Stream<GoogleSignInCredentials?> get authenticationState => _googleSignIn.authenticationState;

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have stored session data
      final userInfoStr = prefs.getString(_userInfoKey);
      final sessionExpiryStr = prefs.getString(_sessionExpiryKey);
      final lastVerifiedStr = prefs.getString(_lastVerifiedKey);
      
      if (userInfoStr == null) {
        // No session at all
        return false;
      }
      
      // Parse session expiry
      DateTime? sessionExpiry;
      if (sessionExpiryStr != null) {
        sessionExpiry = DateTime.tryParse(sessionExpiryStr);
      }
      
      // Check if session has expired (30 days without any activity)
      if (sessionExpiry != null && DateTime.now().isAfter(sessionExpiry)) {
        // Session expired, clear everything
        await _clearSession();
        return false;
      }
      
      // Session is valid based on time - user can work offline
      // Now check if we should verify the token online (if we haven't in the last 7 days)
      DateTime? lastVerified;
      if (lastVerifiedStr != null) {
        lastVerified = DateTime.tryParse(lastVerifiedStr);
      }
      
      final shouldVerify = lastVerified == null || 
          DateTime.now().difference(lastVerified) > _verificationInterval;
      
      if (shouldVerify) {
        // Try to verify token online (but don't fail if offline)
        await _attemptTokenVerification(prefs);
      }
      
      // Extend session on each check
      await _extendSession(prefs);
      
      return true;
    } catch (e) {
      // On error, check if we have valid stored info for offline use
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(_userInfoKey);
      final sessionExpiryStr = prefs.getString(_sessionExpiryKey);
      
      if (userInfoStr != null && sessionExpiryStr != null) {
        final sessionExpiry = DateTime.tryParse(sessionExpiryStr);
        if (sessionExpiry != null && DateTime.now().isBefore(sessionExpiry)) {
          return true; // Valid offline session
        }
      }
      
      return false;
    }
  }
  
  /// Attempt to verify token online without failing the auth check
  Future<void> _attemptTokenVerification(SharedPreferences prefs) async {
    try {
      // On web, check stored access token
      if (kIsWeb) {
        final accessToken = prefs.getString(_accessTokenKey);
        if (accessToken != null && accessToken.isNotEmpty) {
          final userInfo = await _fetchAndStoreUserInfo(accessToken)
              .timeout(const Duration(seconds: 5));
          if (userInfo['email'] != null && userInfo['email']!.isNotEmpty) {
            // Update last verified timestamp
            await prefs.setString(_lastVerifiedKey, DateTime.now().toIso8601String());
            await _extendSession(prefs);
            return;
          }
        }
      }

      // Try to sign in silently (non-web platforms)
      final credentials = await _googleSignIn.silentSignIn()
          .timeout(const Duration(seconds: 5));
      if (credentials != null) {
        await _fetchAndStoreUserInfo(credentials.accessToken);
        await prefs.setString(_lastVerifiedKey, DateTime.now().toIso8601String());
        await _extendSession(prefs);
      }
    } catch (e) {
      // Verification failed (likely offline) - this is OK, session is still valid
      if (kDebugMode) {
        print('Token verification skipped (offline or error): $e');
      }
    }
  }
  
  /// Extend session expiry
  Future<void> _extendSession(SharedPreferences prefs) async {
    final newExpiry = DateTime.now().add(_sessionDuration);
    await prefs.setString(_sessionExpiryKey, newExpiry.toIso8601String());
  }
  
  /// Clear all session data
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_sessionExpiryKey);
    await prefs.remove(_lastVerifiedKey);
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      // On web, sign-in must be triggered via the sign-in button widget for redirect flow
      if (kIsWeb) {
        throw UnimplementedError(
          'Use the getSignInButton() widget to trigger sign-in on web via redirect.',
        );
      }

      final credentials = await _googleSignIn.signIn();
      if (credentials != null) {
        await _fetchAndStoreUserInfo(credentials.accessToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Sign-in Error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Sign-out Error: $e');
    }
    await _clearSession();
  }

  /// Get user info from storage
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userInfoKey);
    if (data != null) {
      try {
        final Map<String, dynamic> user = json.decode(data);
        return user.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        print('Error decoding user info: $e');
      }
    }
    return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
  }
  
  /// Get session info for display
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionExpiryStr = prefs.getString(_sessionExpiryKey);
      final lastVerifiedStr = prefs.getString(_lastVerifiedKey);
      
      DateTime? sessionExpiry;
      DateTime? lastVerified;
      
      if (sessionExpiryStr != null) {
        sessionExpiry = DateTime.tryParse(sessionExpiryStr);
      }
      
      if (lastVerifiedStr != null) {
        lastVerified = DateTime.tryParse(lastVerifiedStr);
      }
      
      return {
        'sessionExpiry': sessionExpiry,
        'lastVerified': lastVerified,
        'daysUntilExpiry': sessionExpiry != null 
            ? sessionExpiry.difference(DateTime.now()).inDays 
            : null,
        'isVerificationDue': lastVerified == null || 
            DateTime.now().difference(lastVerified) > _verificationInterval,
      };
    } catch (e) {
      return {};
    }
  }

  /// Get the sign-in button widget (required for web platform)
  Widget? getSignInButton() {
    if (kIsWeb) {
      // Use the official Google Identity Services (GIS) button.
      // This handles security requirements automatically and avoids the "Loopback flow blocked" error.
      return WebHelper.renderButton();
    }
    return null;
  }

  /// Handle OAuth callback when returning from Google authorization
  void _handleOAuthCallback() {
    if (!kIsWeb || _isHandlingCallback) return;
    
    final uri = Uri.parse(WebHelper.currentUrl);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    
    if (error != null || code != null) {
      _isHandlingCallback = true;
    }

    if (error != null) {
      print('OAuth error: $error');
      // Clear URL parameters
      WebHelper.replaceState(WebHelper.currentPath);
      return;
    }
    
    if (code != null) {
      // Exchange authorization code for access token
      _exchangeCodeForToken(code).then((data) async {
        if (data != null && data['access_token'] != null) {
          // Store credentials and fetch user info
          await _fetchAndStoreUserInfo(data['access_token'] as String);
          
          // Clear the URL parameters
          WebHelper.replaceState(WebHelper.currentPath);
          
          // Trigger a page reload to update the auth state
          WebHelper.reload();
        }
      }).catchError((e) {
        print('Error exchanging code for token: $e');
        WebHelper.replaceState(WebHelper.currentPath);
      });
    }
  }

  /// Exchange authorization code for access token
  Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      final currentOrigin = WebHelper.currentOrigin;
      final redirectUri = currentOrigin.endsWith('/') 
          ? currentOrigin.substring(0, currentOrigin.length - 1) 
          : currentOrigin;
      
      final response = await http.post(
        Uri.parse(GoogleOAuthConfig.tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'code': code,
          'client_id': GoogleOAuthConfig.webClientId,
          'client_secret': GoogleOAuthConfig.clientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final prefs = await SharedPreferences.getInstance();
        if (data['access_token'] != null) {
          await prefs.setString(_accessTokenKey, data['access_token'] as String);
        }
        
        return data;
      } else {
        print('Token exchange failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error exchanging code: $e');
      return null;
    }
  }

  /*
  /// Manual OAuth redirect flow for web
  Future<void> _manualWebSignIn() async {
    if (!kIsWeb) return;
    
    final currentOrigin = WebHelper.currentOrigin;
    final redirectUri = currentOrigin.endsWith('/') 
        ? currentOrigin.substring(0, currentOrigin.length - 1) 
        : currentOrigin;
        
    final encodedRedirectUri = Uri.encodeComponent(redirectUri);
    final clientId = Uri.encodeComponent(GoogleOAuthConfig.webClientId);
    final scopes = GoogleOAuthConfig.scopes.join('%20');
    final state = Uri.encodeComponent(DateTime.now().millisecondsSinceEpoch.toString());
    
    final authUrl = '${GoogleOAuthConfig.authorizationEndpoint}?'
        'client_id=$clientId&'
        'redirect_uri=$encodedRedirectUri&'
        'response_type=code&'
        'scope=$scopes&'
        'state=$state&'
        'access_type=offline&'
        'prompt=select_account';

    WebHelper.assign(authUrl);
  }
  */

  Future<Map<String, String>> _fetchAndStoreUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userInfo = {
          'email': data['email']?.toString() ?? '',
          'name': data['name']?.toString() ?? '',
          'id': data['id']?.toString() ?? '',
          'photoUrl': data['picture']?.toString() ?? '',
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userInfoKey, json.encode(userInfo));
        await prefs.setString(_accessTokenKey, accessToken);
        
        // Initialize session expiry and last verified timestamp
        final now = DateTime.now();
        await prefs.setString(_sessionExpiryKey, now.add(_sessionDuration).toIso8601String());
        await prefs.setString(_lastVerifiedKey, now.toIso8601String());
        
        return userInfo;
      }
    } catch (e) {
      print('User Info Fetch Error: $e');
    }
    return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
  }
}
