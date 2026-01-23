import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();
  
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String get userEmail => _userEmail;
  String get userName => _userName;
  
  // Get authentication service for direct access to session info
  GoogleAuthService get authService => _authService;
  
  /// Get the sign-in button widget (for web platform)
  Widget? getSignInButton() => _authService.getSignInButton();
  
  /// Get the authentication state stream (for web platform)
  Stream<gsi.GoogleSignInCredentials?> get authenticationState => 
      _authService.authenticationState;
  
  // Initialize - check if already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
    
    // On web, listen to authentication state changes
    if (kIsWeb) {
      _authService.authenticationState.listen((credentials) async {
        if (credentials != null) {
          _isAuthenticated = true;
          final userInfo = await _authService.getUserInfo();
          _userEmail = userInfo['email'] ?? '';
          _userName = userInfo['name'] ?? '';
          _isLoading = false;
          notifyListeners();
        } else {
          _isAuthenticated = false;
          _userEmail = '';
          _userName = '';
          _isLoading = false;
          notifyListeners();
        }
      });
    }
    
    _isAuthenticated = await _authService.isAuthenticated();
    
    if (_isAuthenticated) {
      final userInfo = await _authService.getUserInfo();
      _userEmail = userInfo['email'] ?? '';
      _userName = userInfo['name'] ?? '';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Sign in
  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();
    
    final success = await _authService.signIn();
    
    if (success) {
      _isAuthenticated = true;
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      final userInfo = await _authService.getUserInfo();
      _userEmail = userInfo['email'] ?? '';
      _userName = userInfo['name'] ?? '';
    }
    
    _isLoading = false;
    notifyListeners();
    
    return success;
  }
  
  // Set guest mode
  Future<void> setGuestMode(bool isGuest) async {
    _isGuest = isGuest;
    if (isGuest) {
      _isAuthenticated = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', isGuest);
    notifyListeners();
  }
  
  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    _userEmail = '';
    _userName = '';
    notifyListeners();
  }
  
  /// Get session information
  Future<Map<String, dynamic>> getSessionInfo() async {
    return await _authService.getSessionInfo();
  }
  
  /// Manually refresh authentication (when coming back online)
  Future<bool> refreshAuthentication() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final wasAuthenticated = await _authService.isAuthenticated();
      
      if (wasAuthenticated) {
        _isAuthenticated = true;
        final userInfo = await _authService.getUserInfo();
        _userEmail = userInfo['email'] ?? '';
        _userName = userInfo['name'] ?? '';
      } else {
        _isAuthenticated = false;
        _userEmail = '';
        _userName = '';
      }
      
      _isLoading = false;
      notifyListeners();
      
      return _isAuthenticated;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
