import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';
import 'package:plutus_fe_prototype/models/report_template.dart';

void main() {
  group('ReportTemplate', () {
    test('has 5 pre-built templates', () {
      expect(ReportTemplate.all.length, 5);
    });

    test('quickSummary has correct sections', () {
      final ReportTemplate t = ReportTemplate.quickSummary;
      expect(t.sections, <ReportSection>[
        ReportSection.coverPage,
        ReportSection.executiveSummary,
        ReportSection.spendingBreakdown,
        ReportSection.cashFlow,
      ]);
      expect(t.defaultAudience, AudienceMode.personal);
    });

    test('fullFinancialReview includes all 13 sections', () {
      final ReportTemplate t = ReportTemplate.fullFinancialReview;
      expect(t.sections.length, 13);
      expect(t.sections, ReportSection.values.toList());
      expect(t.defaultAudience, AudienceMode.professional);
    });

    test('monthlyReview has correct sections', () {
      final ReportTemplate t = ReportTemplate.monthlyReview;
      expect(t.sections.contains(ReportSection.coverPage), true);
      expect(t.sections.contains(ReportSection.executiveSummary), true);
      expect(t.sections.contains(ReportSection.spendingBreakdown), true);
      expect(t.sections.contains(ReportSection.incomeAnalysis), true);
      expect(t.sections.contains(ReportSection.cashFlow), true);
      expect(t.sections.contains(ReportSection.topMerchants), true);
      expect(t.sections.contains(ReportSection.alerts), true);
      expect(t.sections.contains(ReportSection.coaching), true);
      expect(t.defaultAudience, AudienceMode.personal);
    });

    test('taxPrep has correct sections', () {
      final ReportTemplate t = ReportTemplate.taxPrep;
      expect(t.sections, <ReportSection>[
        ReportSection.coverPage,
        ReportSection.incomeAnalysis,
        ReportSection.spendingBreakdown,
        ReportSection.topMerchants,
        ReportSection.transactionLog,
      ]);
      expect(t.defaultAudience, AudienceMode.professional);
    });

    test('investmentFocus has correct sections', () {
      final ReportTemplate t = ReportTemplate.investmentFocus;
      expect(t.sections, <ReportSection>[
        ReportSection.coverPage,
        ReportSection.executiveSummary,
        ReportSection.investmentPortfolio,
        ReportSection.forecast,
        ReportSection.cashFlow,
      ]);
      expect(t.defaultAudience, AudienceMode.professional);
    });

    test('toReportConfig produces valid config', () {
      final ReportTemplate t = ReportTemplate.quickSummary;
      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      final ReportConfig config = t.toReportConfig(dateRange: range);
      expect(config.enabledSections, t.sections);
      expect(config.audienceMode, t.defaultAudience);
      expect(config.aiEnabled, true);
      expect(config.dateRange, range);
    });
  });
}
