import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';
import 'package:plutus_fe_prototype/models/report_data.dart';
import 'package:plutus_fe_prototype/services/report_ai_service.dart';

void main() {
  group('ReportAiService', () {
    test('parses successful response into section recommendations', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['sections'], <String>['spending_breakdown', 'income_analysis']);
        expect(body['audienceMode'], 'personal');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'recommendations': <String, dynamic>{
              'spending_breakdown': <String, dynamic>{
                'oneLiner': 'Groceries spiked 18%.',
                'detailed': 'Your grocery-to-dining ratio shifted...',
              },
              'income_analysis': <String, dynamic>{
                'oneLiner': 'Income is stable.',
                'detailed': 'Your primary income source shows low variance.',
              },
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final ReportAiService service = ReportAiService(
        httpClient: mockClient,
        baseUrl: 'https://test.example.com',
        apiKey: '',
      );

      final Map<ReportSection, SectionRecommendation> result =
          await service.getRecommendations(
        sections: <ReportSection>[
          ReportSection.spendingBreakdown,
          ReportSection.incomeAnalysis,
        ],
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
        audienceMode: AudienceMode.personal,
        locale: 'en',
        privacyLevel: 'standard',
        sectionData: <String, dynamic>{},
      );

      expect(result.length, 2);
      expect(result[ReportSection.spendingBreakdown]!.oneLiner, 'Groceries spiked 18%.');
      expect(result[ReportSection.incomeAnalysis]!.oneLiner, 'Income is stable.');
    });

    test('returns empty map on API error', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        return http.Response('Internal Server Error', 500);
      });

      final ReportAiService service = ReportAiService(
        httpClient: mockClient,
        baseUrl: 'https://test.example.com',
        apiKey: '',
      );

      final Map<ReportSection, SectionRecommendation> result =
          await service.getRecommendations(
        sections: <ReportSection>[ReportSection.spendingBreakdown],
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
        audienceMode: AudienceMode.personal,
        locale: 'en',
        privacyLevel: 'standard',
        sectionData: <String, dynamic>{},
      );

      expect(result.isEmpty, true);
    });
  });
}
