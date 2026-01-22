import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../config/google_oauth_config.dart';

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn;
  static const String _userInfoKey = 'google_user_info';

  GoogleAuthService() {
    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: GoogleOAuthConfig.clientId,
        clientSecret: GoogleOAuthConfig.clientSecret,
        scopes: GoogleOAuthConfig.scopes,
      ),
    );
    
    // Listen to authentication state changes (especially important for web)
    _googleSignIn.authenticationState.listen((credentials) async {
      if (credentials != null) {
        // User signed in, fetch and store user info
        await _fetchAndStoreUserInfo(credentials.accessToken);
      }
    });
  }

  /// Get the sign-in button widget (required for web platform)
  Widget? getSignInButton() {
    if (kIsWeb) {
      return _googleSignIn.signInButton();
    }
    return null;
  }

  /// Get the authentication state stream
  Stream<GoogleSignInCredentials?> get authenticationState => 
      _googleSignIn.authenticationState;

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      // Try silent sign-in first (no user interaction)
      final credentials = await _googleSignIn.silentSignIn();
      if (credentials != null) {
        // Fetch user info and store it
        await _fetchAndStoreUserInfo(credentials.accessToken);
        return true;
      }

      // Also check stored user info
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(_userInfoKey);
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        // User info exists, but try to verify with silent sign-in
        try {
          final restoredCredentials = await _googleSignIn.silentSignIn();
          if (restoredCredentials != null) {
            await _fetchAndStoreUserInfo(restoredCredentials.accessToken);
            return true;
          } else {
            // Clear invalid stored info
            await prefs.remove(_userInfoKey);
            return false;
          }
        } catch (e) {
          // If silent sign-in fails, clear stored info
          await prefs.remove(_userInfoKey);
          return false;
        }
      }

      return false;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  /// Sign in with Google
  /// Note: On web, this will throw UnimplementedError. Use getSignInButton() instead.
  Future<bool> signIn() async {
    try {
      // On web, sign-in must be triggered via the sign-in button widget
      if (kIsWeb) {
        throw UnimplementedError(
          'Use the signInButton() widget to trigger sign-in on web. '
          'Call getSignInButton() to get the widget.',
        );
      }
      
      // Use the intelligent fallback strategy (lightweight -> full flow)
      final credentials = await _googleSignIn.signIn();
      
      if (credentials != null) {
        // Fetch user info and store it
        await _fetchAndStoreUserInfo(credentials.accessToken);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userInfoKey);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get user information
  Future<Map<String, String>> getUserInfo() async {
    try {
      // First try to get credentials via silent sign-in
      final credentials = await _googleSignIn.silentSignIn();
      if (credentials != null) {
        // Fetch fresh user info
        return await _fetchAndStoreUserInfo(credentials.accessToken);
      }

      // If no current credentials, try to restore from storage
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(_userInfoKey);
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        final userInfo = json.decode(userInfoStr) as Map<String, dynamic>;
        return {
          'email': userInfo['email'] as String? ?? '',
          'name': userInfo['name'] as String? ?? '',
          'id': userInfo['id'] as String? ?? '',
          'photoUrl': userInfo['photoUrl'] as String? ?? '',
        };
      }

      return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
    } catch (e) {
      print('Error getting user info: $e');
      return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
    }
  }

  /// Fetch user information from Google API and store it
  Future<Map<String, String>> _fetchAndStoreUserInfo(String accessToken) async {
    try {
      // Fetch user info from Google OAuth2 userinfo endpoint
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final userInfo = {
          'email': data['email'] as String? ?? '',
          'name': data['name'] as String? ?? '',
          'id': data['id'] as String? ?? '',
          'photoUrl': data['picture'] as String? ?? '',
        };

        // Store user info locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userInfoKey, json.encode(userInfo));

        return userInfo;
      }

      return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
    } catch (e) {
      print('Error fetching user info: $e');
      return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
    }
  }
}
