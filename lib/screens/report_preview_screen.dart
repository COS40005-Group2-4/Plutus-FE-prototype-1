import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report_config.dart';
import '../models/report_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/report/cover_section.dart';
import '../widgets/report/executive_summary_section.dart';
import '../widgets/report/spending_breakdown_section.dart';
import '../widgets/report/income_analysis_section.dart';
import '../widgets/report/cash_flow_section.dart';
import '../widgets/report/budget_actual_section.dart';
import '../widgets/report/top_merchants_section.dart';
import '../widgets/report/investment_portfolio_section.dart';
import '../widgets/report/forecast_section.dart';
import '../widgets/report/alerts_section.dart';
import '../widgets/report/coaching_section.dart';
import '../widgets/report/bills_section.dart';
import '../widgets/report/transaction_log_section.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportProvider provider = context.watch<ReportProvider>();
    final ReportDataModel? data = provider.reportData;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'Report Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            tooltip: 'Share',
            onPressed: data == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: data == null
          ? _buildEmpty(provider)
          : _buildContent(context, data),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _exportPdf(context, provider),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              label: const Text(
                'Export PDF',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildEmpty(ReportProvider provider) {
    if (provider.isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Generating report...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            if (provider.progress > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.description_outlined, color: Colors.white24, size: 64),
          SizedBox(height: AppSpacing.lg),
          Text(
            'No report data',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Configure and generate a report first.',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportDataModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.config.enabledSections
            .map((ReportSection section) => _buildSection(section, data))
            .toList(),
      ),
    );
  }

  Widget _buildSection(ReportSection section, ReportDataModel data) {
    switch (section) {
      case ReportSection.coverPage:
        return CoverSection(data: data);
      case ReportSection.executiveSummary:
        return ExecutiveSummarySection(data: data);
      case ReportSection.spendingBreakdown:
        return SpendingBreakdownSection(data: data);
      case ReportSection.incomeAnalysis:
        return IncomeAnalysisSection(data: data);
      case ReportSection.cashFlow:
        return CashFlowSection(data: data);
      case ReportSection.budgetActual:
        return BudgetActualSection(data: data);
      case ReportSection.topMerchants:
        return TopMerchantsSection(data: data);
      case ReportSection.investmentPortfolio:
        return InvestmentPortfolioSection(data: data);
      case ReportSection.forecast:
        return ForecastSection(data: data);
      case ReportSection.alerts:
        return AlertsSection(data: data);
      case ReportSection.coaching:
        return CoachingSection(data: data);
      case ReportSection.billsRecurring:
        return BillsSection(data: data);
      case ReportSection.transactionLog:
        return TransactionLogSection(data: data);
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    ReportProvider provider,
  ) async {
    final String? path = await provider.exportPdf();
    if (!context.mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to $path'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export failed or not supported on this platform.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
