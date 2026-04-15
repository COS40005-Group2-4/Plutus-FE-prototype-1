import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../providers/report_notifier.dart';
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

class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ReportState reportState = ref.watch(reportNotifierProvider);
    final ReportDataModel? data = reportState.reportData;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(
          l10n.translate('report_preview'),
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textOnDarkSecondary),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textOnDarkSecondary),
            tooltip: l10n.translate('report_share'),
            onPressed: data == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.translate('report_share_soon')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: data == null
          ? _buildEmpty(context, reportState)
          : _buildContent(context, data),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _exportPdf(context, ref),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textOnDark),
              label: Text(
                l10n.translate('report_export_pdf'),
                style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, ReportState reportState) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (reportState.isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('report_generating_loading'),
              style: const TextStyle(color: AppColors.textOnDarkTertiary, fontSize: 14),
            ),
            if (reportState.progress > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: reportState.progress,
                  backgroundColor: const Color(0x1FFFFFFF),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (reportState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Error: ${reportState.error}',
                style: const TextStyle(color: AppColors.textOnDarkTertiary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.description_outlined, color: AppColors.textOnDark.withValues(alpha: 0.24), size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('report_no_data'),
            style: TextStyle(
              color: AppColors.textOnDark.withValues(alpha: 0.38),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.translate('report_no_data_subtitle'),
            style: TextStyle(color: AppColors.textOnDark.withValues(alpha: 0.24), fontSize: 13),
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
    WidgetRef ref,
  ) async {
    final String? path = await ref.read(reportNotifierProvider.notifier).exportPdf();
    if (!context.mounted) return;

    final AppLocalizations l10n = AppLocalizations.of(context);

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('report_pdf_saved')} $path'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: l10n.translate('ok'),
            textColor: AppColors.textOnDark,
            onPressed: () {},
          ),
        ),
      );
    } else {
      final ReportState reportState = ref.read(reportNotifierProvider);
      final String errorMsg = reportState.error ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('report_pdf_failed')}: $errorMsg'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}
