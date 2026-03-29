import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleOAuthConfig {
  // Web Client ID (Authorized JavaScript Origin required)
  static String get webClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  // Android Client ID (Package name and SHA-1 required)
  static String get androidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID', defaultValue: '');

  // Desktop Client ID
  static String get desktopClientId =>
      dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID', defaultValue: '');

  // Client Secret (General/Web)
  static String get clientSecret =>
      dotenv.env['GOOGLE_CLIENT_SECRET'] ??
      const String.fromEnvironment('GOOGLE_CLIENT_SECRET', defaultValue: '');

  // Desktop Client Secret
  static String get desktopClientSecret =>
      dotenv.env['GOOGLE_DESKTOP_CLIENT_SECRET'] ??
      const String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET', defaultValue: '');

  // Production redirect URL (Amplify)
  static const String redirectUrlProduction = 'https://main.d3eqrozysqvds5.amplifyapp.com';
  
  // Development redirect URL (local)
  static const String redirectUrlDev = 'http://localhost:8080';
  
  // Use production URL for web builds, dev URL for testing
  static const String redirectUrl = String.fromEnvironment(
    'REDIRECT_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  // OAuth endpoints
  static const String authorizationEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String tokenEndpoint = 'https://oauth2.googleapis.com/token';
  
  // Scopes
  static const List<String> scopes = [
    'openid',
    'email',
    'profile',
  ];
  
  /// Validate configuration - returns error message if config is missing
  static String? validateConfiguration({required bool isWeb}) {
    if (isWeb) {
      if (webClientId.isEmpty) {
        return 'GOOGLE_WEB_CLIENT_ID environment variable is not set. '
               'Check your build configuration.';
      }
    } else {
      if (androidClientId.isEmpty) {
        return 'GOOGLE_ANDROID_CLIENT_ID environment variable is not set. '
               'Check your build configuration.';
      }
    }
    return null;
  }
}
