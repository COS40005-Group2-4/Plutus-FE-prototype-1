import '../../models/report_config.dart';
import '../../models/report_data.dart';

abstract class IReportAiService {
  Future<Map<ReportSection, SectionRecommendation>> getRecommendations({
    required List<ReportSection> sections,
    required DateRange dateRange,
    required AudienceMode audienceMode,
    required String locale,
    required String privacyLevel,
    required Map<String, dynamic> sectionData,
  });
}
