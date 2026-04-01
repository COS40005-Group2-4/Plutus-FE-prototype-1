import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/ai_config.dart';
import '../models/report_config.dart';
import '../models/report_data.dart';
import 'interfaces/i_report_ai_service.dart';

const Map<ReportSection, String> _sectionApiKeys = <ReportSection, String>{
  ReportSection.executiveSummary: 'executive_summary',
  ReportSection.spendingBreakdown: 'spending_breakdown',
  ReportSection.incomeAnalysis: 'income_analysis',
  ReportSection.cashFlow: 'cash_flow',
  ReportSection.budgetActual: 'budget_actual',
  ReportSection.topMerchants: 'top_merchants',
  ReportSection.investmentPortfolio: 'investment_portfolio',
  ReportSection.forecast: 'forecast',
  ReportSection.alerts: 'alerts',
  ReportSection.coaching: 'coaching',
  ReportSection.billsRecurring: 'bills_recurring',
};

final Map<String, ReportSection> _apiKeyToSection = <String, ReportSection>{
  for (final MapEntry<ReportSection, String> e in _sectionApiKeys.entries)
    e.value: e.key,
};

class ReportAiService implements IReportAiService {
  final http.Client _client;
  final String? _baseUrl;
  final String? _apiKey;

  ReportAiService({http.Client? httpClient, String? baseUrl, String? apiKey})
      : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl,
        _apiKey = apiKey;

  @override
  Future<Map<ReportSection, SectionRecommendation>> getRecommendations({
    required List<ReportSection> sections,
    required DateRange dateRange,
    required AudienceMode audienceMode,
    required String locale,
    required String privacyLevel,
    required Map<String, dynamic> sectionData,
  }) async {
    final String apiUrl = _baseUrl ?? AIConfig.apiGatewayUrl;
    final String apiKey = _apiKey ?? AIConfig.apiKey;

    if (apiUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('ReportAiService: API URL not configured, returning empty recommendations');
      }
      return <ReportSection, SectionRecommendation>{};
    }

    final DateFormat fmt = DateFormat('yyyy-MM-dd');

    final List<String> sectionKeys = sections
        .where((ReportSection s) => _sectionApiKeys.containsKey(s))
        .map((ReportSection s) => _sectionApiKeys[s]!)
        .toList();

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'sections': sectionKeys,
      'dateRange': <String, String>{
        'start': fmt.format(dateRange.start),
        'end': fmt.format(dateRange.end),
      },
      'comparisonRange': <String, String>{
        'start': fmt.format(dateRange.comparisonStart),
        'end': fmt.format(dateRange.comparisonEnd),
      },
      'audienceMode': audienceMode.name,
      'locale': locale,
      'privacyLevel': privacyLevel,
      'sectionData': sectionData,
    };

    try {
      final http.Response response = await _client.post(
        Uri.parse('$apiUrl/report-insights'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'x-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> recs =
            json['recommendations'] as Map<String, dynamic>;

        final Map<ReportSection, SectionRecommendation> result =
            <ReportSection, SectionRecommendation>{};

        for (final MapEntry<String, dynamic> entry in recs.entries) {
          final ReportSection? section = _apiKeyToSection[entry.key];
          if (section != null) {
            result[section] = SectionRecommendation.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }

        return result;
      } else {
        if (kDebugMode) {
          debugPrint(
            'ReportAiService: API returned ${response.statusCode}: ${response.body}',
          );
        }
        return <ReportSection, SectionRecommendation>{};
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ReportAiService error: $e');
      }
      return <ReportSection, SectionRecommendation>{};
    }
  }
}
