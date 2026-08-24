import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  static String get apiGatewayUrl =>
      dotenv.env['AI_API_GATEWAY_URL'] ??
      const String.fromEnvironment(
        'AI_API_GATEWAY_URL',
        defaultValue: '',
      );

  static String get apiKey =>
      dotenv.env['AI_API_KEY'] ??
      const String.fromEnvironment(
        'AI_API_KEY',
        defaultValue: '',
      );

  /// Lambda Function URL for insights — bypasses API Gateway's 29s timeout.
  /// Falls back to the API Gateway URL if not set.
  static String get insightsFunctionUrl =>
      dotenv.env['INSIGHTS_FUNCTION_URL'] ??
      const String.fromEnvironment(
        'INSIGHTS_FUNCTION_URL',
        defaultValue: '',
      ).trim();

  /// Bearer token for the insights Lambda Function URL.
  /// Managed in AWS Secrets Manager under plutus/secrets > INSIGHTS_BEARER_TOKEN.
  static String get insightsBearerToken =>
      dotenv.env['INSIGHTS_BEARER_TOKEN'] ??
      const String.fromEnvironment(
        'INSIGHTS_BEARER_TOKEN',
        defaultValue: '',
      );

  static bool get isConfigured =>
      apiGatewayUrl.isNotEmpty && apiKey.isNotEmpty;
}
