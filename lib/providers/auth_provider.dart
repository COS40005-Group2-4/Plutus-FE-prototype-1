import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';
import '../services/interfaces/i_consent_service.dart';
import '../di/service_locator.dart';
import '../models/user_model.dart';
import '../widgets/consent_dialog.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();
  final UserService _userService = UserService();
  final SettingsService _settingsService = SettingsService();
  final IConsentService _consentService = sl<IConsentService>();
  
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  User? _currentUser;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String get userEmail => _userEmail;
  String get userName => _userName;
  User? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?.id;
  
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
    final lastUserId = prefs.getInt('last_user_id');
    
    // Try to restore last logged-in user
    if (lastUserId != null) {
      final user = await _userService.getUserById(lastUserId);
      if (user != null) {
        _currentUser = user;
        _userName = user.displayName;
        _userEmail = user.email ?? '';
        _isGuest = user.isGuest;
        _isAuthenticated = !user.isGuest || user.hasOAuth;
        
        await _userService.updateLastLogin(user.id);
      }
    }
    
    // On web, listen to OAuth authentication state changes
    if (kIsWeb) {
      _authService.authenticationState.listen((credentials) async {
        if (credentials != null) {
          await _handleOAuthSignIn();
        } else {
          // Don't clear local user on OAuth signout
          if (_currentUser?.hasOAuth == true) {
            _isAuthenticated = false;
          }
          notifyListeners();
        }
      });
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _handleOAuthSignIn() async {
    final userInfo = await _authService.getUserInfo();
    final email = userInfo['email'] ?? '';
    final name = userInfo['name'] ?? '';
    final oauthId = email; // Use email as unique OAuth ID
    
    // Check if OAuth user exists
    User? user = await _userService.getUserByOAuth('google', oauthId);
    
    if (user == null) {
      // Create new OAuth user
      user = await _userService.createOAuthUser(
        username: email.split('@')[0],
        displayName: name,
        email: email,
        oauthProvider: 'google',
        oauthId: oauthId,
      );
    } else {
      await _userService.updateLastLogin(user.id);
    }
    
    _currentUser = user;
    _isAuthenticated = true;
    _isGuest = false;
    _userEmail = email;
    _userName = name;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_user_id', user.id);
    
    notifyListeners();
  }
  
  // Sign in with OAuth
  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();
    
    final success = await _authService.signIn();
    
    if (success) {
      await _handleOAuthSignIn();
    }
    
    _isLoading = false;
    notifyListeners();
    
    return success;
  }
  
  // Sign in with local user
  Future<bool> signInWithLocalUser(String username) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await _userService.getUserByUsername(username);
      
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _currentUser = user;
      _userName = user.displayName;
      _userEmail = user.email ?? '';
      _isGuest = user.isGuest;
      _isAuthenticated = !user.isGuest || user.hasOAuth;
      
      await _userService.updateLastLogin(user.id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_user_id', user.id);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Create new local user
  Future<bool> createLocalUser(String username, String displayName, {bool isGuest = false}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await _userService.createLocalUser(
        username: username,
        displayName: displayName,
        isGuest: isGuest,
      );
      
      _currentUser = user;
      _userName = user.displayName;
      _userEmail = '';
      _isGuest = isGuest;
      _isAuthenticated = !isGuest;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_user_id', user.id);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Link OAuth account to current local user
  Future<bool> linkOAuthAccount() async {
    if (_currentUser == null || _currentUser!.hasOAuth) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _authService.signIn();
      
      if (success) {
        final userInfo = await _authService.getUserInfo();
        final email = userInfo['email'] ?? '';
        final oauthId = email;
        
        await _userService.linkOAuthToUser(
          userId: _currentUser!.id,
          provider: 'google',
          oauthId: oauthId,
          email: email,
        );
        
        // Reload user
        _currentUser = await _userService.getUserById(_currentUser!.id);
        _userEmail = email;
        _isAuthenticated = true;
        
        _isLoading = false;
        notifyListeners();
        
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Unlink OAuth account from current user
  Future<void> unlinkOAuthAccount() async {
    if (_currentUser == null || !_currentUser!.hasOAuth) {
      return;
    }
    
    try {
      await _userService.unlinkOAuthFromUser(_currentUser!.id);
      await _authService.signOut();
      
      // Reload user
      _currentUser = await _userService.getUserById(_currentUser!.id);
      _userEmail = '';
      _isAuthenticated = false;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error unlinking OAuth: $e');
      }
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    if (_currentUser?.hasOAuth == true) {
      await _authService.signOut();
    }
    
    _isAuthenticated = false;
    _isGuest = false;
    _currentUser = null;
    _userEmail = '';
    _userName = '';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');
    
    notifyListeners();
  }
  
  // Get all available local users
  Future<List<User>> getAllUsers() async {
    return await _userService.getAllUsers();
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

  /// Check if user has given consent for data collection.
  /// Returns true if user has OAuth and has consented, or if user doesn't have OAuth.
  bool get hasDataConsent {
    if (_currentUser == null) return true;
    // If user doesn't have OAuth, they are in offline/guest mode - no consent needed
    if (!_currentUser!.hasOAuth) return true;
    // If user has OAuth, check if they have consented
    return _currentUser!.dataConsent;
  }

  /// Check and prompt for data consent if user has OAuth but hasn't consented yet.
  /// Checks DynamoDB first (authoritative), falls back to local SQLite if offline.
  /// Returns true if consent is granted, false if declined.
  Future<bool> checkDataConsent(BuildContext context) async {
    // No user logged in - no consent needed
    if (_currentUser == null) return true;

    // User doesn't have OAuth (offline/guest mode) - no consent needed
    if (!_currentUser!.hasOAuth) return true;

    final email = _currentUser!.email;
    if (email == null || email.isEmpty) return true;

    // 1. Check DynamoDB first (authoritative source)
    try {
      final acceptedRemotely = await _consentService.hasAcceptedTerms(email);
      if (acceptedRemotely) {
        // Sync to local if not already set
        if (!_currentUser!.dataConsent) {
          await _userService.setDataConsent(_currentUser!.id, true);
          _currentUser = await _userService.getUserById(_currentUser!.id);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      // DynamoDB unreachable - fall back to local
      if (kDebugMode) {
        print('ConsentService: DynamoDB check failed, using local: $e');
      }
      if (_currentUser!.dataConsent) return true;
    }

    // 2. If local says consented (offline scenario), trust it
    if (_currentUser!.dataConsent) return true;

    // 3. Neither remote nor local consent - show dialog
    final agreed = await showDataConsentDialog(context);

    if (agreed) {
      // Write to DynamoDB (best-effort), then local
      try {
        await _consentService.recordAcceptance(email);
      } catch (e) {
        if (kDebugMode) {
          print('ConsentService: DynamoDB write failed, saved locally: $e');
        }
      }
      await _userService.setDataConsent(_currentUser!.id, true);
      _currentUser = await _userService.getUserById(_currentUser!.id);
      notifyListeners();
      return true;
    } else {
      // User declined - convert to guest/offline mode
      await _userService.setDataConsent(_currentUser!.id, false);
      await unlinkOAuthAccount();
      return false;
    }
  }
}
