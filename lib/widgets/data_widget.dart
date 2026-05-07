import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'roi_widget.dart';
import 'irr_widget.dart';
import 'cashflow_widget.dart';
import 'upcoming_bills_widget.dart';
import 'tax_estimation_widget.dart';
import 'investment_widget.dart';
import 'budget_summary_widget.dart';
import 'category_budget_widget.dart';
import 'transaction_history_widget.dart';
import 'report_import_widget.dart';
import 'report_export_widget.dart';
import 'profile_dashboard_widget.dart';
import 'expense_breakdown_chart_widget.dart';
import 'portfolio_allocation_widget.dart';
import 'net_worth_trend_widget.dart';
import 'spending_heatmap_widget.dart';
import 'income_trend_widget.dart';
import 'savings_rate_widget.dart';
import 'market_trending_widget.dart';
import 'insights/insights_feed_widget.dart';
import 'insights/health_score_widget.dart';
import 'insights/cash_flow_forecast_widget.dart';
import 'insights/coaching_tips_widget.dart';

const Color blue = AppColors.primary;
const Color red = AppColors.error;
const Color yellow = AppColors.warning;
const Color green = AppColors.success;

class DataWidget extends StatelessWidget {
  DataWidget({super.key, required this.item});

  final ColoredDashboardItem item;

  final Map<String, Widget Function(ColoredDashboardItem i)> _map = {
    "profile": (l) => const ProfileDashboardWidget(),
    "budget": (l) => const BudgetSummaryWidget(),
    "categoryBudget": (l) => const CategoryBudgetWidget(),
    "history": (l) => const TransactionHistoryWidget(),
    "import": (l) => const ReportImportWidget(),
    "export": (l) => const ReportExportWidget(),
    "roi": (l) => const RoiWidget(),
    "irr": (l) => const IrrWidget(),
    "cashflow": (l) => const CashflowWidget(),
    "bills": (l) => const UpcomingBillsWidget(),
    "tax": (l) => const TaxEstimationWidget(),
    "investment": (l) => const InvestmentWidget(),
    "expenseBreakdown": (l) => const ExpenseBreakdownChartWidget(),
    "portfolioAllocation": (l) => const PortfolioAllocationWidget(),
    "netWorthTrend": (l) => const NetWorthTrendWidget(),
    "spendingHeatmap": (l) => const SpendingHeatmapWidget(),
    "incomeTrend": (l) => const IncomeTrendWidget(),
    "savingsRate": (l) => const SavingsRateWidget(),
    "marketTrending": (l) => const MarketTrendingWidget(),
    "insightsFeed": (l) => const InsightsFeedWidget(),
    "healthScore": (l) => const HealthScoreWidget(),
    "cashFlowForecast": (l) => const CashFlowForecastWidget(),
    "coachingTips": (l) => const CoachingTipsWidget(),
  };

  @override
  Widget build(BuildContext context) {
    final dataKey = item.data;
    final builder = dataKey != null ? _map[dataKey] : null;
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(item);
  }
}
