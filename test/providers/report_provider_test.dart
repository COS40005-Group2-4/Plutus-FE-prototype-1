import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/report_config.dart';
import 'package:plutus_fe_prototype/models/report_template.dart';
import 'package:plutus_fe_prototype/models/ai/insight.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';
import 'package:plutus_fe_prototype/providers/insights_notifier.dart';
import 'package:plutus_fe_prototype/providers/report_notifier.dart';
import 'package:plutus_fe_prototype/providers/settings_notifier.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_transaction_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_investment_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_bill_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_report_ai_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_report_pdf_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_user_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_insights_service.dart';
import '../helpers/mock_services.mocks.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — return fixed states without requiring GetIt services
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthUnauthenticated();
}

class FakeInsightsNotifier extends InsightsNotifier {
  @override
  InsightsState build() => const InsightsState();
}

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}

void main() {
  late MockITransactionService mockTransactionService;
  late MockIInvestmentService mockInvestmentService;
  late MockIBillService mockBillService;
  late MockIBudgetService mockBudgetService;
  late MockIReportAiService mockReportAiService;
  late MockIReportPdfService mockReportPdfService;
  late MockIUserService mockUserService;
  final GetIt sl = GetIt.instance;

  setUp(() async {
    mockTransactionService = MockITransactionService();
    mockInvestmentService = MockIInvestmentService();
    mockBillService = MockIBillService();
    mockBudgetService = MockIBudgetService();
    mockReportAiService = MockIReportAiService();
    mockReportPdfService = MockIReportPdfService();
    mockUserService = MockIUserService();

    // Register mocks in GetIt
    Future<void> register<T extends Object>(T mock) async {
      if (sl.isRegistered<T>()) await sl.unregister<T>();
      sl.registerSingleton<T>(mock);
    }

    await register<ITransactionService>(mockTransactionService);
    await register<IInvestmentService>(mockInvestmentService);
    await register<IBillService>(mockBillService);
    await register<IBudgetService>(mockBudgetService);
    await register<IReportAiService>(mockReportAiService);
    await register<IReportPdfService>(mockReportPdfService);
    await register<IUserService>(mockUserService);
  });

  tearDown(() async {
    Future<void> unregister<T extends Object>() async {
      if (sl.isRegistered<T>()) await sl.unregister<T>();
    }

    await unregister<ITransactionService>();
    await unregister<IInvestmentService>();
    await unregister<IBillService>();
    await unregister<IBudgetService>();
    await unregister<IReportAiService>();
    await unregister<IReportPdfService>();
    await unregister<IUserService>();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
        insightsNotifierProvider.overrideWith(() => FakeInsightsNotifier()),
        settingsNotifierProvider.overrideWith(() => FakeSettingsNotifier()),
      ],
    );
  }

  group('ReportNotifier', () {
    test('initial state is idle', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(reportNotifierProvider);

      expect(state.isGenerating, false);
      expect(state.reportData, null);
      expect(state.error, null);
    });

    test('applyTemplate sets config from template', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reportNotifierProvider.notifier);

      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      notifier.applyTemplate(ReportTemplate.quickSummary, dateRange: range);

      final state = container.read(reportNotifierProvider);
      expect(state.config, isNotNull);
      expect(state.config!.enabledSections.length, 4);
      expect(state.config!.audienceMode, AudienceMode.personal);
    });

    test('updateConfig changes config', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reportNotifierProvider.notifier);

      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      notifier.applyTemplate(ReportTemplate.quickSummary, dateRange: range);

      final config = container.read(reportNotifierProvider).config!;
      notifier.updateConfig(config.copyWith(audienceMode: AudienceMode.professional));

      final state = container.read(reportNotifierProvider);
      expect(state.config!.audienceMode, AudienceMode.professional);
    });

    test('reset clears state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reportNotifierProvider.notifier);

      final DateRange range = DateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
        comparisonStart: DateTime(2026, 2, 1),
        comparisonEnd: DateTime(2026, 2, 28),
      );

      notifier.applyTemplate(ReportTemplate.quickSummary, dateRange: range);
      expect(container.read(reportNotifierProvider).config, isNotNull);

      notifier.reset();
      expect(container.read(reportNotifierProvider).config, isNull);
      expect(container.read(reportNotifierProvider).reportData, isNull);
    });
  });
}
