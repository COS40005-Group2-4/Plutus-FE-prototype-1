import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_config.dart';
import '../models/report_data.dart';
import '../models/report_template.dart';
import '../models/ai/insight.dart';
import '../models/transaction_model.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import 'insights_notifier.dart';
import 'settings_notifier.dart';

// ---------------------------------------------------------------------------
// ReportState — immutable value type
// ---------------------------------------------------------------------------

class ReportState {
  final ReportConfig? config;
  final ReportDataModel? reportData;
  final bool isGenerating;
  final String? error;
  final double progress;

  const ReportState({
    this.config,
    this.reportData,
    this.isGenerating = false,
    this.error,
    this.progress = 0.0,
  });

  ReportState copyWith({
    ReportConfig? config,
    ReportDataModel? reportData,
    bool clearReportData = false,
    bool? isGenerating,
    String? error,
    bool clearError = false,
    double? progress,
  }) {
    return ReportState(
      config: config ?? this.config,
      reportData: clearReportData ? null : (reportData ?? this.reportData),
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      progress: progress ?? this.progress,
    );
  }
}

// ---------------------------------------------------------------------------
// ReportNotifier
// ---------------------------------------------------------------------------

class ReportNotifier extends Notifier<ReportState> {
  late ITransactionService _transactionService;
  // ignore: unused_field
  late IInvestmentService _investmentService; // reserved for investment portfolio section
  // ignore: unused_field
  late IBillService _billService; // reserved for bills/recurring section
  // ignore: unused_field
  late IBudgetService _budgetService; // reserved for budget vs actual section
  late IReportAiService _reportAiService;
  late IReportPdfService _reportPdfService;
  late IUserService _userService;

  @override
  ReportState build() {
    _transactionService = sl<ITransactionService>();
    _investmentService = sl<IInvestmentService>();
    _billService = sl<IBillService>();
    _budgetService = sl<IBudgetService>();
    _reportAiService = sl<IReportAiService>();
    _reportPdfService = sl<IReportPdfService>();
    _userService = sl<IUserService>();

    return const ReportState();
  }

  // -------------------------------------------------------------------------
  // Public methods
  // -------------------------------------------------------------------------

  void applyTemplate(ReportTemplate template, {required DateRange dateRange}) {
    state = state.copyWith(
      config: template.toReportConfig(dateRange: dateRange),
      clearReportData: true,
      clearError: true,
    );
  }

  void updateConfig(ReportConfig newConfig) {
    state = state.copyWith(config: newConfig);
  }

