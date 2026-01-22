class GoogleOAuthConfig {
  // Web Client ID (Authorized JavaScript Origin required)
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Android Client ID (Package name and SHA-1 required)
  static const String androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  // Client Secret 
  static const String clientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );
  
  // Production redirect URL (Amplify)
  static const String redirectUrlProduction = 'https://main.d3adjr6i7jedcz.amplifyapp.com';
  
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
}
