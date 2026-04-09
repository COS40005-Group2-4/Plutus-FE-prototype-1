import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/report_strings.dart';
import '../models/ai/insight.dart';
import '../models/report_config.dart';
import '../models/report_data.dart';
import '../models/transaction_model.dart';
import 'interfaces/i_report_pdf_service.dart';

class ReportPdfService implements IReportPdfService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    try {
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      if (kDebugMode) debugPrint('Noto Sans failed: $e');
      try {
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
      } catch (e2) {
        if (kDebugMode) debugPrint('Roboto failed: $e2');
      }
    }
  }

  pw.TextStyle _s({double size = 10, bool bold = false, PdfColor color = PdfColors.black}) {
    return pw.TextStyle(
      fontSize: size,
      font: bold ? _boldFont : _regularFont,
      color: color,
    );
  }

  pw.ThemeData get _theme => pw.ThemeData.withFont(base: _regularFont, bold: _boldFont);

  @override
  Future<String> generatePdf({required ReportDataModel data, String locale = 'en'}) async {
    final Uint8List bytes = await generatePdfBytes(data: data, locale: locale);
    final Directory dir = await getApplicationDocumentsDirectory();
    final String exportDir = '${dir.path}/exports';
    await Directory(exportDir).create(recursive: true);
    final String timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final String filePath = '$exportDir/plutus_report_$timestamp.pdf';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  @override
  Future<Uint8List> generatePdfBytes({required ReportDataModel data, String locale = 'en'}) async {
    await _loadFonts();
    final ReportStrings s = ReportStrings(locale);
    final pw.Document doc = pw.Document(theme: _theme);
    final DateFormat dateFmt = DateFormat('MMM d, yyyy');
    final NumberFormat pctFmt = NumberFormat('0.0');

    final List<ReportSection> sections = data.config.enabledSections;
    final bool hasCover = sections.contains(ReportSection.coverPage);
    final List<ReportSection> bodySections =
        sections.where((ReportSection sec) => sec != ReportSection.coverPage).toList();

    // Cover page — standalone dark page
    if (hasCover) {
      doc.addPage(_buildCoverPage(data, dateFmt, s));
    }

    // ALL other sections flow continuously in a single MultiPage.
    // Each section returns List<pw.Widget> — flat, individually pageable widgets.
    // RULES: no pw.Expanded, no pw.Spacer, no pw.Column wrapping large content.
    if (bodySections.isNotEmpty) {
      final List<pw.Widget> allContent = <pw.Widget>[];
      for (final ReportSection section in bodySections) {
        allContent.addAll(_sectionWidgets(section, data, dateFmt, pctFmt, s));
        allContent.add(pw.SizedBox(height: 16));
      }

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        maxPages: 200,
        header: (pw.Context ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text('PLUTUS ${s.tr('report_financial_report')}', style: _s(size: 8, color: PdfColors.grey500)),
              pw.Text(
                '${dateFmt.format(data.config.dateRange.start)} – ${dateFmt.format(data.config.dateRange.end)}',
                style: _s(size: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        footer: (pw.Context ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text('${s.tr('report_generated_on')}${dateFmt.format(data.generatedAt)}',
                  style: _s(size: 7, color: PdfColors.grey500)),
              pw.Text(s.tr('export_page_of').replaceFirst('{page}', '${ctx.pageNumber}').replaceFirst('{total}', '${ctx.pagesCount}'),
                  style: _s(size: 7, color: PdfColors.grey500)),
            ],
          ),
        ),
        build: (pw.Context ctx) => allContent,
      ));
    }

    return doc.save();
  }

  // ── Cover page (standalone) ─────────────────────────────────────────────

  pw.Page _buildCoverPage(ReportDataModel data, DateFormat dateFmt, ReportStrings s) {
    final String audienceLabel = data.config.audienceMode == AudienceMode.professional
        ? s.tr('report_financial_report')
        : s.tr('report_personal_finance_report');

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: _theme,
      margin: const pw.EdgeInsets.all(48),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          // Top accent line
          pw.Container(width: 60, height: 3, color: PdfColors.blue800),
          pw.SizedBox(height: 40),

          // Title block
          pw.Text('PLUTUS', style: _s(size: 14, bold: true, color: PdfColors.grey500)),
          pw.SizedBox(height: 8),
          pw.Text(s.tr('report_financial_report'), style: _s(size: 32, bold: true, color: PdfColors.grey900)),
          pw.SizedBox(height: 6),
          pw.Text(audienceLabel, style: _s(size: 12, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${dateFmt.format(data.config.dateRange.start)} – ${dateFmt.format(data.config.dateRange.end)}',
            style: _s(size: 11, color: PdfColors.grey600),
          ),

          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 24),

          // Key metrics table
          pw.Text(s.tr('report_key_metrics').toUpperCase(), style: _s(size: 9, bold: true, color: PdfColors.grey500)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: <String>[s.tr('report_metric'), s.tr('report_value')],
            data: <List<String>>[
              <String>[s.tr('report_total_income'), data.formatAmount(data.totalIncome)],
              <String>[s.tr('report_total_expenses'), data.formatAmount(data.totalExpenses)],
              <String>[s.tr('report_net_savings'), data.formatAmount(data.netSavings)],
              <String>[s.tr('report_savings_rate'), '${data.savingsRate.toStringAsFixed(1)}%'],
              <String>[s.tr('report_transactions'), '${data.transactionCount}'],
              if (data.healthScore != null)
                <String>[s.tr('report_health_score'), '${data.healthScore!.score} / 100'],
            ],
            headerStyle: _s(size: 10, bold: true, color: PdfColors.grey800),
            cellStyle: _s(size: 10),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            columnWidths: <int, pw.TableColumnWidth>{
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
          ),

          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 16),

          // Prepared for
          pw.Text(s.tr('report_prepared_for').toUpperCase(), style: _s(size: 9, bold: true, color: PdfColors.grey500)),
          pw.SizedBox(height: 6),
          pw.Text(data.userName, style: _s(size: 16, bold: true, color: PdfColors.grey900)),

          pw.SizedBox(height: 24),
          pw.Text(
            '${s.tr('report_generated_on')}${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(data.generatedAt)}',
            style: _s(size: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── Section widget builder (returns flat List<pw.Widget>) ───────────────

  List<pw.Widget> _sectionWidgets(
      ReportSection section, ReportDataModel data, DateFormat dateFmt, NumberFormat pctFmt, ReportStrings s) {
    final List<pw.Widget> widgets = <pw.Widget>[];

    // Section header
    widgets.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(left: const pw.BorderSide(color: PdfColors.blue, width: 3)),
      ),
      child: pw.Text(_sectionTitle(section, s), style: _s(size: 13, bold: true)),
    ));
    widgets.add(pw.SizedBox(height: 8));

    // Section body — each adds flat widgets
    switch (section) {
      case ReportSection.coverPage:
        break; // handled separately
      case ReportSection.executiveSummary:
        _addExecutiveSummaryWidgets(widgets, data, pctFmt, s);
      case ReportSection.spendingBreakdown:
        _addSpendingWidgets(widgets, data, pctFmt, s);
      case ReportSection.incomeAnalysis:
        _addIncomeWidgets(widgets, data, s);
      case ReportSection.cashFlow:
        _addCashFlowWidgets(widgets, data, s);
      case ReportSection.budgetActual:
        _addBudgetWidgets(widgets, data, pctFmt, s);
      case ReportSection.topMerchants:
        _addMerchantWidgets(widgets, data, s);
      case ReportSection.investmentPortfolio:
        _addInvestmentWidgets(widgets, data, pctFmt, s);
      case ReportSection.forecast:
        _addForecastWidgets(widgets, data, s);
      case ReportSection.alerts:
        _addAlertWidgets(widgets, data, s);
      case ReportSection.coaching:
        _addCoachingWidgets(widgets, data, s);
      case ReportSection.billsRecurring:
        _addBillWidgets(widgets, data, dateFmt, s);
      case ReportSection.transactionLog:
        _addTransactionWidgets(widgets, data, dateFmt, s);
    }

    // AI recommendation
    final SectionRecommendation? rec = data.recommendations[section];
    if (rec != null) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          border: pw.Border(left: const pw.BorderSide(color: PdfColors.blue, width: 3)),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(s.tr('report_ai_insight'), style: _s(size: 8, bold: true, color: PdfColors.blue800)),
            pw.SizedBox(height: 3),
            pw.Text(rec.oneLiner, style: _s(size: 10, bold: true)),
            pw.SizedBox(height: 3),
            pw.Text(rec.detailed, style: _s(size: 9, color: PdfColors.grey700)),
          ],
        ),
      ));
    }

    return widgets;
  }

  // ── Individual section widget builders ──────────────────────────────────
  // Each method adds FLAT widgets to the list. No pw.Column, no pw.Expanded.

  void _addExecutiveSummaryWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt, ReportStrings s) {
    w.add(_infoRow(s.tr('report_total_income'), data.formatAmount(data.totalIncome)));
    w.add(_infoRow(s.tr('report_total_expenses'), data.formatAmount(data.totalExpenses)));
    w.add(_infoRow(s.tr('report_net_savings'), data.formatAmount(data.netSavings)));
    w.add(_infoRow(s.tr('report_savings_rate'), '${pctFmt.format(data.savingsRate)}%'));
    w.add(_infoRow(s.tr('report_transactions'), '${data.transactionCount}'));
    if (data.healthScore != null) {
      w.add(_infoRow(s.tr('report_health_score'), '${data.healthScore!.score}/100'));
    }
    w.add(pw.SizedBox(height: 4));
    w.add(pw.Text(
      s.tr('report_summary_desc'),
      style: _s(size: 9, color: PdfColors.grey600),
    ));
  }

  void _addSpendingWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt, ReportStrings s) {
    final List<SpendingCategoryData>? cats = data.spendingCategories;
    if (cats == null || cats.isEmpty) {
      w.add(pw.Text(s.tr('report_no_spending_data'), style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>[s.tr('report_col_category'), s.tr('report_col_amount'), s.tr('report_col_percent'), s.tr('report_col_mom')],
      data: cats.map((SpendingCategoryData c) => <String>[
        c.category,
        data.formatAmount(c.amount),
        '${pctFmt.format(c.percentage)}%',
        c.changePercent == 0 ? '—' : '${c.changePercent > 0 ? '+' : ''}${pctFmt.format(c.changePercent)}%',
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  void _addIncomeWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    final double change = data.comparisonIncome > 0
        ? ((data.totalIncome - data.comparisonIncome) / data.comparisonIncome) * 100
        : 0;
    w.add(_infoRow(s.tr('report_total_income'), data.formatAmount(data.totalIncome)));
    w.add(_infoRow(s.tr('report_previous_period'), data.formatAmount(data.comparisonIncome)));
    w.add(_infoRow(s.tr('report_change'), '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'));
    if (data.incomeSources != null && data.incomeSources!.isNotEmpty) {
      w.add(pw.SizedBox(height: 6));
      w.add(pw.Text(s.tr('report_income_sources'), style: _s(size: 10, bold: true)));
      for (final IncomeSourceData src in data.incomeSources!) {
        w.add(_infoRow(src.source, data.formatAmount(src.amount)));
      }
    }
  }

  void _addCashFlowWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    w.add(_infoRow(s.tr('report_total_inflows'), data.formatAmount(data.totalIncome)));
    w.add(_infoRow(s.tr('report_total_outflows'), data.formatAmount(data.totalExpenses)));
    w.add(_infoRow(s.tr('report_net_cashflow'), data.formatAmount(data.netSavings)));
    w.add(pw.SizedBox(height: 4));
    w.add(pw.Text(
      data.netSavings >= 0
          ? s.tr('report_positive_cashflow')
          : s.tr('report_negative_cashflow'),
      style: _s(size: 9, color: PdfColors.grey600),
    ));
  }

  void _addBudgetWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt, ReportStrings s) {
    final List<BudgetCategoryData>? budgets = data.budgetCategories;
    if (budgets == null || budgets.isEmpty) {
      w.add(pw.Text(s.tr('report_no_budget_data'), style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>[s.tr('report_col_category'), s.tr('report_col_budget'), s.tr('report_col_actual'), s.tr('report_col_used'), s.tr('report_col_status')],
      data: budgets.map((BudgetCategoryData b) => <String>[
        b.category, data.formatAmount(b.budget), data.formatAmount(b.actual),
        '${pctFmt.format(b.percentage)}%', b.isOverBudget ? s.tr('report_over') : s.tr('report_ok'),
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  void _addMerchantWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    final List<MerchantData>? merchants = data.topMerchants;
    if (merchants == null || merchants.isEmpty) {
      w.add(pw.Text(s.tr('report_no_merchant_data'), style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>[s.tr('report_col_merchant'), s.tr('report_col_category'), s.tr('report_col_amount'), s.tr('report_col_txns'), s.tr('report_col_mom')],
      data: merchants.map((MerchantData m) => <String>[
        m.name, m.category, data.formatAmount(m.amount),
        '${m.transactionCount}', '${m.changePercent >= 0 ? '+' : ''}${m.changePercent.toStringAsFixed(1)}%',
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  void _addInvestmentWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt, ReportStrings s) {
    if (data.portfolioTotalValue != null) {
      w.add(_infoRow('Portfolio Value', data.formatAmount(data.portfolioTotalValue!)));
    }
    if (data.portfolioReturnPercent != null) {
      w.add(_infoRow('Period Return', '${pctFmt.format(data.portfolioReturnPercent!)}%'));
    }
    final List<InvestmentHoldingData>? holdings = data.holdings;
    if (holdings != null && holdings.isNotEmpty) {
      w.add(pw.SizedBox(height: 6));
      w.add(pw.TableHelper.fromTextArray(
        headers: <String>[s.tr('report_col_ticker'), s.tr('report_col_name'), s.tr('report_col_value'), s.tr('report_col_alloc'), s.tr('report_col_return')],
        data: holdings.map((InvestmentHoldingData h) => <String>[
          h.ticker, h.name, data.formatAmount(h.value),
          '${pctFmt.format(h.allocation)}%', '${h.returnPercent >= 0 ? '+' : ''}${pctFmt.format(h.returnPercent)}%',
        ]).toList(),
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ));
    } else {
      w.add(pw.Text(s.tr('report_no_investment_data'), style: _s(color: PdfColors.grey500)));
    }
  }

  void _addForecastWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    final Forecast? forecast = data.forecast;
    if (forecast != null) {
      w.add(pw.Text(forecast.summary, style: _s(size: 10)));
      w.add(pw.SizedBox(height: 6));
      for (final MapEntry<String, double> e in forecast.projectedBalance.entries) {
        w.add(_infoRow(e.key, data.formatAmount(e.value)));
      }
    } else {
      w.add(pw.Text(s.tr('report_no_forecast_data'), style: _s(color: PdfColors.grey500)));
    }
  }

  void _addAlertWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    final List<Alert>? alerts = data.alerts;
    if (alerts != null && alerts.isNotEmpty) {
      for (final Alert alert in alerts) {
        w.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 5),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text('[${alert.severity.name.toUpperCase()}] ${alert.title}',
                  style: _s(size: 10, bold: true)),
              pw.SizedBox(height: 2),
              pw.Text(alert.body, style: _s(size: 9, color: PdfColors.grey700)),
            ],
          ),
        ));
      }
    } else {
      w.add(pw.Text(s.tr('report_no_alerts'), style: _s(color: PdfColors.grey500)));
    }
  }

  void _addCoachingWidgets(List<pw.Widget> w, ReportDataModel data, ReportStrings s) {
    final List<CoachingTip>? tips = data.coachingTips;
    if (tips != null && tips.isNotEmpty) {
      for (final CoachingTip tip in tips) {
        w.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 5),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text('[${tip.difficulty.name.toUpperCase()}] ${tip.title}',
                  style: _s(size: 10, bold: true)),
              pw.SizedBox(height: 2),
              pw.Text(tip.body, style: _s(size: 9, color: PdfColors.grey700)),
              if (tip.savingsEstimate != null)
                pw.Text('${s.tr('report_est_savings')}${data.formatAmount(tip.savingsEstimate!)}',
                    style: _s(size: 8, color: PdfColors.green800)),
            ],
          ),
        ));
      }
    } else {
      w.add(pw.Text(s.tr('report_no_coaching'), style: _s(color: PdfColors.grey500)));
    }
  }

  void _addBillWidgets(List<pw.Widget> w, ReportDataModel data, DateFormat dateFmt, ReportStrings s) {
    final List<BillData>? bills = data.bills;
    if (bills == null || bills.isEmpty) {
      w.add(pw.Text(s.tr('report_no_bills_data'), style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(_infoRow(s.tr('report_total_recurring'), data.formatAmount(data.totalRecurring)));
    w.add(_infoRow(s.tr('report_active_bills'), '${data.activeBillCount}'));
    w.add(pw.SizedBox(height: 6));
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>[s.tr('report_col_name'), s.tr('report_col_amount'), s.tr('report_col_frequency'), s.tr('report_col_next_due'), s.tr('report_col_status')],
      data: bills.map((BillData b) => <String>[
        b.name, data.formatAmount(b.amount), b.frequency,
        b.nextDue != null ? dateFmt.format(b.nextDue!) : '—', b.status,
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  void _addTransactionWidgets(List<pw.Widget> w, ReportDataModel data, DateFormat dateFmt, ReportStrings s) {
    final List<Transaction>? txns = data.transactions;
    if (txns == null || txns.isEmpty) {
      w.add(pw.Text(s.tr('report_no_transactions'), style: _s(color: PdfColors.grey500)));
      return;
    }
    final int maxRows = 50;
    final List<Transaction> limited = txns.length > maxRows ? txns.sublist(0, maxRows) : txns;
    w.add(pw.Text(
      '${txns.length} ${s.tr('report_transactions')}${txns.length > maxRows ? ' (${s.tr('export_showing_first')} $maxRows)' : ''}',
      style: _s(size: 9, color: PdfColors.grey600),
    ));
    w.add(pw.SizedBox(height: 6));
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>[s.tr('report_col_date'), s.tr('report_col_description'), s.tr('report_col_amount')],
      data: limited.map((Transaction tx) => <String>[
        dateFmt.format(tx.dateTime),
        tx.label,
        '${tx.isExpense ? '-' : '+'}${tx.totalAmount.toStringAsFixed(2)} ${tx.currency}',
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _sectionTitle(ReportSection section, ReportStrings s) {
    switch (section) {
      case ReportSection.coverPage: return s.tr('report_sec_cover');
      case ReportSection.executiveSummary: return s.tr('report_sec_summary');
      case ReportSection.spendingBreakdown: return s.tr('report_sec_spending');
      case ReportSection.incomeAnalysis: return s.tr('report_sec_income');
      case ReportSection.cashFlow: return s.tr('report_sec_cashflow');
      case ReportSection.budgetActual: return s.tr('report_sec_budget');
      case ReportSection.topMerchants: return s.tr('report_sec_merchants');
      case ReportSection.investmentPortfolio: return s.tr('report_sec_investments');
      case ReportSection.forecast: return s.tr('report_sec_forecast');
      case ReportSection.alerts: return s.tr('report_sec_alerts');
      case ReportSection.coaching: return s.tr('report_sec_coaching');
      case ReportSection.billsRecurring: return s.tr('report_sec_bills');
      case ReportSection.transactionLog: return s.tr('report_sec_transactions');
    }
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: _s(size: 10, color: PdfColors.grey700)),
          ),
          pw.Text(value, style: _s(size: 10, bold: true)),
        ],
      ),
    );
  }
}
