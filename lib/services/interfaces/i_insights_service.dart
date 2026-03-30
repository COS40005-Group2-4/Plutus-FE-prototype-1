import '../../models/ai/insight.dart';

abstract class IInsightsService {
  Future<InsightsResponse> generateInsights({
    required String locale,
    required PrivacyLevel privacyLevel,
    required List<String> requestedTypes,
    required Map<String, dynamic> data,
  });
}
