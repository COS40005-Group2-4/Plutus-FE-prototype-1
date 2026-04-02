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

    for (final ReportSection section in data.config.enabledSections) {
      if (kDebugMode) debugPrint('ReportPdfService: adding ${section.name}');
      _addSection(doc, section, data, dateFmt, pctFmt);
    }

    return doc.save();
  }

  // ── Section dispatcher ──────────────────────────────────────────────────

  void _addSection(pw.Document doc, ReportSection section, ReportDataModel data,
      DateFormat dateFmt, NumberFormat pctFmt) {
    switch (section) {
      case ReportSection.coverPage:
        _addCoverPage(doc, data, dateFmt);
      case ReportSection.executiveSummary:
        _addExecutiveSummary(doc, data, pctFmt);
      case ReportSection.spendingBreakdown:
        _addSpendingBreakdown(doc, data, pctFmt);
      case ReportSection.incomeAnalysis:
        _addIncomeAnalysis(doc, data);
      case ReportSection.cashFlow:
        _addCashFlow(doc, data);
      case ReportSection.budgetActual:
        _addBudgetActual(doc, data, pctFmt);
      case ReportSection.topMerchants:
        _addTopMerchants(doc, data);
      case ReportSection.investmentPortfolio:
        _addInvestmentPortfolio(doc, data, pctFmt);
      case ReportSection.forecast:
        _addForecast(doc, data);
      case ReportSection.alerts:
        _addAlerts(doc, data);
      case ReportSection.coaching:
        _addCoaching(doc, data);
      case ReportSection.billsRecurring:
        _addBills(doc, data, dateFmt);
      case ReportSection.transactionLog:
        _addTransactionLog(doc, data, dateFmt);
    }
  }

  // ── Cover page ──────────────────────────────────────────────────────────

  void _addCoverPage(pw.Document doc, ReportDataModel data, DateFormat dateFmt) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: _theme,
      build: (pw.Context ctx) => pw.Container(
        color: const PdfColor.fromInt(0xFF0A1828),
        padding: const pw.EdgeInsets.all(48),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Container(width: 48, height: 4, color: PdfColors.blue),
            pw.SizedBox(height: 24),
            pw.Text('Plutus', style: _s(size: 36, bold: true, color: PdfColors.white)),
            pw.SizedBox(height: 8),
            pw.Text('Financial Report', style: _s(size: 20, color: PdfColors.grey400)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${dateFmt.format(data.config.dateRange.start)} – ${dateFmt.format(data.config.dateRange.end)}',
              style: _s(size: 12, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 80),
            // Key metrics
            _coverMetric('Total Income', data.formatAmount(data.totalIncome), PdfColors.green),
            pw.SizedBox(height: 12),
            _coverMetric('Total Expenses', data.formatAmount(data.totalExpenses), PdfColors.red),
            pw.SizedBox(height: 12),
            _coverMetric('Net Savings', data.formatAmount(data.netSavings),
                data.netSavings >= 0 ? PdfColors.green : PdfColors.red),
            if (data.healthScore != null) ...<pw.Widget>[
              pw.SizedBox(height: 12),
              _coverMetric('Health Score', '${data.healthScore!.score}/100', PdfColors.blue),
            ],
            pw.SizedBox(height: 60),
            pw.Text('Prepared for', style: _s(size: 9, color: PdfColors.grey500)),
            pw.Text(data.userName, style: _s(size: 14, bold: true, color: PdfColors.white)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated ${dateFmt.format(data.generatedAt)}',
              style: _s(size: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    ));
  }

  pw.Widget _coverMetric(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF132337),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          pw.Text(label, style: _s(size: 10, color: PdfColors.grey400)),
          pw.SizedBox(width: 16),
          pw.Text(value, style: _s(size: 14, bold: true, color: color)),
        ],
      ),
    );
  }

  // ── Executive Summary ───────────────────────────────────────────────────

  void _addExecutiveSummary(pw.Document doc, ReportDataModel data, NumberFormat pctFmt) {
    _addSectionPage(doc, 'Executive Summary', data, ReportSection.executiveSummary, <pw.Widget>[
      _infoRow('Total Income', data.formatAmount(data.totalIncome)),
      _infoRow('Total Expenses', data.formatAmount(data.totalExpenses)),
      _infoRow('Net Savings', data.formatAmount(data.netSavings)),
      _infoRow('Savings Rate', '${pctFmt.format(data.savingsRate)}%'),
      _infoRow('Transactions', '${data.transactionCount}'),
      if (data.healthScore != null)
        _infoRow('Health Score', '${data.healthScore!.score}/100'),
      pw.SizedBox(height: 8),
      pw.Text(
        'This summary compares the selected period against the previous equivalent period.',
        style: _s(size: 9, color: PdfColors.grey600),
      ),
    ]);
  }

  // ── Spending Breakdown ──────────────────────────────────────────────────

  void _addSpendingBreakdown(pw.Document doc, ReportDataModel data, NumberFormat pctFmt) {
    final List<SpendingCategoryData>? cats = data.spendingCategories;
    if (cats == null || cats.isEmpty) {
      _addSectionPage(doc, 'Spending Breakdown', data, ReportSection.spendingBreakdown, <pw.Widget>[
        pw.Text('No spending data available.', style: _s(color: PdfColors.grey500)),
      ]);
      return;
    }

    final List<List<String>> tableData = cats.map((SpendingCategoryData c) {
      final String mom = c.changePercent == 0
          ? '—'
          : '${c.changePercent > 0 ? '+' : ''}${pctFmt.format(c.changePercent)}%';
      return <String>[
        c.category,
        data.formatAmount(c.amount),
        '${pctFmt.format(c.percentage)}%',
        mom,
      ];
    }).toList();

    _addSectionPage(doc, 'Spending Breakdown', data, ReportSection.spendingBreakdown, <pw.Widget>[
      pw.TableHelper.fromTextArray(
        headers: <String>['Category', 'Amount', '% of Total', 'MoM Change'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        cellAlignment: pw.Alignment.centerLeft,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    ]);
  }

  // ── Income Analysis ─────────────────────────────────────────────────────

  void _addIncomeAnalysis(pw.Document doc, ReportDataModel data) {
    final double change = data.comparisonIncome > 0
        ? ((data.totalIncome - data.comparisonIncome) / data.comparisonIncome) * 100
        : 0;

    _addSectionPage(doc, 'Income Analysis', data, ReportSection.incomeAnalysis, <pw.Widget>[
      _infoRow('Total Income', data.formatAmount(data.totalIncome)),
      _infoRow('Previous Period', data.formatAmount(data.comparisonIncome)),
      _infoRow('Change', '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'),
      if (data.incomeSources != null) ...<pw.Widget>[
        pw.SizedBox(height: 8),
        pw.Text('Income Sources', style: _s(size: 10, bold: true)),
        pw.SizedBox(height: 4),
        ...data.incomeSources!.map((IncomeSourceData s) =>
            _infoRow(s.source, data.formatAmount(s.amount))),
      ],
    ]);
  }

  // ── Cash Flow ───────────────────────────────────────────────────────────

  void _addCashFlow(pw.Document doc, ReportDataModel data) {
    _addSectionPage(doc, 'Cash Flow', data, ReportSection.cashFlow, <pw.Widget>[
      _infoRow('Total Inflows', data.formatAmount(data.totalIncome)),
      _infoRow('Total Outflows', data.formatAmount(data.totalExpenses)),
      _infoRow('Net Cash Flow', data.formatAmount(data.netSavings)),
      pw.SizedBox(height: 8),
      pw.Text(
        data.netSavings >= 0
            ? 'Positive cash flow — you saved more than you spent this period.'
            : 'Negative cash flow — expenses exceeded income this period.',
        style: _s(size: 9, color: PdfColors.grey600),
      ),
    ]);
  }

  // ── Budget vs Actual ────────────────────────────────────────────────────

  void _addBudgetActual(pw.Document doc, ReportDataModel data, NumberFormat pctFmt) {
    final List<BudgetCategoryData>? budgets = data.budgetCategories;
    if (budgets == null || budgets.isEmpty) {
      _addSectionPage(doc, 'Budget vs Actual', data, ReportSection.budgetActual, <pw.Widget>[
        pw.Text('No budget data available.', style: _s(color: PdfColors.grey500)),
      ]);
      return;
    }

    final List<List<String>> tableData = budgets.map((BudgetCategoryData b) =>
      <String>[b.category, data.formatAmount(b.budget), data.formatAmount(b.actual),
        '${pctFmt.format(b.percentage)}%', b.isOverBudget ? 'OVER' : 'OK']
    ).toList();

    _addSectionPage(doc, 'Budget vs Actual', data, ReportSection.budgetActual, <pw.Widget>[
      pw.TableHelper.fromTextArray(
        headers: <String>['Category', 'Budget', 'Actual', 'Used', 'Status'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    ]);
  }

  // ── Top Merchants ───────────────────────────────────────────────────────

  void _addTopMerchants(pw.Document doc, ReportDataModel data) {
    final List<MerchantData>? merchants = data.topMerchants;
    if (merchants == null || merchants.isEmpty) {
      _addSectionPage(doc, 'Top Merchants', data, ReportSection.topMerchants, <pw.Widget>[
        pw.Text('No merchant data available.', style: _s(color: PdfColors.grey500)),
      ]);
      return;
    }

    final List<List<String>> tableData = merchants.map((MerchantData m) =>
      <String>[m.name, m.category, data.formatAmount(m.amount),
        '${m.transactionCount}', '${m.changePercent >= 0 ? '+' : ''}${m.changePercent.toStringAsFixed(1)}%']
    ).toList();

    _addSectionPage(doc, 'Top Merchants', data, ReportSection.topMerchants, <pw.Widget>[
      pw.TableHelper.fromTextArray(
        headers: <String>['Merchant', 'Category', 'Amount', 'Txns', 'MoM'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    ]);
  }

  // ── Investment Portfolio ────────────────────────────────────────────────

  void _addInvestmentPortfolio(pw.Document doc, ReportDataModel data, NumberFormat pctFmt) {
    final List<InvestmentHoldingData>? holdings = data.holdings;

    final List<pw.Widget> content = <pw.Widget>[];
    if (data.portfolioTotalValue != null) {
      content.add(_infoRow('Portfolio Value', data.formatAmount(data.portfolioTotalValue!)));
    }
    if (data.portfolioReturnPercent != null) {
      content.add(_infoRow('Period Return', '${pctFmt.format(data.portfolioReturnPercent!)}%'));
    }

    if (holdings != null && holdings.isNotEmpty) {
      final List<List<String>> tableData = holdings.map((InvestmentHoldingData h) =>
        <String>[h.ticker, h.name, data.formatAmount(h.value),
          '${pctFmt.format(h.allocation)}%', '${h.returnPercent >= 0 ? '+' : ''}${pctFmt.format(h.returnPercent)}%']
      ).toList();

      content.add(pw.SizedBox(height: 8));
      content.add(pw.TableHelper.fromTextArray(
        headers: <String>['Ticker', 'Name', 'Value', 'Alloc%', 'Return%'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ));
    } else {
      content.add(pw.Text('No investment data available.', style: _s(color: PdfColors.grey500)));
    }

    _addSectionPage(doc, 'Investment Portfolio', data, ReportSection.investmentPortfolio, content);
  }

  // ── Forecast ────────────────────────────────────────────────────────────

  void _addForecast(pw.Document doc, ReportDataModel data) {
    final Forecast? forecast = data.forecast;
    final List<pw.Widget> content = <pw.Widget>[];

    if (forecast != null) {
      content.add(pw.Text(forecast.summary, style: _s(size: 10)));
      content.add(pw.SizedBox(height: 8));
      for (final MapEntry<String, double> e in forecast.projectedBalance.entries) {
        content.add(_infoRow(e.key, data.formatAmount(e.value)));
      }
    } else {
      content.add(pw.Text('No forecast data available.', style: _s(color: PdfColors.grey500)));
    }

    _addSectionPage(doc, 'Forecast', data, ReportSection.forecast, content);
  }

  // ── Alerts ──────────────────────────────────────────────────────────────

  void _addAlerts(pw.Document doc, ReportDataModel data) {
    final List<Alert>? alerts = data.alerts;
    final List<pw.Widget> content = <pw.Widget>[];

    if (alerts != null && alerts.isNotEmpty) {
      for (final Alert alert in alerts) {
        final String severity = alert.severity.name.toUpperCase();
        content.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text('[$severity] ${alert.title}', style: _s(size: 10, bold: true)),
              pw.SizedBox(height: 2),
              pw.Text(alert.body, style: _s(size: 9, color: PdfColors.grey700)),
            ],
          ),
        ));
      }
    } else {
      content.add(pw.Text('No alerts.', style: _s(color: PdfColors.grey500)));
    }

    _addSectionPage(doc, 'Alerts & Warnings', data, ReportSection.alerts, content);
  }

  // ── Coaching ────────────────────────────────────────────────────────────

  void _addCoaching(pw.Document doc, ReportDataModel data) {
    final List<CoachingTip>? tips = data.coachingTips;
    final List<pw.Widget> content = <pw.Widget>[];

    if (tips != null && tips.isNotEmpty) {
      for (final CoachingTip tip in tips) {
        content.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text('[${tip.difficulty.name.toUpperCase()}] ${tip.title}', style: _s(size: 10, bold: true)),
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
      content.add(pw.Text('No coaching tips available.', style: _s(color: PdfColors.grey500)));
    }

    _addSectionPage(doc, 'Coaching Tips', data, ReportSection.coaching, content);
  }

  // ── Bills & Recurring ───────────────────────────────────────────────────

  void _addBills(pw.Document doc, ReportDataModel data, DateFormat dateFmt) {
    final List<BillData>? bills = data.bills;
    if (bills == null || bills.isEmpty) {
      _addSectionPage(doc, 'Bills & Recurring', data, ReportSection.billsRecurring, <pw.Widget>[
        pw.Text('No recurring bills data.', style: _s(color: PdfColors.grey500)),
      ]);
      return;
    }

    final List<List<String>> tableData = bills.map((BillData b) =>
      <String>[b.name, data.formatAmount(b.amount), b.frequency,
        b.nextDue != null ? dateFmt.format(b.nextDue!) : '—', b.status]
    ).toList();

    _addSectionPage(doc, 'Bills & Recurring', data, ReportSection.billsRecurring, <pw.Widget>[
      _infoRow('Total Recurring', data.formatAmount(data.totalRecurring)),
      _infoRow('Active Bills', '${data.activeBillCount}'),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: <String>['Name', 'Amount', 'Frequency', 'Next Due', 'Status'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    ]);
  }

  // ── Transaction Log ─────────────────────────────────────────────────────

  void _addTransactionLog(pw.Document doc, ReportDataModel data, DateFormat dateFmt) {
    final List<Transaction>? txns = data.transactions;
    if (txns == null || txns.isEmpty) {
      _addSectionPage(doc, 'Transaction Log', data, ReportSection.transactionLog, <pw.Widget>[
        pw.Text('No transactions in this period.', style: _s(color: PdfColors.grey500)),
      ]);
      return;
    }

    // Limit to 50 rows for PDF; full list in app preview
    final int maxRows = 50;
    final List<Transaction> limited = txns.length > maxRows ? txns.sublist(0, maxRows) : txns;

    final List<List<String>> tableData = limited.map((Transaction tx) =>
      <String>[
        dateFmt.format(tx.dateTime),
        tx.label,
        '${tx.isExpense ? '-' : '+'}${tx.totalAmount.toStringAsFixed(2)} ${tx.currency}',
      ]
    ).toList();

    _addSectionPage(doc, 'Transaction Log', data, ReportSection.transactionLog, <pw.Widget>[
      pw.Text('${txns.length} transactions total${txns.length > maxRows ? ' (showing first $maxRows)' : ''}',
          style: _s(size: 9, color: PdfColors.grey600)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: <String>['Date', 'Description', 'Amount'],
        data: tableData,
        headerStyle: _s(size: 9, bold: true),
        cellStyle: _s(size: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Adds a section as a single pw.Page with title, content, and optional AI recommendation.
  void _addSectionPage(pw.Document doc, String title, ReportDataModel data,
      ReportSection section, List<pw.Widget> content) {
    final SectionRecommendation? rec = data.recommendations[section];

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: _theme,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(left: const pw.BorderSide(color: PdfColors.blue, width: 3)),
            ),
            child: pw.Text(title, style: _s(size: 14, bold: true)),
          ),
          pw.SizedBox(height: 12),
          // Content
          ...content,
          // AI Recommendation
          if (rec != null) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            pw.Container(
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
                  pw.SizedBox(height: 4),
                  pw.Text(rec.oneLiner, style: _s(size: 10, bold: true)),
                  pw.SizedBox(height: 4),
                  pw.Text(rec.detailed, style: _s(size: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
          ],
          // Footer
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Text(
            'Plutus Financial Report • ${DateFormat('MMM d, yyyy').format(data.generatedAt)}',
            style: _s(size: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    ));
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
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