  Future<void> generateReport({
    required int? userId,
  }) async {
    if (state.config == null) {
      state = state.copyWith(error: 'No report configuration set');
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      progress: 0.0,
    );

    try {
      final ReportConfig cfg = state.config!;
      final Set<ReportSection> enabled = cfg.enabledSections.toSet();

      state = state.copyWith(progress: 0.1);

      String userName = 'User';
      if (userId != null) {
        final user = await _userService.getUserById(userId);
        if (user != null) {
          userName = user.displayName.isNotEmpty ? user.displayName : user.username;
        }
      }

      state = state.copyWith(progress: 0.2);

      final List<Transaction> allTransactions = await _transactionService.getTransactions();

      final int startSec = cfg.dateRange.start.millisecondsSinceEpoch ~/ 1000;
      final int endSec = cfg.dateRange.end.millisecondsSinceEpoch ~/ 1000;
      final int compStartSec = cfg.dateRange.comparisonStart.millisecondsSinceEpoch ~/ 1000;
      final int compEndSec = cfg.dateRange.comparisonEnd.millisecondsSinceEpoch ~/ 1000;

      final List<Transaction> transactions = allTransactions
          .where((Transaction t) => t.date >= startSec && t.date <= endSec)
          .toList();
      final List<Transaction> comparisonTransactions = allTransactions
          .where((Transaction t) => t.date >= compStartSec && t.date <= compEndSec)
          .toList();

      double totalIncome = 0;
      double totalExpenses = 0;
      double compIncome = 0;
      double compExpenses = 0;
      String currency = '\$';

      for (final Transaction t in transactions) {
        final double amount = t.postings.isNotEmpty ? t.postings.first.amount : 0;
        if (amount > 0) {
          totalIncome += amount;
        } else {
          totalExpenses += amount.abs();
        }
        currency = t.currency;
      }
      for (final Transaction t in comparisonTransactions) {
        final double amount = t.postings.isNotEmpty ? t.postings.first.amount : 0;
        if (amount > 0) {
          compIncome += amount;
        } else {
          compExpenses += amount.abs();
        }
      }

      state = state.copyWith(progress: 0.4);

      List<SpendingCategoryData>? spendingCategories;
      if (enabled.contains(ReportSection.spendingBreakdown)) {
        spendingCategories = _buildSpendingCategories(
          transactions,
          comparisonTransactions,
          totalExpenses,
        );
      }

      state = state.copyWith(progress: 0.6);

      // Read insights from Riverpod provider
      final InsightsState insightsState = ref.read(insightsNotifierProvider);
      HealthScore? healthScore;
      Forecast? forecast;
      List<Alert>? alerts;
      List<CoachingTip>? coachingTips;

      if (insightsState.hasInsights) {
        healthScore = insightsState.healthScore;
        forecast = insightsState.forecast;
        alerts = insightsState.alerts;
        coachingTips = insightsState.coachingTips;
      }

      state = state.copyWith(progress: 0.8);

      Map<ReportSection, SectionRecommendation> recommendations =
          <ReportSection, SectionRecommendation>{};

      final List<ReportSection> aiSections = cfg.enabledSections
          .where((ReportSection s) => cfg.aiEnabledForSection(s))
          .toList();

      if (aiSections.isNotEmpty) {
        final SettingsState settings = ref.read(settingsNotifierProvider);
        final String locale = settings.language.code;
        final String privacyLevel = settings.privacyLevel.name;

        try {
          recommendations = await _reportAiService.getRecommendations(
            sections: aiSections,
            dateRange: cfg.dateRange,
            audienceMode: cfg.audienceMode,
            locale: locale,
            privacyLevel: privacyLevel,
            sectionData: _buildSectionDataPayload(
              spendingCategories: spendingCategories,
              totalIncome: totalIncome,
              totalExpenses: totalExpenses,
              compIncome: compIncome,
              compExpenses: compExpenses,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ReportNotifier: AI recommendations failed: $e');
          }
        }
      }

      state = state.copyWith(progress: 0.95);

      final ReportDataModel reportData = ReportDataModel(
        config: cfg,
        userName: userName,
        generatedAt: DateTime.now(),
        currency: currency,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        comparisonIncome: compIncome,
        comparisonExpenses: compExpenses,
        transactionCount: transactions.length,
        comparisonTransactionCount: comparisonTransactions.length,
        spendingCategories: spendingCategories,
        healthScore: healthScore,
        forecast: forecast,
        alerts: alerts,
        coachingTips: coachingTips,
        recommendations: recommendations,
        transactions: enabled.contains(ReportSection.transactionLog) ? transactions : null,
      );

      state = state.copyWith(
        reportData: reportData,
        progress: 1.0,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isGenerating: false,
      );
    }
  }

  Future<String?> exportPdf() async {
    if (state.reportData == null) return null;

    try {
      final String path = await _reportPdfService.generatePdf(
        data: state.reportData!,
        locale: state.config?.reportLocale ?? 'en',
      );
      if (kDebugMode) {
        debugPrint('ReportNotifier: PDF exported to $path');
      }
      return path;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ReportNotifier: PDF export failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = state.copyWith(error: 'PDF export failed: $e');
      return null;
    }
  }

  void reset() {
    state = const ReportState();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  List<SpendingCategoryData> _buildSpendingCategories(
    List<Transaction> transactions,
    List<Transaction> comparisonTransactions,
    double totalExpenses,
  ) {
    final Map<String, double> categoryTotals = <String, double>{};
    final Map<String, double> compCategoryTotals = <String, double>{};

    for (final Transaction t in transactions) {
      final double amount = t.postings.isNotEmpty ? t.postings.first.amount : 0;
      if (amount < 0) {
        final String account = t.postings.first.account;
        final String cat = account.contains(':') ? account.split(':').last : account;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount.abs();
      }
    }
    for (final Transaction t in comparisonTransactions) {
      final double amount = t.postings.isNotEmpty ? t.postings.first.amount : 0;
      if (amount < 0) {
        final String account = t.postings.first.account;
        final String cat = account.contains(':') ? account.split(':').last : account;
        compCategoryTotals[cat] = (compCategoryTotals[cat] ?? 0) + amount.abs();
      }
    }

    final List<SpendingCategoryData> result = categoryTotals.entries
        .map((MapEntry<String, double> e) => SpendingCategoryData(
              category: e.key,
              amount: e.value,
              totalSpending: totalExpenses,
              comparisonAmount: compCategoryTotals[e.key] ?? 0,
            ))
        .toList()
      ..sort((SpendingCategoryData a, SpendingCategoryData b) =>
          b.amount.compareTo(a.amount));

    return result;
  }

  Map<String, dynamic> _buildSectionDataPayload({
    List<SpendingCategoryData>? spendingCategories,
    required double totalIncome,
    required double totalExpenses,
    required double compIncome,
    required double compExpenses,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{};

    if (spendingCategories != null) {
      payload['spending_breakdown'] = <String, dynamic>{
        'categories': spendingCategories
            .map((SpendingCategoryData c) => <String, dynamic>{
                  'name': c.category,
                  'amount': c.amount,
                  'percentage': c.percentage,
                  'changePercent': c.changePercent,
                })
            .toList(),
        'total': totalExpenses,
        'comparisonTotal': compExpenses,
      };
    }

    payload['income_analysis'] = <String, dynamic>{
      'total': totalIncome,
      'comparisonTotal': compIncome,
    };

    return payload;
  }
}

// ---------------------------------------------------------------------------
// Provider definition
// ---------------------------------------------------------------------------

final reportNotifierProvider =
    NotifierProvider<ReportNotifier, ReportState>(ReportNotifier.new);
