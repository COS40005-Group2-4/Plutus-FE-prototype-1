import 'package:flutter/foundation.dart';

import '../models/report_config.dart';
import '../models/report_data.dart';
import '../models/report_template.dart';
import '../models/ai/insight.dart';
import '../models/transaction_model.dart';
import '../services/interfaces/interfaces.dart';
import '../providers/insights_provider.dart';
import '../providers/settings_provider.dart';

class ReportProvider extends ChangeNotifier {
  final ITransactionService _transactionService;
  final IInvestmentService _investmentService;
  final IBillService _billService;
  final IBudgetService _budgetService;
  final IReportAiService _reportAiService;
  final IReportPdfService _reportPdfService;
  final IUserService _userService;

  ReportConfig? _config;
  ReportDataModel? _reportData;
  bool _isGenerating = false;
  String? _error;
  double _progress = 0;

  ReportProvider({
    required ITransactionService transactionService,
    required IInvestmentService investmentService,
    required IBillService billService,
    required IBudgetService budgetService,
    required IReportAiService reportAiService,
    required IReportPdfService reportPdfService,
    required IUserService userService,
  })  : _transactionService = transactionService,
        _investmentService = investmentService,
        _billService = billService,
        _budgetService = budgetService,
        _reportAiService = reportAiService,
        _reportPdfService = reportPdfService,
        _userService = userService;

  ReportConfig? get config => _config;
  ReportDataModel? get reportData => _reportData;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  double get progress => _progress;

  void applyTemplate(ReportTemplate template, {required DateRange dateRange}) {
    _config = template.toReportConfig(dateRange: dateRange);
    _reportData = null;
    _error = null;
    notifyListeners();
  }

  void updateConfig(ReportConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  Future<void> generateReport({
    required int? userId,
    InsightsProvider? insightsProvider,
    SettingsProvider? settingsProvider,
  }) async {
    if (_config == null) {
      _error = 'No report configuration set';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    _progress = 0;
    notifyListeners();

    try {
      final ReportConfig cfg = _config!;
      final Set<ReportSection> enabled = cfg.enabledSections.toSet();

      _progress = 0.1;
      notifyListeners();
      String userName = 'User';
      if (userId != null) {
        final user = await _userService.getUserById(userId);
        if (user != null) {
          userName = user.displayName.isNotEmpty ? user.displayName : user.username;
        }
      }

      _progress = 0.2;
      notifyListeners();
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

      _progress = 0.4;
      notifyListeners();

      List<SpendingCategoryData>? spendingCategories;
      if (enabled.contains(ReportSection.spendingBreakdown)) {
        spendingCategories = _buildSpendingCategories(
          transactions, comparisonTransactions, totalExpenses,
        );
      }

      _progress = 0.6;
      notifyListeners();
      HealthScore? healthScore;
      Forecast? forecast;
      List<Alert>? alerts;
      List<CoachingTip>? coachingTips;

      if (insightsProvider != null && insightsProvider.hasInsights) {
        healthScore = insightsProvider.healthScore;
        forecast = insightsProvider.forecast;
        alerts = insightsProvider.alerts;
        coachingTips = insightsProvider.coachingTips;
      }

      _progress = 0.8;
      notifyListeners();
      Map<ReportSection, SectionRecommendation> recommendations =
          <ReportSection, SectionRecommendation>{};

      final List<ReportSection> aiSections = cfg.enabledSections
          .where((ReportSection s) => cfg.aiEnabledForSection(s))
          .toList();

      if (aiSections.isNotEmpty) {
        final String locale = settingsProvider?.language.code ?? 'en';
        final String privacyLevel = settingsProvider?.privacyLevel.name ?? 'standard';

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
            debugPrint('ReportProvider: AI recommendations failed: $e');
          }
        }
      }

      _progress = 0.95;
      notifyListeners();

      _reportData = ReportDataModel(
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

      _progress = 1.0;
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<String?> exportPdf() async {
    if (_reportData == null) return null;

    try {
      final String path = await _reportPdfService.generatePdf(
        data: _reportData!,
        locale: _config?.reportLocale ?? 'en',
      );
      if (kDebugMode) {
        debugPrint('ReportProvider: PDF exported to $path');
      }
      return path;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ReportProvider: PDF export failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _error = 'PDF export failed: $e';
      notifyListeners();
      return null;
    }
  }

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

  void reset() {
    _config = null;
    _reportData = null;
    _error = null;
    _isGenerating = false;
    _progress = 0;
    notifyListeners();
  }
}
