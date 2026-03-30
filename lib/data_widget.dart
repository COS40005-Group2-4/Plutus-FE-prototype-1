import 'package:flutter/material.dart';
import 'storage.dart';
import 'theme/app_colors.dart';
import 'widgets/roi_widget.dart';
import 'widgets/irr_widget.dart';
import 'widgets/cashflow_widget.dart';
import 'widgets/upcoming_bills_widget.dart';
import 'widgets/tax_estimation_widget.dart';
import 'widgets/investment_widget.dart';
import 'widgets/budget_summary_widget.dart';
import 'widgets/category_budget_widget.dart';
import 'widgets/transaction_history_widget.dart';
import 'widgets/report_import_widget.dart';
import 'widgets/report_export_widget.dart';
import 'widgets/profile_dashboard_widget.dart';
import 'widgets/expense_breakdown_chart_widget.dart';
import 'widgets/portfolio_allocation_widget.dart';
import 'widgets/net_worth_trend_widget.dart';
import 'widgets/spending_heatmap_widget.dart';
import 'widgets/income_trend_widget.dart';
import 'widgets/savings_rate_widget.dart';
import 'widgets/market_trending_widget.dart';
import 'widgets/insights/insights_feed_widget.dart';
import 'widgets/insights/health_score_widget.dart';
import 'widgets/insights/cash_flow_forecast_widget.dart';
import 'widgets/insights/coaching_tips_widget.dart';

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
