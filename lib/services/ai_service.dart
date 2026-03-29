import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../models/ai/category_suggestion.dart';
import '../models/ai/correction.dart';
import '../models/transaction_model.dart';
import 'interfaces/i_ai_service.dart';

class AIService implements IAIService {
  final String _apiUrl;
  final String _apiKey;
  final http.Client _httpClient;

  AIService({
    String? apiUrl,
    String? apiKey,
    http.Client? httpClient,
  })  : _apiUrl = apiUrl ?? AIConfig.apiGatewayUrl,
        _apiKey = apiKey ?? AIConfig.apiKey,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<CategorySuggestion?> categorizeTransaction(
    Transaction transaction,
    List<String> accounts,
    List<Correction> corrections,
  ) async {
    try {
      final body = jsonEncode({
        'transaction': {
          'payee': transaction.payee,
          'description': transaction.description,
          'amount': transaction.totalAmount.abs(),
          'currency': transaction.currency,
        },
        'accounts': accounts,
        'corrections': corrections.map((c) => c.toApiFormat()).toList(),
      });

      final response = await _httpClient.post(
        Uri.parse('$_apiUrl/categorize'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CategorySuggestion.fromJson(json);
      }

      if (kDebugMode) {
        print('AI categorize failed: ${response.statusCode} ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('AI categorize error: $e');
      }
      return null;
    }
  }
}
