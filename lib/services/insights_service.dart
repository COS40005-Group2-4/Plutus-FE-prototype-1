import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../models/ai/insight.dart';
import 'interfaces/i_insights_service.dart';

class InsightsService implements IInsightsService {
  @override
  Future<InsightsResponse> generateInsights({
    required String locale,
    required PrivacyLevel privacyLevel,
    required List<String> requestedTypes,
    required Map<String, dynamic> data,
  }) async {
    final String functionUrl = AIConfig.insightsFunctionUrl;
    final String apiUrl = AIConfig.apiGatewayUrl;
    final String apiKey = AIConfig.apiKey;

    // Prefer the direct Lambda Function URL (no 29s API Gateway timeout).
    // Fall back to API Gateway /insights if function URL is not configured.
    final String url = functionUrl.isNotEmpty
        ? functionUrl
        : '$apiUrl/insights';

    if (url.isEmpty || (functionUrl.isEmpty && apiUrl.isEmpty)) {
      throw Exception('AI API Gateway URL not configured');
    }

    final Map<String, dynamic> requestBody = {
      'locale': locale,
      'privacyLevel': privacyLevel.name,
      'requestedTypes': requestedTypes,
      'data': data,
    };

    final String bearerToken = AIConfig.insightsBearerToken;

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Function URL: bearer token auth; API Gateway: API key auth
          if (functionUrl.isNotEmpty && bearerToken.isNotEmpty)
            'Authorization': 'Bearer $bearerToken',
          if (functionUrl.isEmpty && apiKey.isNotEmpty) 'x-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return InsightsResponse.fromJson(json);
      } else {
        if (kDebugMode) {
          debugPrint('Insights API failed: ${response.statusCode} ${response.body}');
        }
        throw Exception('Insights API returned ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InsightsService error: $e');
      }
      rethrow;
    }
  }
}
