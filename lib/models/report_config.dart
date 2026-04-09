// lib/models/report_config.dart
import 'package:equatable/equatable.dart';

enum ReportSection {
  coverPage,
  executiveSummary,
  spendingBreakdown,
  incomeAnalysis,
  cashFlow,
  budgetActual,
  topMerchants,
  investmentPortfolio,
  forecast,
  alerts,
  coaching,
  billsRecurring,
  transactionLog,
}

enum AudienceMode { personal, professional }

enum DateRangePreset { thisMonth, lastQuarter, yearToDate, last12Months, custom }

/// Sections that never show AI recommendations.
const Set<ReportSection> _noAiSections = <ReportSection>{
  ReportSection.coverPage,
  ReportSection.transactionLog,
};

class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;
  final DateTime comparisonStart;
  final DateTime comparisonEnd;

  const DateRange({
    required this.start,
    required this.end,
    required this.comparisonStart,
    required this.comparisonEnd,
  });

  @override
  List<Object?> get props => <Object?>[start, end, comparisonStart, comparisonEnd];
}

class ReportConfig extends Equatable {
  final List<ReportSection> enabledSections;
  final DateRange dateRange;
  final AudienceMode audienceMode;
  final bool aiEnabled;
  final Set<ReportSection> aiDisabledSections;
  final String reportLocale;

  const ReportConfig({
    required this.enabledSections,
    required this.dateRange,
    this.audienceMode = AudienceMode.personal,
    this.aiEnabled = true,
    this.aiDisabledSections = const <ReportSection>{},
    this.reportLocale = 'en',
  });

  bool aiEnabledForSection(ReportSection section) {
    if (!aiEnabled) return false;
    if (_noAiSections.contains(section)) return false;
    if (aiDisabledSections.contains(section)) return false;
    return true;
  }

  ReportConfig copyWith({
    List<ReportSection>? enabledSections,
    DateRange? dateRange,
    AudienceMode? audienceMode,
    bool? aiEnabled,
    Set<ReportSection>? aiDisabledSections,
    String? reportLocale,
  }) {
    return ReportConfig(
      enabledSections: enabledSections ?? this.enabledSections,
      dateRange: dateRange ?? this.dateRange,
      audienceMode: audienceMode ?? this.audienceMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiDisabledSections: aiDisabledSections ?? this.aiDisabledSections,
      reportLocale: reportLocale ?? this.reportLocale,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        enabledSections,
        dateRange,
        audienceMode,
        aiEnabled,
        aiDisabledSections,
        reportLocale,
      ];
}

extension DateRangePresetCalculation on DateRangePreset {
  DateRange calculate(DateTime now) {
    switch (this) {
      case DateRangePreset.thisMonth:
        final DateTime start = DateTime(now.year, now.month, 1);
        final DateTime end = DateTime(now.year, now.month, now.day);
        final DateTime compStart = DateTime(now.year, now.month - 1, 1);
        final DateTime compEnd = DateTime(now.year, now.month - 1, now.day);
        return DateRange(
          start: start,
          end: end,
          comparisonStart: compStart,
          comparisonEnd: compEnd,
        );

      case DateRangePreset.lastQuarter:
        final int qEndMonth = now.month - 1;
        final int qStartMonth = qEndMonth - 2;
        final DateTime start = DateTime(now.year, qStartMonth, 1);
        final DateTime end = DateTime(now.year, qEndMonth + 1, 0); // last day of qEndMonth
        final DateTime compStart = DateTime(now.year, qStartMonth - 3, 1);
        final DateTime compEnd = DateTime(now.year, qStartMonth, 0); // last day of month before qStartMonth
        return DateRange(
          start: start,
          end: end,
          comparisonStart: compStart,
          comparisonEnd: compEnd,
        );

      case DateRangePreset.yearToDate:
        final DateTime start = DateTime(now.year, 1, 1);
        final DateTime end = DateTime(now.year, now.month, now.day);
        final DateTime compStart = DateTime(now.year - 1, 1, 1);
        final DateTime compEnd = DateTime(now.year - 1, now.month, now.day);
        return DateRange(
          start: start,
          end: end,
          comparisonStart: compStart,
          comparisonEnd: compEnd,
        );

      case DateRangePreset.last12Months:
        final DateTime start = DateTime(now.year - 1, now.month, 1);
        final DateTime end = DateTime(now.year, now.month, 0); // last day of prev month
        final DateTime compStart = DateTime(now.year - 2, now.month, 1);
        final DateTime compEnd = DateTime(now.year - 1, now.month, 0);
        return DateRange(
          start: start,
          end: end,
          comparisonStart: compStart,
          comparisonEnd: compEnd,
        );

      case DateRangePreset.custom:
        throw StateError('Custom preset requires manual DateRange construction');
    }
  }
}
