import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/google_oauth_config.dart';

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn;
  static const String _userInfoKey = 'google_user_info';
  static const String _accessTokenKey = 'google_access_token';

  GoogleAuthService() {
    // Determine the correct Client ID. 
    final String clientId = kIsWeb 
        ? GoogleOAuthConfig.webClientId 
        : GoogleOAuthConfig.androidClientId;

    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: clientId,
        clientSecret: GoogleOAuthConfig.clientSecret,
        scopes: GoogleOAuthConfig.scopes,
      ),
    );
  }

  /// Get the authentication state stream
  Stream<GoogleSignInCredentials?> get authenticationState => _googleSignIn.authenticationState;

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      // Try to sign in silently to check for existing credentials
      final credentials = await _googleSignIn.silentSignIn();
      if (credentials != null) {
        await _fetchAndStoreUserInfo(credentials.accessToken);
        return true;
      }

      // Fallback check for stored info
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userInfoKey) != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
    await prefs.remove(_accessTokenKey);
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

  /// Helper to get the sign-in button (not used in this flow)
  dynamic getSignInButton() => null;

  Future<void> _fetchAndStoreUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userInfo = {
          'email': data['email'] ?? '',
          'name': data['name'] ?? '',
          'id': data['id'] ?? '',
          'photoUrl': data['picture'] ?? '',
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userInfoKey, json.encode(userInfo));
        await prefs.setString(_accessTokenKey, accessToken);
      }
    } catch (e) {
      print('User Info Fetch Error: $e');
    }
  }
}
