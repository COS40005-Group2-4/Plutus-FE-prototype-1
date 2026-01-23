import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
  bool _isHandlingCallback = false;

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
      // On web, check for stored access token first (from manual OAuth flow)
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString(_accessTokenKey);
        if (accessToken != null && accessToken.isNotEmpty) {
          // Verify token is still valid by checking user info
          try {
            final userInfo = await _fetchAndStoreUserInfo(accessToken);
            if (userInfo['email'] != null && userInfo['email']!.isNotEmpty) {
              return true;
            }
          } catch (e) {
            // Token might be expired, clear it
            await prefs.remove(_accessTokenKey);
            await prefs.remove(_userInfoKey);
          }
        }
      }

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
    await prefs.remove(_accessTokenKey);
  }

  /// Get user info from storage
  Future<Map<String, String>> getUserInfo() async {
    // On web, try to refresh info with stored token if possible
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          await _fetchAndStoreUserInfo(accessToken);
        } catch (e) {
          print('Error refreshing user info on web: $e');
        }
      }
    }

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
        return userInfo;
      }
    } catch (e) {
      print('User Info Fetch Error: $e');
    }
    return {'email': '', 'name': '', 'id': '', 'photoUrl': ''};
  }
}
