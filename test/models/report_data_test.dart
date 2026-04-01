import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';
import 'package:plutus_fe_prototype/models/report_data.dart';

void main() {
  group('SectionRecommendation', () {
    test('creates from JSON', () {
      final SectionRecommendation rec = SectionRecommendation.fromJson(<String, dynamic>{
        'oneLiner': 'Groceries spiked 18%.',
        'detailed': 'Your grocery-to-dining ratio shifted...',
      });

      expect(rec.oneLiner, 'Groceries spiked 18%.');
      expect(rec.detailed, 'Your grocery-to-dining ratio shifted...');
    });

    test('serializes to JSON', () {
      const SectionRecommendation rec = SectionRecommendation(
        oneLiner: 'Test one-liner.',
        detailed: 'Test detailed.',
      );

      final Map<String, dynamic> json = rec.toJson();
      expect(json['oneLiner'], 'Test one-liner.');
      expect(json['detailed'], 'Test detailed.');
    });
  });

  group('SpendingCategoryData', () {
    test('calculates percentage', () {
      final SpendingCategoryData data = SpendingCategoryData(
        category: 'Housing',
        amount: 950.0,
        totalSpending: 2847.0,
        comparisonAmount: 950.0,
      );

      expect(data.percentage, closeTo(33.4, 0.1));
      expect(data.changePercent, closeTo(0.0, 0.1));
    });

    test('calculates MoM change', () {
      final SpendingCategoryData data = SpendingCategoryData(
        category: 'Groceries',
        amount: 632.0,
        totalSpending: 2847.0,
        comparisonAmount: 535.0,
      );

      expect(data.changePercent, closeTo(18.1, 0.2));
    });
  });

  group('ReportDataModel', () {
    test('creates with required fields only', () {
      final ReportDataModel model = ReportDataModel(
        config: ReportConfig(
          enabledSections: <ReportSection>[ReportSection.coverPage],
          dateRange: DateRange(
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 31),
            comparisonStart: DateTime(2026, 2, 1),
            comparisonEnd: DateTime(2026, 2, 28),
          ),
        ),
        userName: 'Anh',
        generatedAt: DateTime(2026, 4, 2),
        totalIncome: 4230.0,
        totalExpenses: 2847.0,
        comparisonIncome: 4200.0,
        comparisonExpenses: 3105.0,
        transactionCount: 142,
        comparisonTransactionCount: 150,
        currency: '\$',
      );

      expect(model.netSavings, closeTo(1383.0, 0.01));
      expect(model.savingsRate, closeTo(32.7, 0.1));
      expect(model.comparisonNetSavings, closeTo(1095.0, 0.01));
    });

    test('sectionsWithAiRecommendations filters correctly', () {
      final ReportDataModel model = ReportDataModel(
        config: ReportConfig(
          enabledSections: <ReportSection>[
            ReportSection.coverPage,
            ReportSection.spendingBreakdown,
            ReportSection.transactionLog,
          ],
          dateRange: DateRange(
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 31),
            comparisonStart: DateTime(2026, 2, 1),
            comparisonEnd: DateTime(2026, 2, 28),
          ),
        ),
        userName: 'Test',
        generatedAt: DateTime.now(),
        totalIncome: 0,
        totalExpenses: 0,
        comparisonIncome: 0,
        comparisonExpenses: 0,
        transactionCount: 0,
        comparisonTransactionCount: 0,
        currency: '\$',
      );

      final List<ReportSection> aiSections = model.sectionsNeedingAi;
      expect(aiSections.contains(ReportSection.coverPage), false);
      expect(aiSections.contains(ReportSection.spendingBreakdown), true);
      expect(aiSections.contains(ReportSection.transactionLog), false);
    });
  });
}
