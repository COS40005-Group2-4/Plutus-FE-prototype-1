import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';
import 'package:plutus_fe_prototype/models/report_data.dart';
import 'package:plutus_fe_prototype/models/report_template.dart';
import 'package:plutus_fe_prototype/models/ai/insight.dart';
import 'package:plutus_fe_prototype/providers/report_provider.dart';

import '../helpers/mock_services.mocks.dart';

void main() {
  late MockITransactionService mockTransactionService;
  late MockIInvestmentService mockInvestmentService;
  late MockIBillService mockBillService;
  late MockIBudgetService mockBudgetService;
  late MockIReportAiService mockReportAiService;
  late MockIReportPdfService mockReportPdfService;
  late MockIUserService mockUserService;

  setUp(() {
    mockTransactionService = MockITransactionService();
    mockInvestmentService = MockIInvestmentService();
    mockBillService = MockIBillService();
    mockBudgetService = MockIBudgetService();
    mockReportAiService = MockIReportAiService();
    mockReportPdfService = MockIReportPdfService();
    mockUserService = MockIUserService();
  });

  group('ReportProvider', () {
    test('initial state is idle', () {
      final ReportProvider provider = ReportProvider(
        transactionService: mockTransactionService,
        investmentService: mockInvestmentService,
        billService: mockBillService,
        budgetService: mockBudgetService,
        reportAiService: mockReportAiService,
        reportPdfService: mockReportPdfService,
        userService: mockUserService,
      );

      expect(provider.isGenerating, false);
      expect(provider.reportData, null);
      expect(provider.error, null);
    });

    test('applyTemplate sets config from template', () {
      final ReportProvider provider = ReportProvider(
        transactionService: mockTransactionService,
        investmentService: mockInvestmentService,
        billService: mockBillService,
        budgetService: mockBudgetService,
        reportAiService: mockReportAiService,
        reportPdfService: mockReportPdfService,
        userService: mockUserService,
      );

      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      provider.applyTemplate(ReportTemplate.quickSummary, dateRange: range);

      expect(provider.config, isNotNull);
      expect(provider.config!.enabledSections.length, 4);
      expect(provider.config!.audienceMode, AudienceMode.personal);
    });

    test('updateConfig changes config and notifies', () {
      final ReportProvider provider = ReportProvider(
        transactionService: mockTransactionService,
        investmentService: mockInvestmentService,
        billService: mockBillService,
        budgetService: mockBudgetService,
        reportAiService: mockReportAiService,
        reportPdfService: mockReportPdfService,
        userService: mockUserService,
      );

      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      provider.applyTemplate(ReportTemplate.quickSummary, dateRange: range);

      bool notified = false;
      provider.addListener(() => notified = true);

      provider.updateConfig(provider.config!.copyWith(
        audienceMode: AudienceMode.professional,
      ));

      expect(provider.config!.audienceMode, AudienceMode.professional);
      expect(notified, true);
    });
  });
}
