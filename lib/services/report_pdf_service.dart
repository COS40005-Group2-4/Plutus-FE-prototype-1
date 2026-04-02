import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  Future<String> generatePdf({required ReportDataModel data}) async {
    final Uint8List bytes = await generatePdfBytes(data: data);
    final Directory dir = await getApplicationDocumentsDirectory();
    final String exportDir = '${dir.path}/exports';
    await Directory(exportDir).create(recursive: true);
    final String timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final String filePath = '$exportDir/plutus_report_$timestamp.pdf';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  @override
  Future<Uint8List> generatePdfBytes({required ReportDataModel data}) async {
    await _loadFonts();
    final pw.Document doc = pw.Document(theme: _theme);
    final DateFormat dateFmt = DateFormat('MMM d, yyyy');
    final NumberFormat pctFmt = NumberFormat('0.0');

    final List<ReportSection> sections = data.config.enabledSections;
    final bool hasCover = sections.contains(ReportSection.coverPage);
    final List<ReportSection> bodySections =
        sections.where((ReportSection s) => s != ReportSection.coverPage).toList();

    // Cover page — standalone dark page
    if (hasCover) {
      doc.addPage(_buildCoverPage(data, dateFmt));
    }

    // ALL other sections flow continuously in a single MultiPage.
    // Each section returns List<pw.Widget> — flat, individually pageable widgets.
    // RULES: no pw.Expanded, no pw.Spacer, no pw.Column wrapping large content.
    if (bodySections.isNotEmpty) {
      final List<pw.Widget> allContent = <pw.Widget>[];
      for (final ReportSection section in bodySections) {
        allContent.addAll(_sectionWidgets(section, data, dateFmt, pctFmt));
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
              pw.Text('Plutus Financial Report', style: _s(size: 8, color: PdfColors.grey500)),
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
              pw.Text('Generated ${dateFmt.format(data.generatedAt)}',
                  style: _s(size: 7, color: PdfColors.grey500)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
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

  pw.Page _buildCoverPage(ReportDataModel data, DateFormat dateFmt) {
    final String audienceLabel = data.config.audienceMode == AudienceMode.professional
        ? 'Professional Report'
        : 'Personal Report';

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
          pw.Text('Financial Report', style: _s(size: 32, bold: true, color: PdfColors.grey900)),
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
          pw.Text('KEY METRICS', style: _s(size: 9, bold: true, color: PdfColors.grey500)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: <String>['Metric', 'Value'],
            data: <List<String>>[
              <String>['Total Income', data.formatAmount(data.totalIncome)],
              <String>['Total Expenses', data.formatAmount(data.totalExpenses)],
              <String>['Net Savings', data.formatAmount(data.netSavings)],
              <String>['Savings Rate', '${data.savingsRate.toStringAsFixed(1)}%'],
              <String>['Transactions', '${data.transactionCount}'],
              if (data.healthScore != null)
                <String>['Health Score', '${data.healthScore!.score} / 100'],
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
          pw.Text('PREPARED FOR', style: _s(size: 9, bold: true, color: PdfColors.grey500)),
          pw.SizedBox(height: 6),
          pw.Text(data.userName, style: _s(size: 16, bold: true, color: PdfColors.grey900)),

          pw.SizedBox(height: 24),
          pw.Text(
            'Generated on ${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(data.generatedAt)}',
            style: _s(size: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── Section widget builder (returns flat List<pw.Widget>) ───────────────

  List<pw.Widget> _sectionWidgets(
      ReportSection section, ReportDataModel data, DateFormat dateFmt, NumberFormat pctFmt) {
    final List<pw.Widget> widgets = <pw.Widget>[];

    // Section header
    widgets.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(left: const pw.BorderSide(color: PdfColors.blue, width: 3)),
      ),
      child: pw.Text(_sectionTitle(section), style: _s(size: 13, bold: true)),
    ));
    widgets.add(pw.SizedBox(height: 8));

    // Section body — each adds flat widgets
    switch (section) {
      case ReportSection.coverPage:
        break; // handled separately
      case ReportSection.executiveSummary:
        _addExecutiveSummaryWidgets(widgets, data, pctFmt);
      case ReportSection.spendingBreakdown:
        _addSpendingWidgets(widgets, data, pctFmt);
      case ReportSection.incomeAnalysis:
        _addIncomeWidgets(widgets, data);
      case ReportSection.cashFlow:
        _addCashFlowWidgets(widgets, data);
      case ReportSection.budgetActual:
        _addBudgetWidgets(widgets, data, pctFmt);
      case ReportSection.topMerchants:
        _addMerchantWidgets(widgets, data);
      case ReportSection.investmentPortfolio:
        _addInvestmentWidgets(widgets, data, pctFmt);
      case ReportSection.forecast:
        _addForecastWidgets(widgets, data);
      case ReportSection.alerts:
        _addAlertWidgets(widgets, data);
      case ReportSection.coaching:
        _addCoachingWidgets(widgets, data);
      case ReportSection.billsRecurring:
        _addBillWidgets(widgets, data, dateFmt);
      case ReportSection.transactionLog:
        _addTransactionWidgets(widgets, data, dateFmt);
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
            pw.Text('AI Insight', style: _s(size: 8, bold: true, color: PdfColors.blue800)),
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

  void _addExecutiveSummaryWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt) {
    w.add(_infoRow('Total Income', data.formatAmount(data.totalIncome)));
    w.add(_infoRow('Total Expenses', data.formatAmount(data.totalExpenses)));
    w.add(_infoRow('Net Savings', data.formatAmount(data.netSavings)));
    w.add(_infoRow('Savings Rate', '${pctFmt.format(data.savingsRate)}%'));
    w.add(_infoRow('Transactions', '${data.transactionCount}'));
    if (data.healthScore != null) {
      w.add(_infoRow('Health Score', '${data.healthScore!.score}/100'));
    }
    w.add(pw.SizedBox(height: 4));
    w.add(pw.Text(
      'Compared against the previous equivalent period.',
      style: _s(size: 9, color: PdfColors.grey600),
    ));
  }

  void _addSpendingWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt) {
    final List<SpendingCategoryData>? cats = data.spendingCategories;
    if (cats == null || cats.isEmpty) {
      w.add(pw.Text('No spending data available.', style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>['Category', 'Amount', '% of Total', 'MoM Change'],
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

  void _addIncomeWidgets(List<pw.Widget> w, ReportDataModel data) {
    final double change = data.comparisonIncome > 0
        ? ((data.totalIncome - data.comparisonIncome) / data.comparisonIncome) * 100
        : 0;
    w.add(_infoRow('Total Income', data.formatAmount(data.totalIncome)));
    w.add(_infoRow('Previous Period', data.formatAmount(data.comparisonIncome)));
    w.add(_infoRow('Change', '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'));
    if (data.incomeSources != null && data.incomeSources!.isNotEmpty) {
      w.add(pw.SizedBox(height: 6));
      w.add(pw.Text('Income Sources', style: _s(size: 10, bold: true)));
      for (final IncomeSourceData s in data.incomeSources!) {
        w.add(_infoRow(s.source, data.formatAmount(s.amount)));
      }
    }
  }

  void _addCashFlowWidgets(List<pw.Widget> w, ReportDataModel data) {
    w.add(_infoRow('Total Inflows', data.formatAmount(data.totalIncome)));
    w.add(_infoRow('Total Outflows', data.formatAmount(data.totalExpenses)));
    w.add(_infoRow('Net Cash Flow', data.formatAmount(data.netSavings)));
    w.add(pw.SizedBox(height: 4));
    w.add(pw.Text(
      data.netSavings >= 0
          ? 'Positive cash flow — you saved more than you spent.'
          : 'Negative cash flow — expenses exceeded income.',
      style: _s(size: 9, color: PdfColors.grey600),
    ));
  }

  void _addBudgetWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt) {
    final List<BudgetCategoryData>? budgets = data.budgetCategories;
    if (budgets == null || budgets.isEmpty) {
      w.add(pw.Text('No budget data available.', style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>['Category', 'Budget', 'Actual', 'Used', 'Status'],
      data: budgets.map((BudgetCategoryData b) => <String>[
        b.category, data.formatAmount(b.budget), data.formatAmount(b.actual),
        '${pctFmt.format(b.percentage)}%', b.isOverBudget ? 'OVER' : 'OK',
      ]).toList(),
      headerStyle: _s(size: 9, bold: true),
      cellStyle: _s(size: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ));
  }

  void _addMerchantWidgets(List<pw.Widget> w, ReportDataModel data) {
    final List<MerchantData>? merchants = data.topMerchants;
    if (merchants == null || merchants.isEmpty) {
      w.add(pw.Text('No merchant data available.', style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>['Merchant', 'Category', 'Amount', 'Txns', 'MoM'],
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

  void _addInvestmentWidgets(List<pw.Widget> w, ReportDataModel data, NumberFormat pctFmt) {
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
        headers: <String>['Ticker', 'Name', 'Value', 'Alloc%', 'Return%'],
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
      w.add(pw.Text('No investment data available.', style: _s(color: PdfColors.grey500)));
    }
  }

  void _addForecastWidgets(List<pw.Widget> w, ReportDataModel data) {
    final Forecast? forecast = data.forecast;
    if (forecast != null) {
      w.add(pw.Text(forecast.summary, style: _s(size: 10)));
      w.add(pw.SizedBox(height: 6));
      for (final MapEntry<String, double> e in forecast.projectedBalance.entries) {
        w.add(_infoRow(e.key, data.formatAmount(e.value)));
      }
    } else {
      w.add(pw.Text('No forecast data available.', style: _s(color: PdfColors.grey500)));
    }
  }

  void _addAlertWidgets(List<pw.Widget> w, ReportDataModel data) {
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
      w.add(pw.Text('No alerts.', style: _s(color: PdfColors.grey500)));
    }
  }

  void _addCoachingWidgets(List<pw.Widget> w, ReportDataModel data) {
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
                pw.Text('Est. savings: ${data.formatAmount(tip.savingsEstimate!)}',
                    style: _s(size: 8, color: PdfColors.green800)),
            ],
          ),
        ));
      }
    } else {
      w.add(pw.Text('No coaching tips available.', style: _s(color: PdfColors.grey500)));
    }
  }

  void _addBillWidgets(List<pw.Widget> w, ReportDataModel data, DateFormat dateFmt) {
    final List<BillData>? bills = data.bills;
    if (bills == null || bills.isEmpty) {
      w.add(pw.Text('No recurring bills data.', style: _s(color: PdfColors.grey500)));
      return;
    }
    w.add(_infoRow('Total Recurring', data.formatAmount(data.totalRecurring)));
    w.add(_infoRow('Active Bills', '${data.activeBillCount}'));
    w.add(pw.SizedBox(height: 6));
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>['Name', 'Amount', 'Frequency', 'Next Due', 'Status'],
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

  void _addTransactionWidgets(List<pw.Widget> w, ReportDataModel data, DateFormat dateFmt) {
    final List<Transaction>? txns = data.transactions;
    if (txns == null || txns.isEmpty) {
      w.add(pw.Text('No transactions in this period.', style: _s(color: PdfColors.grey500)));
      return;
    }
    final int maxRows = 50;
    final List<Transaction> limited = txns.length > maxRows ? txns.sublist(0, maxRows) : txns;
    w.add(pw.Text(
      '${txns.length} transactions${txns.length > maxRows ? ' (showing first $maxRows)' : ''}',
      style: _s(size: 9, color: PdfColors.grey600),
    ));
    w.add(pw.SizedBox(height: 6));
    w.add(pw.TableHelper.fromTextArray(
      headers: <String>['Date', 'Description', 'Amount'],
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

  String _sectionTitle(ReportSection section) {
    switch (section) {
      case ReportSection.coverPage: return 'Cover';
      case ReportSection.executiveSummary: return 'Executive Summary';
      case ReportSection.spendingBreakdown: return 'Spending Breakdown';
      case ReportSection.incomeAnalysis: return 'Income Analysis';
      case ReportSection.cashFlow: return 'Cash Flow';
      case ReportSection.budgetActual: return 'Budget vs Actual';
      case ReportSection.topMerchants: return 'Top Merchants';
      case ReportSection.investmentPortfolio: return 'Investment Portfolio';
      case ReportSection.forecast: return 'Forecast';
      case ReportSection.alerts: return 'Alerts & Warnings';
      case ReportSection.coaching: return 'Coaching Tips';
      case ReportSection.billsRecurring: return 'Bills & Recurring';
      case ReportSection.transactionLog: return 'Transaction Log';
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
