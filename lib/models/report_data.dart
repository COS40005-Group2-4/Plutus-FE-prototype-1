import 'package:equatable/equatable.dart';
import 'report_config.dart';
import 'ai/insight.dart';
import 'transaction_model.dart';

class SectionRecommendation extends Equatable {
  final String oneLiner;
  final String detailed;

  const SectionRecommendation({
    required this.oneLiner,
    required this.detailed,
  });

  factory SectionRecommendation.fromJson(Map<String, dynamic> json) {
    return SectionRecommendation(
      oneLiner: json['oneLiner'] as String,
      detailed: json['detailed'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'oneLiner': oneLiner,
      'detailed': detailed,
    };
  }

  @override
  List<Object?> get props => <Object?>[oneLiner, detailed];
}

class SpendingCategoryData extends Equatable {
  final String category;
  final double amount;
  final double totalSpending;
  final double comparisonAmount;

  const SpendingCategoryData({
    required this.category,
    required this.amount,
    required this.totalSpending,
    required this.comparisonAmount,
  });

  double get percentage => totalSpending > 0 ? (amount / totalSpending) * 100 : 0;

  double get changePercent =>
      comparisonAmount > 0 ? ((amount - comparisonAmount) / comparisonAmount) * 100 : 0;

  @override
  List<Object?> get props => <Object?>[category, amount, totalSpending, comparisonAmount];
}

class IncomeSourceData extends Equatable {
  final String source;
  final double amount;
  final double variance;

  const IncomeSourceData({
    required this.source,
    required this.amount,
    required this.variance,
  });

  @override
  List<Object?> get props => <Object?>[source, amount, variance];
}

class MerchantData extends Equatable {
  final String name;
  final String category;
  final double amount;
  final int transactionCount;
  final double changePercent;

  const MerchantData({
    required this.name,
    required this.category,
    required this.amount,
    required this.transactionCount,
    required this.changePercent,
  });

  @override
  List<Object?> get props => <Object?>[name, category, amount, transactionCount, changePercent];
}

class BudgetCategoryData extends Equatable {
  final String category;
  final double actual;
  final double budget;

  const BudgetCategoryData({
    required this.category,
    required this.actual,
    required this.budget,
  });

  double get percentage => budget > 0 ? (actual / budget) * 100 : 0;
  bool get isOverBudget => actual > budget;

  @override
  List<Object?> get props => <Object?>[category, actual, budget];
}

class BillData extends Equatable {
  final String name;
  final String category;
  final String frequency;
  final double amount;
  final double? previousAmount;
  final DateTime? nextDue;
  final String status;

  const BillData({
    required this.name,
    required this.category,
    required this.frequency,
    required this.amount,
    this.previousAmount,
    this.nextDue,
    required this.status,
  });

  double? get changePercent =>
      previousAmount != null && previousAmount! > 0
          ? ((amount - previousAmount!) / previousAmount!) * 100
          : null;

  @override
  List<Object?> get props =>
      <Object?>[name, category, frequency, amount, previousAmount, nextDue, status];
}

class InvestmentHoldingData extends Equatable {
  final String ticker;
  final String name;
  final double value;
  final double allocation;
  final double returnPercent;

  const InvestmentHoldingData({
    required this.ticker,
    required this.name,
    required this.value,
    required this.allocation,
    required this.returnPercent,
  });

  @override
  List<Object?> get props => <Object?>[ticker, name, value, allocation, returnPercent];
}

class ReportDataModel {
  final ReportConfig config;
  final String userName;
  final DateTime generatedAt;
  final String currency;

  final double totalIncome;
  final double totalExpenses;
  final double comparisonIncome;
  final double comparisonExpenses;
  final int transactionCount;
  final int comparisonTransactionCount;

  final List<SpendingCategoryData>? spendingCategories;
  final List<IncomeSourceData>? incomeSources;
  final List<double>? incomeHistory;
  final List<MerchantData>? topMerchants;
  final List<BudgetCategoryData>? budgetCategories;
  final List<InvestmentHoldingData>? holdings;
  final double? portfolioTotalValue;
  final double? portfolioReturnPercent;
  final double? portfolioTotalGain;
  final List<BillData>? bills;
  final List<Transaction>? transactions;

  final HealthScore? healthScore;
  final Forecast? forecast;
  final List<Alert>? alerts;
  final List<CoachingTip>? coachingTips;

  final Map<ReportSection, SectionRecommendation> recommendations;

  ReportDataModel({
    required this.config,
    required this.userName,
    required this.generatedAt,
    required this.currency,
    required this.totalIncome,
    required this.totalExpenses,
    required this.comparisonIncome,
    required this.comparisonExpenses,
    required this.transactionCount,
    required this.comparisonTransactionCount,
    this.spendingCategories,
    this.incomeSources,
    this.incomeHistory,
    this.topMerchants,
    this.budgetCategories,
    this.holdings,
    this.portfolioTotalValue,
    this.portfolioReturnPercent,
    this.portfolioTotalGain,
    this.bills,
    this.transactions,
    this.healthScore,
    this.forecast,
    this.alerts,
    this.coachingTips,
    this.recommendations = const <ReportSection, SectionRecommendation>{},
  });

  double get netSavings => totalIncome - totalExpenses;
  double get comparisonNetSavings => comparisonIncome - comparisonExpenses;
  double get savingsRate => totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;
  double get comparisonSavingsRate =>
      comparisonIncome > 0 ? (comparisonNetSavings / comparisonIncome) * 100 : 0;

  List<ReportSection> get sectionsNeedingAi {
    return config.enabledSections
        .where((ReportSection s) => config.aiEnabledForSection(s))
        .toList();
  }

  int get overBudgetCount =>
      budgetCategories?.where((BudgetCategoryData b) => b.isOverBudget).length ?? 0;
  int get activeBillCount => bills?.length ?? 0;
  double get totalRecurring =>
      bills?.fold<double>(0, (double sum, BillData b) => sum + b.amount) ?? 0;
}
