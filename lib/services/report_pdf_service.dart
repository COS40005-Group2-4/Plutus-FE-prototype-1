import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/report_config.dart';
import '../models/report_data.dart';
import 'interfaces/i_report_pdf_service.dart';

class ReportPdfService implements IReportPdfService {
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
    final String html = await _buildHtml(data);
    return await Printing.convertHtml(format: PdfPageFormat.a4, html: html);
  }

  // ── Template renderer ─────────────────────────────────────────────────────

  Future<String> _buildHtml(ReportDataModel data) async {
    String template =
        await rootBundle.loadString('assets/report_templates/report.html');

    final NumberFormat nf = NumberFormat('#,##0.00');
    final NumberFormat pctFmt = NumberFormat('0.0');
    final DateFormat dateFmt = DateFormat('MMM d, yyyy');

    // ── Simple placeholder replacements ──────────────────────────────────────
    template = template.replaceAll('{{userName}}', _esc(data.userName));
    template = template.replaceAll(
        '{{generatedAt}}', dateFmt.format(data.generatedAt));
    template = template.replaceAll('{{currency}}', _esc(data.currency));

    template = template.replaceAll(
        '{{totalIncome}}', nf.format(data.totalIncome));
    template = template.replaceAll(
        '{{totalExpenses}}', nf.format(data.totalExpenses));
    template = template.replaceAll(
        '{{netSavings}}', nf.format(data.netSavings));
    template = template.replaceAll(
        '{{savingsRate}}', pctFmt.format(data.savingsRate));
    template = template.replaceAll(
        '{{comparisonIncome}}', nf.format(data.comparisonIncome));
    template = template.replaceAll(
        '{{comparisonExpenses}}', nf.format(data.comparisonExpenses));

    template = template.replaceAll(
        '{{healthScore}}',
        data.healthScore != null
            ? data.healthScore!.score.toString()
            : '—');
    template = template.replaceAll(
        '{{transactionCount}}', data.transactionCount.toString());

    template = template.replaceAll('{{dateRangeStart}}',
        dateFmt.format(data.config.dateRange.start));
    template = template.replaceAll(
        '{{dateRangeEnd}}', dateFmt.format(data.config.dateRange.end));

    template = template.replaceAll(
        '{{audienceLabel}}',
        data.config.audienceMode == AudienceMode.professional
            ? 'Professional Report'
            : 'Personal Report');

    // ── Pre-rendered blocks ───────────────────────────────────────────────────
    template = template.replaceAll(
        '{{spendingCategoriesHtml}}', _buildCategoryRows(data, nf, pctFmt));

    // AI recommendation blocks for each section
    for (final ReportSection section in ReportSection.values) {
      final String tag = _sectionTag(section);
      final String placeholder = '{{aiRecommendation_$tag}}';
      if (template.contains(placeholder)) {
        template =
            template.replaceAll(placeholder, _buildAiBox(data, section));
      }
    }

    // ── Conditional section blocks ────────────────────────────────────────────
    for (final ReportSection section in ReportSection.values) {
      final String tag = _sectionTag(section);
      final String open = '{{#section_$tag}}';
      final String close = '{{/section_$tag}}';

      if (data.config.enabledSections.contains(section)) {
        // Keep the content — just strip the markers
        template = template.replaceAll(open, '');
        template = template.replaceAll(close, '');
      } else {
        // Remove the entire block including its content
        final RegExp blockRe = RegExp(
          '\\{\\{#section_$tag\\}\\}.*?\\{\\{/section_$tag\\}\\}',
          dotAll: true,
        );
        template = template.replaceAll(blockRe, '');
      }
    }

    return template;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a [ReportSection] enum value to its template tag name.
  String _sectionTag(ReportSection section) => section.name;

  /// HTML-escapes a string to prevent injection.
  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Builds HTML `<tr>` rows for the spending categories table.
  String _buildCategoryRows(
      ReportDataModel data, NumberFormat nf, NumberFormat pctFmt) {
    final List<SpendingCategoryData>? cats = data.spendingCategories;
    if (cats == null || cats.isEmpty) {
      return '<tr><td colspan="4" style="text-align:center;color:#9ca3af;padding:16px;">No spending data</td></tr>';
    }

    final StringBuffer sb = StringBuffer();
    for (final SpendingCategoryData cat in cats) {
      final double pct = cat.percentage;
      final double change = cat.changePercent;
      final String changePill = _changePill(change);

      sb.write('<tr>');
      sb.write('<td><span class="pill expense">${_esc(cat.category)}</span></td>');
      sb.write('<td class="num">${_esc(data.currency)} ${nf.format(cat.amount)}</td>');
      sb.write('<td class="pct">${pctFmt.format(pct)}%</td>');
      sb.write('<td class="pct">$changePill</td>');
      sb.write('</tr>');
    }
    return sb.toString();
  }

  /// Returns a coloured pill HTML fragment for a percentage change value.
  String _changePill(double change) {
    if (change.abs() < 0.05) {
      return '<span class="pill">0.0%</span>';
    }
    final String sign = change > 0 ? '+' : '';
    final String label = '$sign${change.toStringAsFixed(1)}%';
    final String cls = change > 0 ? 'danger' : 'income';
    return '<span class="pill $cls">$label</span>';
  }

  /// Builds the AI recommendation box HTML for a section.
  String _buildAiBox(ReportDataModel data, ReportSection section) {
    final SectionRecommendation? rec = data.recommendations[section];
    if (rec == null) return '';

    // Pick a colour class based on section type
    final String colorClass = _aiBoxClass(section);

    return '''
<div class="ai-box $colorClass">
  <div class="ai-header">
    <span class="ai-tag">AI Insight</span>
  </div>
  <div class="ai-one-liner">${_esc(rec.oneLiner)}</div>
  <div class="ai-detail">${_esc(rec.detailed)}</div>
</div>''';
  }

  String _aiBoxClass(ReportSection section) {
    switch (section) {
      case ReportSection.incomeAnalysis:
        return 'income';
      case ReportSection.spendingBreakdown:
      case ReportSection.topMerchants:
        return 'expense';
      case ReportSection.budgetActual:
      case ReportSection.forecast:
      case ReportSection.alerts:
        return 'warning';
      default:
        return '';
    }
  }
}
