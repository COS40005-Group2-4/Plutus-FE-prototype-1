import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as official;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as all_platforms;
import 'package:http/http.dart' as http;
import '../config/google_oauth_config.dart';
import 'secure_storage_service.dart';

class GoogleAuthService {
  final SecureStorageService _storage = SecureStorageService();
  
  // Official for Mobile/Web
  final official.GoogleSignIn _officialGoogleSignIn = official.GoogleSignIn.instance;
  
  // All platforms for Desktop (specifically Windows)
  all_platforms.GoogleSignIn? _allPlatformsGoogleSignIn;
  
  bool _initialized = false;
  
  bool get _isWindows => !kIsWeb && Platform.isWindows;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (_isWindows) {
      _allPlatformsGoogleSignIn = all_platforms.GoogleSignIn(
        params: all_platforms.GoogleSignInParams(
          clientId: GoogleOAuthConfig.clientId,
          clientSecret: GoogleOAuthConfig.clientSecret,
          scopes: GoogleOAuthConfig.scopes,
          redirectPort: 8080,
        ),
      );
    } else {
      await _officialGoogleSignIn.initialize(
        clientId: GoogleOAuthConfig.clientId,
      );
    }
    _initialized = true;
  }

  // Start OAuth flow
  Future<bool> signIn() async {
    try {
      await _ensureInitialized();
      
      String? accessToken;
      String? email;
      String? name;

      if (_isWindows) {
        final result = await _allPlatformsGoogleSignIn!.signIn();
        if (result == null) return false;
        
        accessToken = result.accessToken;
        
        // Fetch user info manually using the access token
        try {
          final response = await http.get(
            Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          
          if (response.statusCode == 200) {
            final userInfo = json.decode(response.body);
            email = userInfo['email'];
            name = userInfo['name'] ?? userInfo['given_name'] ?? '';
          }
        } catch (e) {
          print('Error fetching user info on Windows: $e');
        }
      } else {
        // In v7+, authenticate() is used instead of signIn()
        // It throws instead of returning null if failed or cancelled
        final official.GoogleSignInAccount account = await _officialGoogleSignIn.authenticate(
          scopeHint: GoogleOAuthConfig.scopes,
        );
        
        // In v7+, tokens are obtained via authorizationClient
        final authorizedUser = await account.authorizationClient.authorizeScopes(
          GoogleOAuthConfig.scopes,
        );
        accessToken = authorizedUser.accessToken;
        email = account.email;
        name = account.displayName;
      }
      
      // Save tokens
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: null, 
      );
      
      // Save user info
      await _storage.saveUserInfo(
        email: email ?? '',
        name: name ?? '',
      );
      
      return true;
    } catch (e) {
      print('Error during sign in: $e');
      return false;
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) return true;
    
    return false;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _ensureInitialized();
    if (_isWindows) {
      await _allPlatformsGoogleSignIn?.signOut();
    } else {
      await _officialGoogleSignIn.signOut();
    }
    await _storage.clearAll();
  }
  
  // Get current user info
  Future<Map<String, String>> getUserInfo() async {
    final email = await _storage.getUserEmail();
    final name = await _storage.getUserName();
    return {
      'email': email ?? '',
      'name': name ?? '',
    };
  }
}
