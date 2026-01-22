import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../config/google_oauth_config.dart';

// Conditional import for web
import 'package:web/web.dart' as web;

/// Custom Google Sign-In button widget for web
class _CustomGoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CustomGoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.login, size: 20);
        },
      ),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        side: const BorderSide(color: Colors.grey, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn;
  static const String _userInfoKey = 'google_user_info';
  static const String _accessTokenKey = 'google_access_token';

  GoogleAuthService() {
    // Use the correct ClientID based on platform
    final clientId = kIsWeb 
        ? GoogleOAuthConfig.webClientId 
        : GoogleOAuthConfig.androidClientId;
    
    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: clientId,
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
    
    // Handle OAuth callback on web
    if (kIsWeb) {
      _handleOAuthCallback();
    }
  }

  /// Get the sign-in button widget (required for web platform)
  /// Returns a custom Flutter button that triggers Google Sign-In via redirect flow
  Widget? getSignInButton() {
    if (kIsWeb) {
      // Check if we're returning from OAuth callback
      _handleOAuthCallback();
      
      // Return a custom button that uses redirect flow instead of popup
      // This avoids the email display issue and popup blocking
      return _CustomGoogleSignInButton(
        onPressed: () async {
          try {
            // Use pure OAuth redirect flow to avoid CORS issues
            await _manualWebSignIn();
          } catch (e) {
            print('Error signing in: $e');
          }
        },
      );
    }
    return null;
  }
  
  /// Handle OAuth callback when returning from Google authorization
  void _handleOAuthCallback() {
    if (!kIsWeb) return;
    
    final uri = Uri.parse(web.window.location.href);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    
    if (error != null) {
      print('OAuth error: $error');
      // Clear URL parameters
      web.window.history.replaceState(null, '', web.window.location.pathname);
      return;
    }
    
    if (code != null) {
      // Exchange authorization code for access token
      _exchangeCodeForToken(code).then((credentials) async {
        if (credentials != null && credentials['access_token'] != null) {
          // Store credentials and fetch user info
          await _fetchAndStoreUserInfo(credentials['access_token'] as String);
          
          // Clear the URL parameters
          web.window.history.replaceState(null, '', web.window.location.pathname);
          
          // Trigger a page reload to update the auth state
          // This ensures the auth provider picks up the new authentication
          web.window.location.reload();
        }
      }).catchError((e) {
        print('Error exchanging code for token: $e');
        // Clear URL parameters even on error
        web.window.history.replaceState(null, '', web.window.location.pathname);
      });
    }
  }
  
  /// Exchange authorization code for access token
  Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      final currentOrigin = web.window.location.origin;
      // Ensure redirectUri matches EXACTLY what was sent in _manualWebSignIn
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
        
        // Store access token
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

  /// Manual OAuth redirect flow for web (fallback)
  Future<void> _manualWebSignIn() async {
    if (!kIsWeb) return;
    
    // Get current origin for redirect URI
    final currentOrigin = web.window.location.origin;
    // Ensure no trailing slash for the redirect URI
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
        'prompt=select_account'; // Changed from 'consent' to 'select_account'

    print('Attempting OAuth redirect to: $authUrl');
    web.window.location.assign(authUrl); // Use assign instead of href for better history handling
  }

  /// Get the authentication state stream
  Stream<GoogleSignInCredentials?> get authenticationState => 
      _googleSignIn.authenticationState;

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
      
      // Try silent sign-in first (no user interaction)
      try {
        final credentials = await _googleSignIn.silentSignIn();
        if (credentials != null) {
          // Fetch user info and store it
          await _fetchAndStoreUserInfo(credentials.accessToken);
          return true;
        }
      } catch (e) {
        // Silent sign-in failed, continue to check stored info
      }

      // Also check stored user info
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString(_userInfoKey);
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        // User info exists, verify token if available
        if (kIsWeb) {
          final accessToken = prefs.getString(_accessTokenKey);
          if (accessToken != null && accessToken.isNotEmpty) {
            return true;
          }
        }
        return true; // Assume authenticated if user info exists
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
      await prefs.remove(_accessTokenKey);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get user information
  Future<Map<String, String>> getUserInfo() async {
    try {
      // On web, try stored access token first
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString(_accessTokenKey);
        if (accessToken != null && accessToken.isNotEmpty) {
          try {
            return await _fetchAndStoreUserInfo(accessToken);
          } catch (e) {
            print('Error fetching user info with stored token: $e');
          }
        }
      }
      
      // First try to get credentials via silent sign-in
      try {
        final credentials = await _googleSignIn.silentSignIn();
        if (credentials != null) {
          // Fetch fresh user info
          return await _fetchAndStoreUserInfo(credentials.accessToken);
        }
      } catch (e) {
        // Silent sign-in failed, continue to check stored info
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
