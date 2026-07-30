import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum WidgetCategory { overview, analytics, investments, tools, insights }

class WidgetMeta {
  final String widgetType;
  final String label;
  final IconData icon;
  final WidgetCategory category;
  final bool allowDuplicates;
  final int defaultWidth;
  final int defaultHeight;

  const WidgetMeta({
    required this.widgetType,
    required this.label,
    required this.icon,
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
      label: 'widget_label_profile',
      icon: Icons.person,
      category: WidgetCategory.overview,
      allowDuplicates: false,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'budget': WidgetMeta(
      widgetType: 'budget',
      label: 'widget_label_budget',
      icon: Icons.account_balance_wallet,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 1,
    ),
    'categoryBudget': WidgetMeta(
      widgetType: 'categoryBudget',
      label: 'widget_label_category_budget',
      icon: Icons.category,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'savingsRate': WidgetMeta(
      widgetType: 'savingsRate',
      label: 'widget_label_savings_rate',
      icon: Icons.savings,
      category: WidgetCategory.overview,
      defaultWidth: 2,
      defaultHeight: 1,
    ),
    'netWorthTrend': WidgetMeta(
      widgetType: 'netWorthTrend',
      label: 'widget_label_net_worth_trend',
      icon: Icons.timeline,
      category: WidgetCategory.overview,
      defaultWidth: 3,
      defaultHeight: 2,
    ),

    // ── Analytics ──
    'history': WidgetMeta(
      widgetType: 'history',
      label: 'widget_label_history',
      icon: Icons.history,
      category: WidgetCategory.analytics,
      defaultWidth: 3,
      defaultHeight: 4,
    ),
    'cashflow': WidgetMeta(
      widgetType: 'cashflow',
      label: 'widget_label_cashflow',
      icon: Icons.waterfall_chart,
      category: WidgetCategory.analytics,
      defaultWidth: 3,
      defaultHeight: 2,
    ),
    'expenseBreakdown': WidgetMeta(
      widgetType: 'expenseBreakdown',
      label: 'widget_label_expense_breakdown',
      icon: Icons.pie_chart,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'incomeTrend': WidgetMeta(
      widgetType: 'incomeTrend',
      label: 'widget_label_income_trend',
      icon: Icons.trending_up,
      category: WidgetCategory.analytics,
      defaultWidth: 3,
      defaultHeight: 2,
    ),
    'spendingHeatmap': WidgetMeta(
      widgetType: 'spendingHeatmap',
      label: 'widget_label_spending_heatmap',
      icon: Icons.calendar_view_week,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'tax': WidgetMeta(
      widgetType: 'tax',
      label: 'widget_label_tax',
      icon: Icons.account_balance,
      category: WidgetCategory.analytics,
      defaultWidth: 2,
      defaultHeight: 2,
    ),

    // ── Investments ──
    'investment': WidgetMeta(
      widgetType: 'investment',
      label: 'widget_label_investment',
      icon: Icons.show_chart,
      category: WidgetCategory.investments,
      defaultWidth: 3,
      defaultHeight: 3,
    ),
    'portfolioAllocation': WidgetMeta(
      widgetType: 'portfolioAllocation',
      label: 'widget_label_portfolio_allocation',
      icon: Icons.donut_large,
      category: WidgetCategory.investments,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'roi': WidgetMeta(
      widgetType: 'roi',
      label: 'widget_label_roi',
      icon: Icons.trending_up,
      category: WidgetCategory.investments,
      defaultWidth: 1,
      defaultHeight: 1,
    ),
    'irr': WidgetMeta(
      widgetType: 'irr',
      label: 'widget_label_irr',
      icon: Icons.analytics,
      category: WidgetCategory.investments,
      defaultWidth: 1,
      defaultHeight: 1,
    ),
    'marketTrending': WidgetMeta(
      widgetType: 'marketTrending',
      label: 'widget_label_market_trending',
      icon: Icons.candlestick_chart,
      category: WidgetCategory.investments,
      defaultWidth: 2,
      defaultHeight: 3,
    ),

    // ── Tools ──
    'bills': WidgetMeta(
      widgetType: 'bills',
      label: 'widget_label_bills',
      icon: Icons.receipt_long,
      category: WidgetCategory.tools,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'import': WidgetMeta(
      widgetType: 'import',
      label: 'widget_label_import',
      icon: Icons.upload_file,
      category: WidgetCategory.tools,
      defaultWidth: 1,
      defaultHeight: 1,
    ),
    'export': WidgetMeta(
      widgetType: 'export',
      label: 'widget_label_export',
      icon: Icons.download,
      category: WidgetCategory.tools,
      defaultWidth: 1,
      defaultHeight: 1,
    ),

    // ── Insights ──
    'insightsFeed': WidgetMeta(
      widgetType: 'insightsFeed',
      label: 'widget_label_insights_feed',
      icon: Icons.lightbulb_outline,
      category: WidgetCategory.insights,
      defaultWidth: 3,
      defaultHeight: 3,
    ),
    'healthScore': WidgetMeta(
      widgetType: 'healthScore',
      label: 'widget_label_health_score',
      icon: Icons.health_and_safety,
      category: WidgetCategory.insights,
      defaultWidth: 2,
      defaultHeight: 2,
    ),
    'cashFlowForecast': WidgetMeta(
      widgetType: 'cashFlowForecast',
      label: 'widget_label_cash_flow_forecast',
      icon: Icons.auto_graph,
      category: WidgetCategory.insights,
      defaultWidth: 3,
      defaultHeight: 2,
    ),
    'coachingTips': WidgetMeta(
      widgetType: 'coachingTips',
      label: 'widget_label_coaching_tips',
      icon: Icons.school,
      category: WidgetCategory.insights,
      defaultWidth: 2,
      defaultHeight: 2,
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

  static String categoryLabelKey(WidgetCategory cat) {
    switch (cat) {
      case WidgetCategory.overview:
        return 'widget_cat_overview';
      case WidgetCategory.analytics:
        return 'widget_cat_analytics';
      case WidgetCategory.investments:
        return 'widget_cat_investments';
      case WidgetCategory.tools:
        return 'widget_cat_tools';
      case WidgetCategory.insights:
        return 'widget_cat_insights';
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
      case WidgetCategory.insights:
        return Icons.lightbulb_outline;
    }
  }

  static List<WidgetMeta> searchLocalized(String query, AppLocalizations l10n) {
    if (query.isEmpty) return all.values.toList();
    final q = query.toLowerCase();
    return all.values
        .where((m) => l10n.translate(m.label).toLowerCase().contains(q))
        .toList();
  }

  static const int maxInstancesPerType = 5;
}
