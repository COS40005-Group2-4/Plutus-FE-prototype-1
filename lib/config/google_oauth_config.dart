class GoogleOAuthConfig {
  // Client ID
  static const String clientId = '611876522758-30av79i8clflnriv7ee5dp68qft0ja28.apps.googleusercontent.com';
  const String AMPLIFY_REDIRECT_URL = 'https://main.d3adjr6i7jedcz.amplifyapp.com';
  // Client Secret
  static const String clientSecret = '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';
  
  // OAuth endpoints
  static const String authorizationEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const String redirectUrl = 'http://localhost:8080';
  
  // Scopes
  static const List<String> scopes = [
    'openid',
    'email',
    'profile',
  ];
}
