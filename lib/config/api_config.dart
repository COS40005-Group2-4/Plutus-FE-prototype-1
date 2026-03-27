/// Configuration for the backend API endpoint.
/// On web, the Flutter app communicates with the Go backend via HTTP API Gateway.
/// On native platforms, the Go backend is accessed via FFI (this config is unused).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static bool get isConfigured => baseUrl != 'http://localhost:8080' && baseUrl.isNotEmpty;
}
