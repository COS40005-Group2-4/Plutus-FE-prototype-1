import 'package:flutter/material.dart';
import 'storage.dart';
import 'widgets/profile_widget.dart';
import 'widgets/roi_widget.dart';
import 'widgets/irr_widget.dart';
import 'widgets/cashflow_widget.dart';
import 'widgets/upcoming_bills_widget.dart';
import 'widgets/tax_estimation_widget.dart';
import 'widgets/investment_widget.dart';
import 'widgets/budget_tracking_widget.dart';
import 'widgets/category_budget_widget.dart';
import 'widgets/transaction_history_widget.dart';
import 'widgets/report_import_widget.dart';
import 'widgets/report_export_widget.dart';
import 'widgets/profile_dashboard_widget.dart';

const Color blue = Color(0xFF4285F4);
const Color red = Color(0xFFEA4335);
const Color yellow = Color(0xFFFBBC05);
const Color green = Color(0xFF34A853);

class DataWidget extends StatelessWidget {
  DataWidget({super.key, required this.item});

  final ColoredDashboardItem item;

  final Map<String, Widget Function(ColoredDashboardItem i)> _map = {
    "profile": (l) => const ProfileDashboardWidget(),
    "budget": (l) => const BudgetTrackingWidget(),
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
