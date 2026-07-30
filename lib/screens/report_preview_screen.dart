import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../providers/report_notifier.dart';
import '../models/report_config.dart';
import '../models/report_data.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
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
    final PlutusTokens t = context.tokens;
    final ReportState reportState = ref.watch(reportNotifierProvider);
    final ReportDataModel? data = reportState.reportData;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text(l10n.translate('report_preview')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined),
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
              backgroundColor: t.gold,
              icon: Icon(Icons.picture_as_pdf_outlined, color: t.onGold),
              label: Text(
                l10n.translate('report_export_pdf'),
                style: TextStyle(color: t.onGold, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, ReportState reportState) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    if (reportState.isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: t.gold),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('report_generating_loading'),
              style: TextStyle(color: t.textSecondary, fontSize: 14),
            ),
            if (reportState.progress > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: reportState.progress,
                  backgroundColor: PlutusTokens.dark.surfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(PlutusTokens.dark.goldText),
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
              Icon(Icons.error_outline, color: t.error.text, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${l10n.translate('error_prefix')}${reportState.error}',
                style: TextStyle(color: t.textSecondary, fontSize: 14),
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
          Icon(Icons.description_outlined, color: t.textMuted, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('report_no_data'),
            style: TextStyle(
              color: t.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.translate('report_no_data_subtitle'),
            style: TextStyle(color: t.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportDataModel data) {
    // Task 14/15 idiom: the report DOCUMENT canvas is fixed dark regardless
    // of app theme. Wrap in a Theme override carrying the dark PlutusTokens
    // extension so every context-reading primitive inside (MeanderDivider,
    // ReportSectionHeader, etc.) resolves dark tokens too — otherwise a
    // light app theme leaks light-theme colors onto the navy document
    // (carried finding from Task 14). SizedBox.expand guarantees the navy
    // canvas fills the full viewport even for a short report.
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[PlutusTokens.dark],
      ),
      child: SizedBox.expand(
        child: ColoredBox(
          color: PlutusTokens.dark.bg,
          child: SingleChildScrollView(
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
          ),
        ),
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
    final PlutusTokens t = context.tokens;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('report_pdf_saved')} $path'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PlutusTokens.dark.success.text,
          action: SnackBarAction(
            label: l10n.translate('ok'),
            textColor: PlutusTokens.dark.text,
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
          backgroundColor: t.error.text,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}
