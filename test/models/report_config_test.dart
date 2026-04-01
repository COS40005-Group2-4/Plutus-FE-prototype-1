// test/models/report_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';

void main() {
  group('ReportSection', () {
    test('has all 13 sections', () {
      expect(ReportSection.values.length, 13);
    });

    test('serializes to snake_case string', () {
      expect(ReportSection.coverPage.name, 'coverPage');
      expect(ReportSection.executiveSummary.name, 'executiveSummary');
    });
  });

  group('DateRangePreset', () {
    test('thisMonth calculates current month range', () {
      final DateRangePreset preset = DateRangePreset.thisMonth;
      final DateTime now = DateTime.now();
      final DateRange range = preset.calculate(now);

      expect(range.start, DateTime(now.year, now.month, 1));
      expect(range.end.year, now.year);
      expect(range.end.month, now.month);
      expect(range.end.day, now.day);
    });

    test('thisMonth comparison is same days of previous month', () {
      final DateTime now = DateTime(2026, 3, 15);
      final DateRange range = DateRangePreset.thisMonth.calculate(now);

      expect(range.comparisonStart, DateTime(2026, 2, 1));
      expect(range.comparisonEnd, DateTime(2026, 2, 15));
    });

    test('lastQuarter calculates previous 3 calendar months', () {
      final DateTime now = DateTime(2026, 4, 2);
      final DateRange range = DateRangePreset.lastQuarter.calculate(now);

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 3, 31));
      expect(range.comparisonStart, DateTime(2025, 10, 1));
      expect(range.comparisonEnd, DateTime(2025, 12, 31));
    });

    test('yearToDate calculates Jan 1 to today', () {
      final DateTime now = DateTime(2026, 4, 2);
      final DateRange range = DateRangePreset.yearToDate.calculate(now);

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 4, 2));
      expect(range.comparisonStart, DateTime(2025, 1, 1));
      expect(range.comparisonEnd, DateTime(2025, 4, 2));
    });

    test('last12Months calculates 12 calendar months back', () {
      final DateTime now = DateTime(2026, 4, 2);
      final DateRange range = DateRangePreset.last12Months.calculate(now);

      expect(range.start, DateTime(2025, 4, 1));
      expect(range.end, DateTime(2026, 3, 31));
      expect(range.comparisonStart, DateTime(2024, 4, 1));
      expect(range.comparisonEnd, DateTime(2025, 3, 31));
    });
  });

  group('ReportConfig', () {
    test('creates with defaults', () {
      final ReportConfig config = ReportConfig(
        enabledSections: <ReportSection>[
          ReportSection.coverPage,
          ReportSection.executiveSummary,
        ],
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
      );

      expect(config.audienceMode, AudienceMode.personal);
      expect(config.aiEnabled, true);
      expect(config.enabledSections.length, 2);
    });

    test('aiEnabledForSection respects master toggle', () {
      final ReportConfig config = ReportConfig(
        enabledSections: <ReportSection>[ReportSection.spendingBreakdown],
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
        aiEnabled: false,
      );

      expect(config.aiEnabledForSection(ReportSection.spendingBreakdown), false);
    });

    test('aiEnabledForSection respects per-section toggle', () {
      final ReportConfig config = ReportConfig(
        enabledSections: <ReportSection>[ReportSection.spendingBreakdown],
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
        aiEnabled: true,
        aiDisabledSections: <ReportSection>{ReportSection.spendingBreakdown},
      );

      expect(config.aiEnabledForSection(ReportSection.spendingBreakdown), false);
      expect(config.aiEnabledForSection(ReportSection.incomeAnalysis), true);
    });

    test('sections with no AI always return false', () {
      final ReportConfig config = ReportConfig(
        enabledSections: ReportSection.values.toList(),
        dateRange: DateRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          comparisonStart: DateTime(2026, 2, 1),
          comparisonEnd: DateTime(2026, 2, 28),
        ),
        aiEnabled: true,
      );

      expect(config.aiEnabledForSection(ReportSection.coverPage), false);
      expect(config.aiEnabledForSection(ReportSection.transactionLog), false);
    });
  });
}
