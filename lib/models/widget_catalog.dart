import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum WidgetCategory { overview, analytics, investments, tools }

class WidgetMeta {
  final String widgetType;
  final String label;
  final IconData icon;
  final Color color;
  final WidgetCategory category;
  final bool allowDuplicates;
  final int defaultWidth;
  final int defaultHeight;

  const WidgetMeta({
    required this.widgetType,
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    this.allowDuplicates = true,
    this.defaultWidth = 2,
    this.defaultHeight = 2,
  });
}

class WidgetCatalog {
  WidgetCatalog._();

  static const Map<String, WidgetMeta> all = {
    // ── Overview ──
    'profile': WidgetMeta(
      widgetType: 'profile',
      label: 'Profile',
      icon: Icons.person,
      color: AppColors.profileAccent,
      category: WidgetCategory.overview,
      allowDuplicates: false,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'budget': WidgetMeta(
      widgetType: 'budget',
      label: 'Budget Tracking',
      icon: Icons.account_balance_wallet,
      color: AppColors.budgetAccent,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'categoryBudget': WidgetMeta(
      widgetType: 'categoryBudget',
      label: 'Category Budget',
      icon: Icons.category,
      color: AppColors.categoryBudgetAccent,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'savingsRate': WidgetMeta(
      widgetType: 'savingsRate',
      label: 'Savings Rate',
      icon: Icons.savings,
      color: AppColors.savingsAccent,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'netWorthTrend': WidgetMeta(
      widgetType: 'netWorthTrend',
      label: 'Net Worth Trend',
      icon: Icons.timeline,
      color: AppColors.netWorthAccent,
      category: WidgetCategory.overview,
      defaultWidth: 3,
      defaultHeight: 3,
    ),

    // ── Analytics ──
    'history': WidgetMeta(
      widgetType: 'history',
      label: 'Transaction History',
      icon: Icons.history,
      color: AppColors.historyAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 3,
      defaultHeight: 4,
    ),
    'cashflow': WidgetMeta(
      widgetType: 'cashflow',
      label: 'Cash Flow',
      icon: Icons.waterfall_chart,
      color: AppColors.cashflowAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 3,
      defaultHeight: 3,
    ),
    'expenseBreakdown': WidgetMeta(
      widgetType: 'expenseBreakdown',
      label: 'Expense Breakdown',
      icon: Icons.pie_chart,
      color: AppColors.expenseAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'incomeTrend': WidgetMeta(
      widgetType: 'incomeTrend',
      label: 'Income Trend',
      icon: Icons.trending_up,
      color: AppColors.incomeAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'spendingHeatmap': WidgetMeta(
      widgetType: 'spendingHeatmap',
      label: 'Spending Heatmap',
      icon: Icons.calendar_view_week,
      color: AppColors.heatmapAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'tax': WidgetMeta(
      widgetType: 'tax',
      label: 'Tax Estimation',
      icon: Icons.account_balance,
      color: AppColors.taxAccent,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 2,
    ),

    // ── Investments ──
    'investment': WidgetMeta(
      widgetType: 'investment',
      label: 'Investments',
      icon: Icons.show_chart,
      color: AppColors.primaryDark,
      category: WidgetCategory.investments,
      defaultWidth: 3,
      defaultHeight: 3,
    ),
    'portfolioAllocation': WidgetMeta(
      widgetType: 'portfolioAllocation',
      label: 'Portfolio Allocation',
      icon: Icons.donut_large,
      color: AppColors.primary,
      category: WidgetCategory.investments,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'roi': WidgetMeta(
      widgetType: 'roi',
      label: 'ROI',
      icon: Icons.trending_up,
      color: AppColors.accent,
      category: WidgetCategory.investments,
      defaultWidth: 1,
      defaultHeight: 2,
    ),
    'irr': WidgetMeta(
      widgetType: 'irr',
      label: 'IRR',
      icon: Icons.analytics,
      color: AppColors.accent,
      category: WidgetCategory.investments,
      defaultWidth: 1,
      defaultHeight: 2,
    ),
    'marketTrending': WidgetMeta(
      widgetType: 'marketTrending',
      label: 'Market Trending',
      icon: Icons.candlestick_chart,
      color: AppColors.marketAccent,
      category: WidgetCategory.investments,
      defaultWidth: 2,
      defaultHeight: 3,
    ),

    // ── Tools ──
    'bills': WidgetMeta(
      widgetType: 'bills',
      label: 'Upcoming Bills',
      icon: Icons.receipt_long,
      color: AppColors.billsAccent,
      category: WidgetCategory.tools,
      defaultWidth: 2,
      defaultHeight: 3,
    ),
    'import': WidgetMeta(
      widgetType: 'import',
      label: 'Import Report',
      icon: Icons.upload_file,
      color: AppColors.importAccent,
      category: WidgetCategory.tools,
      defaultWidth: 1,
      defaultHeight: 1,
    ),
    'export': WidgetMeta(
      widgetType: 'export',
      label: 'Export Report',
      icon: Icons.download,
      color: AppColors.exportAccent,
      category: WidgetCategory.tools,
      defaultWidth: 1,
      defaultHeight: 1,
    ),
  };

  static Map<WidgetCategory, List<WidgetMeta>> get grouped {
    final map = <WidgetCategory, List<WidgetMeta>>{};
    for (final cat in WidgetCategory.values) {
      map[cat] = all.values.where((m) => m.category == cat).toList();
    }
    return map;
  }

  static List<WidgetMeta> search(String query) {
    if (query.isEmpty) return all.values.toList();
    final q = query.toLowerCase();
    return all.values.where((m) => m.label.toLowerCase().contains(q)).toList();
  }

  static String categoryLabel(WidgetCategory cat) {
    switch (cat) {
      case WidgetCategory.overview:
        return 'Overview';
      case WidgetCategory.analytics:
        return 'Analytics';
      case WidgetCategory.investments:
        return 'Investments';
      case WidgetCategory.tools:
        return 'Tools';
    }
  }

  static IconData categoryIcon(WidgetCategory cat) {
    switch (cat) {
      case WidgetCategory.overview:
        return Icons.dashboard_outlined;
      case WidgetCategory.analytics:
        return Icons.insights;
      case WidgetCategory.investments:
        return Icons.trending_up;
      case WidgetCategory.tools:
        return Icons.build_outlined;
    }
  }

  static const int maxInstancesPerType = 5;
}
