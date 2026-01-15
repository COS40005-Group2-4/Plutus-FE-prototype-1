import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/google_oauth_config.dart';
import 'secure_storage_service.dart';

class GoogleAuthService {
  final SecureStorageService _storage = SecureStorageService();
  
  // Start OAuth flow
  Future<bool> signIn() async {
    try {
      // Generate authorization URL
      final authUrl = Uri.parse(GoogleOAuthConfig.authorizationEndpoint).replace(
        queryParameters: {
          'client_id': GoogleOAuthConfig.clientId,
          'redirect_uri': GoogleOAuthConfig.redirectUrl,
          'response_type': 'code',
          'scope': GoogleOAuthConfig.scopes.join(' '),
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      
      // Start local server to listen for redirect
      final server = await HttpServer.bind('localhost', 8080);
      
      // Open browser for authentication
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      }
      
      // Wait for callback
      final request = await server.first;
      final code = request.uri.queryParameters['code'];
      
      // Send success response to browser
      request.response
        ..statusCode = 200
        ..headers.set('Content-Type', 'text/html')
        ..write('<html><body><h1>Login Successful!</h1><p>You can close this window.</p></body></html>');
      await request.response.close();
      await server.close();
      
      if (code == null) {
        return false;
      }
      
      // Exchange code for tokens
      return await _exchangeCodeForTokens(code);
    } catch (e) {
      print('Error during sign in: $e');
      return false;
    }
  }
  
  // Exchange authorization code for tokens
  Future<bool> _exchangeCodeForTokens(String code) async {
    try {
      final response = await http.post(
        Uri.parse(GoogleOAuthConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': GoogleOAuthConfig.clientId,
          'client_secret': GoogleOAuthConfig.clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': GoogleOAuthConfig.redirectUrl,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        
        // Save tokens
        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        
        // Get user info
        await _getUserInfo(accessToken);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error exchanging code: $e');
      return false;
    }
  }
  
  // Get user info from Google
  Future<void> _getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.saveUserInfo(
          email: data['email'] ?? '',
          name: data['name'] ?? '',
        );
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  // Sign out
  Future<void> signOut() async {
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
