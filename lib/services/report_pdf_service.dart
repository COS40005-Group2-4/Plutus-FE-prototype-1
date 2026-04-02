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
import 'interfaces/i_report_pdf_service.dart';

// Design tokens — AWS CloudWatch dashboard palette
const PdfColor _colorBackground = PdfColor.fromInt(0xFF0A1828);
const PdfColor _colorAccentBlue = PdfColor.fromInt(0xFF1E90FF);
const PdfColor _colorAccentGreen = PdfColor.fromInt(0xFF00C48C);
const PdfColor _colorAccentRed = PdfColor.fromInt(0xFFFF4D4F);
const PdfColor _colorSurface = PdfColor.fromInt(0xFF132337);
const PdfColor _colorBorder = PdfColor.fromInt(0xFF1E3A52);
const PdfColor _colorTextPrimary = PdfColors.white;
const PdfColor _colorTextSecondary = PdfColor.fromInt(0xFF9CA3AF);

class ReportPdfService implements IReportPdfService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  // ── Font loading ─────────────────────────────────────────────────────────

  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    try {
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading Noto Sans fonts: $e. Trying Roboto fallback…');
      }
      try {
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
      } catch (e2) {
        if (kDebugMode) debugPrint('Error loading fallback fonts: $e2. Using built-ins.');
      }
    }
  }

  pw.TextStyle _style({
    double? size,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: size,
      font: bold ? _boldFont : _regularFont,
      fontFallback: bold
          ? <pw.Font>[_boldFont ?? pw.Font.helveticaBold()]
          : <pw.Font>[_regularFont ?? pw.Font.helvetica()],
      color: color,
    );
  }

  // ── Public interface ──────────────────────────────────────────────────────

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

    final pw.Document doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _regularFont,
        bold: _boldFont,
      ),
    );

    final NumberFormat nf = NumberFormat('#,##0', 'en_US');
    final NumberFormat pctFmt = NumberFormat('0.0');
    final DateFormat dateFmt = DateFormat('MMM d, yyyy');

    // Sections requested by the user config
    final List<ReportSection> sections = data.config.enabledSections;

    // If cover page is the only "full-bleed" section, put it on its own page.
    final bool hasCover = sections.contains(ReportSection.coverPage);
    final List<ReportSection> bodySections =
        sections.where((ReportSection s) => s != ReportSection.coverPage).toList();

    // Cover page — dark-themed standalone page
    if (hasCover) {
      doc.addPage(_buildCoverPage(data, nf, dateFmt));
    }

    // Body sections — paginated with header/footer
    if (bodySections.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          header: (pw.Context ctx) => _buildPageHeader(data, dateFmt),
          footer: (pw.Context ctx) => _buildPageFooter(ctx),
          build: (pw.Context ctx) {
            final List<pw.Widget> content = <pw.Widget>[];
            for (final ReportSection section in bodySections) {
              content.add(_buildSection(section, data, nf, pctFmt, dateFmt));
              content.add(pw.SizedBox(height: 24));
            }
            return content;
          },
        ),
      );
    }

    return doc.save();
  }

  // ── Page-level builders ───────────────────────────────────────────────────

  pw.Page _buildCoverPage(
      ReportDataModel data, NumberFormat nf, DateFormat dateFmt) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _regularFont, bold: _boldFont),
      build: (pw.Context ctx) {
        return pw.Container(
          color: _colorBackground,
          padding: const pw.EdgeInsets.all(48),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              // Header accent bar
              pw.Container(
                width: 48,
                height: 4,
                decoration: const pw.BoxDecoration(color: _colorAccentBlue),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Plutus',
                style: _style(size: 36, bold: true, color: _colorTextPrimary),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Financial Report',
                style: _style(size: 22, color: _colorTextSecondary),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${dateFmt.format(data.config.dateRange.start)} – ${dateFmt.format(data.config.dateRange.end)}',
                style: _style(size: 13, color: _colorTextSecondary),
              ),
              pw.Spacer(),
              // 3 metric boxes
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: <pw.Widget>[
                  _metricBox(
                    label: 'Income',
                    value: data.formatAmount(data.totalIncome),
                    color: _colorAccentGreen,
                  ),
                  pw.SizedBox(width: 16),
                  _metricBox(
                    label: 'Expenses',
                    value: data.formatAmount(data.totalExpenses),
                    color: _colorAccentRed,
                  ),
                  pw.SizedBox(width: 16),
                  _metricBox(
                    label: 'Health Score',
                    value: data.healthScore != null
                        ? '${data.healthScore!.score}/100'
                        : '—',
                    color: _colorAccentBlue,
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // Prepared for
              pw.Text(
                'Prepared for',
                style: _style(size: 9, color: _colorTextSecondary),
              ),
              pw.Text(
                data.userName,
                style: _style(size: 14, bold: true, color: _colorTextPrimary),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated ${dateFmt.format(data.generatedAt)}',
                style: _style(size: 9, color: _colorTextSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _metricBox({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _colorSurface,
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(label, style: _style(size: 9, color: _colorTextSecondary)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: _style(size: 13, bold: true, color: _colorTextPrimary)),
        ],
      ),
    );
  }

  pw.Widget _buildPageHeader(ReportDataModel data, DateFormat dateFmt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _colorBorder, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text('Plutus Financial Report',
              style: _style(size: 9, color: _colorTextSecondary)),
          pw.Text(
            '${dateFmt.format(data.config.dateRange.start)} – ${dateFmt.format(data.config.dateRange.end)}',
            style: _style(size: 9, color: _colorTextSecondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: _colorBorder, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Generated ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
            style: _style(size: 8, color: _colorTextSecondary),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: _style(size: 8, color: _colorTextSecondary),
          ),
        ],
      ),
    );
  }

  // ── Section dispatcher ────────────────────────────────────────────────────

  pw.Widget _buildSection(
    ReportSection section,
    ReportDataModel data,
    NumberFormat nf,
    NumberFormat pctFmt,
    DateFormat dateFmt,
  ) {
    switch (section) {
      case ReportSection.coverPage:
        // Handled as a standalone page above; should not appear in body.
        return pw.SizedBox();
      case ReportSection.executiveSummary:
        return _buildExecutiveSummary(data, nf, pctFmt);
      case ReportSection.spendingBreakdown:
        return _buildSpendingBreakdown(data, nf, pctFmt);
      case ReportSection.incomeAnalysis:
        return _buildIncomeAnalysis(data, nf);
      case ReportSection.cashFlow:
        return _buildCashFlow(data, nf);
      case ReportSection.budgetActual:
        return _buildBudgetActual(data, nf, pctFmt);
      case ReportSection.topMerchants:
        return _buildTopMerchants(data, nf);
      case ReportSection.investmentPortfolio:
        return _buildInvestmentPortfolio(data, nf, pctFmt);
      case ReportSection.forecast:
        return _buildForecast(data);
      case ReportSection.alerts:
        return _buildAlerts(data);
      case ReportSection.coaching:
        return _buildCoaching(data, nf);
      case ReportSection.billsRecurring:
        return _buildBills(data, nf, dateFmt);
      case ReportSection.transactionLog:
        return _buildTransactionLog(data, nf, dateFmt);
    }
  }

  // ── Individual section builders ───────────────────────────────────────────

  pw.Widget _buildExecutiveSummary(
      ReportDataModel data, NumberFormat nf, NumberFormat pctFmt) {
    final double incomeChange = data.comparisonIncome > 0
        ? ((data.totalIncome - data.comparisonIncome) / data.comparisonIncome) *
            100
        : 0;
    final double expenseChange = data.comparisonExpenses > 0
        ? ((data.totalExpenses - data.comparisonExpenses) /
                data.comparisonExpenses) *
            100
        : 0;

    return _section(
      title: 'Executive Summary',
      section: ReportSection.executiveSummary,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          // 2×2 metric grid
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: _summaryCard(
                  label: 'Total Income',
                  value: data.formatAmount(data.totalIncome),
                  subLabel: _momLabel(incomeChange),
                  valueColor: _colorAccentGreen,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _summaryCard(
                  label: 'Total Expenses',
                  value: data.formatAmount(data.totalExpenses),
                  subLabel: _momLabel(expenseChange),
                  valueColor: _colorAccentRed,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: _summaryCard(
                  label: 'Net Savings',
                  value: data.formatAmount(data.netSavings),
                  subLabel: 'Savings rate: ${pctFmt.format(data.savingsRate)}%',
                  valueColor: data.netSavings >= 0
                      ? _colorAccentGreen
                      : _colorAccentRed,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _summaryCard(
                  label: 'Health Score',
                  value: data.healthScore != null
                      ? '${data.healthScore!.score}/100'
                      : '—',
                  subLabel: data.healthScore?.summary ?? '',
                  valueColor: _colorAccentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryCard({
    required String label,
    required String value,
    required String subLabel,
    required PdfColor valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _colorSurface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _colorBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(label, style: _style(size: 9, color: _colorTextSecondary)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: _style(size: 16, bold: true, color: valueColor)),
          pw.SizedBox(height: 4),
          pw.Text(subLabel, style: _style(size: 8, color: _colorTextSecondary)),
        ],
      ),
    );
  }

  pw.Widget _buildSpendingBreakdown(
      ReportDataModel data, NumberFormat nf, NumberFormat pctFmt) {
    final List<SpendingCategoryData>? cats = data.spendingCategories;

    return _section(
      title: 'Spending Breakdown',
      section: ReportSection.spendingBreakdown,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (cats == null || cats.isEmpty)
            pw.Text('No spending data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Category', 'Amount', '%', 'MoM']),
                ...cats.map((SpendingCategoryData cat) {
                  final String momText = cat.changePercent == 0
                      ? '—'
                      : '${cat.changePercent > 0 ? '+' : ''}${pctFmt.format(cat.changePercent)}%';
                  final PdfColor momColor = cat.changePercent > 0
                      ? _colorAccentRed
                      : cat.changePercent < 0
                          ? _colorAccentGreen
                          : _colorTextSecondary;
                  return pw.TableRow(
                    children: <pw.Widget>[
                      _tableCell(cat.category),
                      _tableCell(data.formatAmount(cat.amount)),
                      _tableCell(
                          '${pctFmt.format(cat.percentage)}%'),
                      _tableCellColored(momText, momColor),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildIncomeAnalysis(ReportDataModel data, NumberFormat nf) {
    final List<IncomeSourceData>? sources = data.incomeSources;

    return _section(
      title: 'Income Analysis',
      section: ReportSection.incomeAnalysis,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Total income: ${data.formatAmount(data.totalIncome)}',
            style: _style(size: 11, bold: true, color: _colorTextPrimary),
          ),
          pw.SizedBox(height: 8),
          if (sources == null || sources.isEmpty)
            pw.Text('No income source data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(<String>['Source', 'Amount', 'Variance']),
                ...sources.map((IncomeSourceData src) {
                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(src.source),
                    _tableCell(data.formatAmount(src.amount)),
                    _tableCellColored(
                      '${src.variance >= 0 ? '+' : ''}${data.formatAmount(src.variance)}',
                      src.variance >= 0 ? _colorAccentGreen : _colorAccentRed,
                    ),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCashFlow(ReportDataModel data, NumberFormat nf) {
    return _section(
      title: 'Cash Flow',
      section: ReportSection.cashFlow,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _infoRow('Total Income', data.formatAmount(data.totalIncome)),
          _infoRow('Total Expenses', data.formatAmount(data.totalExpenses)),
          _infoRow('Net Cash Flow', data.formatAmount(data.netSavings),
              valueColor: data.netSavings >= 0
                  ? _colorAccentGreen
                  : _colorAccentRed),
          pw.SizedBox(height: 8),
          pw.Text(
            'See in-app for full cash flow chart.',
            style: _style(size: 9, color: _colorTextSecondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBudgetActual(
      ReportDataModel data, NumberFormat nf, NumberFormat pctFmt) {
    final List<BudgetCategoryData>? budgets = data.budgetCategories;

    return _section(
      title: 'Budget vs. Actual',
      section: ReportSection.budgetActual,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (budgets == null || budgets.isEmpty)
            pw.Text('No budget data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Category', 'Budget', 'Actual', 'Used']),
                ...budgets.map((BudgetCategoryData b) {
                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(b.category),
                    _tableCell(data.formatAmount(b.budget)),
                    _tableCell(data.formatAmount(b.actual)),
                    _tableCellColored(
                      '${pctFmt.format(b.percentage)}%',
                      b.isOverBudget ? _colorAccentRed : _colorAccentGreen,
                    ),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTopMerchants(ReportDataModel data, NumberFormat nf) {
    final List<MerchantData>? merchants = data.topMerchants;

    return _section(
      title: 'Top Merchants',
      section: ReportSection.topMerchants,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (merchants == null || merchants.isEmpty)
            pw.Text('No merchant data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Merchant', 'Amount', 'Category', 'Txns']),
                ...merchants.map((MerchantData m) {
                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(m.name),
                    _tableCell(data.formatAmount(m.amount)),
                    _tableCell(m.category),
                    _tableCell(m.transactionCount.toString()),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildInvestmentPortfolio(
      ReportDataModel data, NumberFormat nf, NumberFormat pctFmt) {
    final List<InvestmentHoldingData>? holdings = data.holdings;

    return _section(
      title: 'Investment Portfolio',
      section: ReportSection.investmentPortfolio,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (data.portfolioTotalValue != null)
            _infoRow('Portfolio Value',
                data.formatAmount(data.portfolioTotalValue!)),
          if (data.portfolioReturnPercent != null)
            _infoRow(
              'Total Return',
              '${data.portfolioReturnPercent! >= 0 ? '+' : ''}${pctFmt.format(data.portfolioReturnPercent!)}%',
              valueColor: data.portfolioReturnPercent! >= 0
                  ? _colorAccentGreen
                  : _colorAccentRed,
            ),
          pw.SizedBox(height: 8),
          if (holdings == null || holdings.isEmpty)
            pw.Text('No holdings data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Ticker', 'Name', 'Value', 'Alloc%', 'Return%']),
                ...holdings.map((InvestmentHoldingData h) {
                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(h.ticker),
                    _tableCell(h.name),
                    _tableCell(data.formatAmount(h.value)),
                    _tableCell('${pctFmt.format(h.allocation)}%'),
                    _tableCellColored(
                      '${h.returnPercent >= 0 ? '+' : ''}${pctFmt.format(h.returnPercent)}%',
                      h.returnPercent >= 0 ? _colorAccentGreen : _colorAccentRed,
                    ),
                  ]);
                }),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildForecast(ReportDataModel data) {
    final Forecast? forecast = data.forecast;

    return _section(
      title: 'Forecast',
      section: ReportSection.forecast,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (forecast == null)
            pw.Text('No forecast data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else ...<pw.Widget>[
            pw.Text(forecast.summary,
                style: _style(size: 10, color: _colorTextPrimary)),
            pw.SizedBox(height: 8),
            ...forecast.projectedBalance.entries.map(
              (MapEntry<String, double> e) =>
                  _infoRow(e.key, data.formatAmount(e.value)),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'See in-app for interactive forecast chart.',
            style: _style(size: 9, color: _colorTextSecondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAlerts(ReportDataModel data) {
    final List<Alert>? alerts = data.alerts;

    return _section(
      title: 'Alerts',
      section: ReportSection.alerts,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (alerts == null || alerts.isEmpty)
            pw.Text('No alerts.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            ...alerts.map((Alert a) {
              final PdfColor severityColor = a.severity == Severity.positive
                  ? _colorAccentGreen
                  : a.severity == Severity.warning
                      ? PdfColors.amber
                      : _colorAccentRed;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  border:
                      pw.Border(left: pw.BorderSide(color: severityColor, width: 3)),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(a.title,
                        style: _style(
                            size: 10, bold: true, color: _colorTextPrimary)),
                    pw.SizedBox(height: 3),
                    pw.Text(a.body,
                        style: _style(size: 9, color: _colorTextSecondary)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  pw.Widget _buildCoaching(ReportDataModel data, NumberFormat nf) {
    final List<CoachingTip>? tips = data.coachingTips;

    return _section(
      title: 'Coaching Tips',
      section: ReportSection.coaching,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (tips == null || tips.isEmpty)
            pw.Text('No coaching tips available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else
            ...tips.map((CoachingTip tip) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  border: pw.Border.all(color: _colorBorder),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: <pw.Widget>[
                        pw.Text(tip.title,
                            style: _style(
                                size: 10, bold: true, color: _colorTextPrimary)),
                        pw.Text(tip.difficulty.name,
                            style: _style(
                                size: 8, color: _colorTextSecondary)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(tip.body,
                        style: _style(size: 9, color: _colorTextSecondary)),
                    if (tip.savingsEstimate != null) ...<pw.Widget>[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Est. savings: ${data.formatAmount(tip.savingsEstimate!)}',
                        style: _style(
                            size: 8, color: _colorAccentGreen),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  pw.Widget _buildBills(
      ReportDataModel data, NumberFormat nf, DateFormat dateFmt) {
    final List<BillData>? bills = data.bills;

    return _section(
      title: 'Bills & Recurring',
      section: ReportSection.billsRecurring,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (bills == null || bills.isEmpty)
            pw.Text('No bills data available.',
                style: _style(size: 10, color: _colorTextSecondary))
          else ...<pw.Widget>[
            _infoRow(
              'Total Monthly Recurring',
              data.formatAmount(data.totalRecurring),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Name', 'Amount', 'Frequency', 'Next Due', 'Status']),
                ...bills.map((BillData b) {
                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(b.name),
                    _tableCell(data.formatAmount(b.amount)),
                    _tableCell(b.frequency),
                    _tableCell(b.nextDue != null
                        ? dateFmt.format(b.nextDue!)
                        : '—'),
                    _tableCell(b.status),
                  ]);
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTransactionLog(
      ReportDataModel data, NumberFormat nf, DateFormat dateFmt) {
    final List<dynamic>? txns = data.transactions;

    return _section(
      title: 'Transaction Log',
      section: ReportSection.transactionLog,
      data: data,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (txns == null || txns.isEmpty)
            pw.Text('No transactions in this period.',
                style: _style(size: 10, color: _colorTextSecondary))
          else ...<pw.Widget>[
            pw.Text(
              '${txns.length} transactions',
              style: _style(size: 9, color: _colorTextSecondary),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _colorBorder, width: 0.5),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.5),
              },
              children: <pw.TableRow>[
                _tableHeaderRow(
                    <String>['Date', 'Description', 'Amount', 'Type']),
                ...txns.map((dynamic tx) {
                  // Transaction is the model type; access known fields.
                  final String dateStr =
                      dateFmt.format(tx.dateTime as DateTime);
                  final String label = tx.label as String;
                  final double amount = tx.totalAmount as double;
                  final bool isExpense = tx.isExpense as bool;
                  final String currency = tx.currency as String;

                  return pw.TableRow(children: <pw.Widget>[
                    _tableCell(dateStr),
                    _tableCell(label),
                    _tableCell(
                      '${isExpense ? '-' : '+'}${nf.format(amount)} $currency',
                    ),
                    _tableCell(isExpense ? 'Expense' : 'Income'),
                  ]);
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Reusable layout helpers ───────────────────────────────────────────────

  /// Wraps content in a titled section card with optional AI recommendation.
  pw.Widget _section({
    required String title,
    required ReportSection section,
    required ReportDataModel data,
    required pw.Widget child,
  }) {
    final SectionRecommendation? rec = data.recommendations[section];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        // Section title bar
        pw.Container(
          width: double.infinity,
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _colorSurface,
            border: pw.Border(
                left: const pw.BorderSide(color: _colorAccentBlue, width: 3)),
          ),
          child: pw.Text(
            title,
            style: _style(size: 13, bold: true, color: _colorTextPrimary),
          ),
        ),
        pw.SizedBox(height: 10),
        child,
        if (rec != null) ...<pw.Widget>[
          pw.SizedBox(height: 10),
          _aiRecommendationBox(rec),
        ],
      ],
    );
  }

  pw.Widget _aiRecommendationBox(SectionRecommendation rec) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _colorSurface,
        border: pw.Border.all(color: _colorAccentBlue, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            children: <pw.Widget>[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _colorAccentBlue,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text('AI Insight',
                    style: _style(
                        size: 7, bold: true, color: PdfColors.white)),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(rec.oneLiner,
              style: _style(
                  size: 10, bold: true, color: _colorTextPrimary)),
          pw.SizedBox(height: 4),
          pw.Text(rec.detailed,
              style: _style(size: 9, color: _colorTextSecondary)),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: <pw.Widget>[
          pw.SizedBox(
            width: 160,
            child: pw.Text(label,
                style: _style(size: 10, color: _colorTextSecondary)),
          ),
          pw.Text(value,
              style: _style(
                  size: 10,
                  bold: true,
                  color: valueColor ?? _colorTextPrimary)),
        ],
      ),
    );
  }

  pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _colorSurface),
      children: headers
          .map((String h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: pw.Text(h,
                    style: _style(
                        size: 9, bold: true, color: _colorTextPrimary)),
              ))
          .toList(),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text,
          style: _style(size: 9, color: _colorTextPrimary)),
    );
  }

  pw.Widget _tableCellColored(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text, style: _style(size: 9, color: color)),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  String _momLabel(double changePercent) {
    if (changePercent.abs() < 0.05) return 'No change vs prior period';
    final String sign = changePercent > 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}% vs prior period';
  }
}
