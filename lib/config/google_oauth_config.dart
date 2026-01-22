class GoogleOAuthConfig {
  // Web Client ID (Authorized JavaScript Origin required)
  static const String webClientId = '611876522758-30av79i8clflnriv7ee5dp68qft0ja28.apps.googleusercontent.com';

  // Android Client ID (Package name and SHA-1 required)
  static const String androidClientId = '611876522758-embicif9ls5drv85b576i5693uamuksj.apps.googleusercontent.com';

  // Client Secret 
  static const String clientSecret = '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';
  
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
