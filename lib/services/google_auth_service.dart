import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_oauth_config.dart';
import 'secure_storage_service.dart';

class GoogleAuthService {
  final SecureStorageService _storage = SecureStorageService();
  
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: GoogleOAuthConfig.clientId,
    scopes: GoogleOAuthConfig.scopes,
  );

  // Start OAuth flow
  Future<bool> signIn() async {
    try {
      // Use google_sign_in package which works on Web, Android, and iOS
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? accessToken = auth.accessToken;
      
      if (accessToken == null) {
        return false;
      }
      
      // Save tokens
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: null, 
      );
      
      // Save user info from the account object
      await _storage.saveUserInfo(
        email: account.email,
        name: account.displayName ?? '',
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
    return await _googleSignIn.isSignedIn();
  }
  
  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
