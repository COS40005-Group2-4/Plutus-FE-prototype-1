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

  static bool get isConfigured =>
      apiGatewayUrl.isNotEmpty && apiKey.isNotEmpty;
}
