import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get userEmail => _userEmail;
  String get userName => _userName;
  
  // Initialize - check if already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
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
      final userInfo = await _authService.getUserInfo();
      _userEmail = userInfo['email'] ?? '';
      _userName = userInfo['name'] ?? '';
    }
    
    _isLoading = false;
    notifyListeners();
    
    return success;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _userEmail = '';
    _userName = '';
    notifyListeners();
  }
}
